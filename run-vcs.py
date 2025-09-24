from pathlib import Path
import os
import argparse
import shutil
import subprocess
import json
from util import fmt

# Commit on branch feature/fdm_dev_tristan
RTL_COP_COMMIT = "e5e7c6e82e8e6d6b46e4f5ae61e2a1331e41d607"
# Commit on branch feature/rvfi_improvements
RTL_BASE_COMMIT = "e027937aef36f95723b05f19eecdd2f567495e57"

# Commit on branch pab_uvm_tristan
TB_COP_COMMIT = "a7e008b1c88c880898bacc785659319cba76bf9b"
# Commit on branch feature/interrupts
TB_BASE_COMMIT = "e892f368f831b0df7d5da00a93c5ef6d5b7998cc"

allowed_tests = [
    "uvmt_cv32e20_firmware_test_c",
    "uvmt_cv32e20_model_test_c",
    "uvmt_cv32e20_model_test_dual_ref_c"
]

allowed_marches = [
    "rv32imc_zicsr",
    "rv32imc",
    "rv32im_zicsr",
    "rv32imc_zicsr_xcvalu",
    "rv32imc_zicsr_xcvsimd",
    "rv32imc_zicsr_xcvalu_xcvsimd",
    "rv32imc_zicsr_xcvalu_xcvsimd_xcvmac",
    "rv32imc_zicsr_xcvalu_xcvsimd_xcvmac_xcvmem",
]

allowed_toolchains = [
    "/mnt/rhea_hdd_raid5/opt_non_storage/backend/toolchains/risc/rv32im/bin/riscv32-unknown-elf-",
    "/mnt/rhea_hdd_raid5/opt_non_storage/backend/toolchains/risc/rv32imc/bin/riscv32-unknown-elf-",
    "/mnt/rhea_hdd_raid5/opt_non_storage/backend/toolchains/risc/rv32imcb/bin/riscv32-unknown-elf-",
    "/home/vcl/compiler/riscv-toolchain/riscv-gnu-toolchain/riscv/bin/riscv32-unknown-elf-",
    "/opt/eda/riscv/tools/corev-openhw-gcc-rocky8-20240530/bin/riscv32-corev-elf-"
]

# Argparse the input in search of the flag -gui
parser = argparse.ArgumentParser()
parser.add_argument("-asf", help="ASF flag (accepts a string)", default="", type=str)
parser.add_argument("-out_dir", help="Output directory for the simulation results")
parser.add_argument("-gui", help="Run the simulation in GUI mode", action="store_true")
parser.add_argument("-cop", help="Compile the coprocessor as well", action="store_true")
parser.add_argument("-dmv", help="Compile the data mover as well", action="store_true")
parser.add_argument(
    "-sw_only", help="Compile only the SW, not the HW", action="store_true"
)
parser.add_argument("--bsp-only", help="Compile only the BSP", action="store_true")
parser.add_argument(
    "--skip-testcase-comp",
    help="Skip the compilation of the testcase.",
    action="store_true",
)
# program can either be a program name or a path to the precompiled program. The .hex and .itb files should be in the same directory as the program
parser.add_argument("-program", help="Specify the program name", default="hello-world")
parser.add_argument(
    "-no_iss", help="Run the simulation without ISS", action="store_true"
)
parser.add_argument("-mem_dump", help="Dump the memory content", action="store_true")
parser.add_argument(
    "-test",
    help=f"Select the UVM test, default is {allowed_tests[0]}, allowed are {allowed_tests}",
    default=allowed_tests[0],
)
parser.add_argument(
    "-ld",
    help="Select the linker script",
    default=None
)
parser.add_argument(
    "-toolchain",
    help=f"Selects the toolchain to use, default is {allowed_toolchains[0]}, allowed are {allowed_toolchains}",
    default=allowed_toolchains[0],
)
parser.add_argument(
    "-crt0",
    help=f"Select the crt0.S script"
)
parser.add_argument(
    "-c",
    help="Select the C script(s) to compile (space-separated list)",
    nargs="+"
)
parser.add_argument("-bm", help="Enable the behavioral model", action="store_true")
parser.add_argument("-define",  help="Pass a sim define",      default="")
parser.add_argument("-march", help=f"March definition, default is {allowed_marches[0]}, allowed are {allowed_marches}", default=allowed_marches[0])
parser.add_argument("-delay", help="Fetch initial delay to give time to the TB to load data through AXI in the IMEM", default="100000")
parser.add_argument("-core", help="Name of the core to simulate, default is cv32e20", default="cv32e20")

if __name__ == "__main__":
    
    # Default define
    test_define = ""

    additional_filelist = ""

    args = parser.parse_args()

    # Get path to the current directory
    CORE_V_VERIF = os.path.dirname(os.path.realpath(__file__))
    
    # Print default values if no flag is passed
    for action in parser._actions:
        if action.default is not None and not any(arg in action.option_strings for arg in vars(parser.parse_args())):
            print(f"\033[93mUsing default value for {action.dest}: {action.default}\033[0m")

    #####################################################################################
    ##################### Select all the desired parameters #############################
    #####################################################################################

    # Get input flags
    march = args.march
    uvm_test_name = args.test
    fetch_initial_delay = args.delay # Use +fetch_initial_delay to give time to the jtag to write into the IMEM
    cv_core = args.core # Select the desired core
    
    if args.mem_dump is True:
        test_define += "+define+DUMP_MEMORY"
        
    if args.bm is True:
        test_define += "+define+BEHAVIORAL_MODEL"

    # If the flag -gui is set, run the simulation in GUI mode
    if args.gui:
        kdb = "-debug_access+all+class+verbose -kdb"
        gui = "-gui"
    else:
        kdb = ""
        gui = ""

    if args.no_iss:
        scoreboard_enable = "0"
        define_ssm_spike = ""
    else:
        scoreboard_enable = "1"
        define_ssm_spike = "+define+SSM_SPIKE"

    #####################################################################################

    # Main subrepos paths
    # TODO: For the moment CORE V VERIF is aside of the RVV, should maybe become a submodule
    CORE_RTL_PATH = f"{CORE_V_VERIF}/core-v-cores/{args.core}"
    CORE_TB_PATH = f"{CORE_V_VERIF}/{args.core}"
    VERILAB_DIR = f"{CORE_TB_PATH}/vendor_lib/verilab/svlib"
    RISCV_OPCODES_DIR = f"{CORE_V_VERIF}/riscv-opcodes"
    RISCV_OPCODES_CONFIG_PATH = f"{CORE_V_VERIF}/util/config.json"
    DV_UVMC_RVFI_REFERENCE_MODEL_PATH = f"{CORE_V_VERIF}/lib/uvm_components/uvmc_rvfi_reference_model"

    os.environ["CORE_V_VERIF"] = CORE_V_VERIF
    os.environ["CORE_RTL_PATH"] = CORE_RTL_PATH
    os.environ["NOVAS_RC"] = "/opt/eda/synopsys/tools/verdi/V-2023.12/etc/custom_rovas.rc"

    VCS_HOME                      = "/opt/eda/synopsys/tools/vcs/latest"
    
    if args.march not in allowed_marches:
        print("\033[91m" + f"Error: {args.march} is not a valid march definition. Exiting..." + "\033[0m")
        exit()
    
    RISCV_EXE_PREFIX = args.toolchain.format(march=args.march)
    
    if not shutil.which(RISCV_EXE_PREFIX + "gcc"):
        print(f"\033[91mError: Toolchain not found at {RISCV_EXE_PREFIX} (missing gcc). Exiting...\033[0m")
        exit()
    
    # Define CV_SW_TOOLCHAIN as RISCV_EXE_PREFIX with everything from 'bin/' on removed
    CV_SW_TOOLCHAIN = RISCV_EXE_PREFIX.split("/bin/")[0]

    os.environ["VCS_HOME"]        = VCS_HOME
    os.environ["CV_SW_TOOLCHAIN"] = CV_SW_TOOLCHAIN
    os.environ["SPIKE_PATH"]      = f"{CORE_V_VERIF}/vendor/riscv/riscv-isa-sim"

    GCC = "gcc"  # BSP is compiled with gcc
    GXX = "g++"  # Test program is compiled with g++

    # CORE type setup
    CV_CORE_LC = cv_core
    os.environ["CV_CORE_LC"] = CV_CORE_LC

    # export DV_UVMT_PATH           = $(CORE_V_VERIF)/$(CV_CORE_LC)/tb/uvmt
    os.environ["DV_UVMT_PATH"] = f"{CORE_V_VERIF}/{CV_CORE_LC}/tb/uvmt"
    # export DV_UVME_PATH           = $(CORE_V_VERIF)/$(CV_CORE_LC)/env/uvme
    os.environ["DV_UVME_PATH"] = f"{CORE_V_VERIF}/{CV_CORE_LC}/env/uvme"
    # export DV_UVML_HRTBT_PATH     = $(CORE_V_VERIF)/lib/uvm_libs/uvml_hrtbt
    os.environ["DV_UVML_HRTBT_PATH"] = f"{CORE_V_VERIF}/lib/uvm_libs/uvml_hrtbt"
    # export DV_UVMA_ISACOV_PATH    = $(CORE_V_VERIF)/lib/uvm_agents/uvma_isacov
    os.environ["DV_UVMA_ISACOV_PATH"] = f"{CORE_V_VERIF}/lib/uvm_agents/uvma_isacov"
    # export DV_UVMA_CLKNRST_PATH   = $(CORE_V_VERIF)/lib/uvm_agents/uvma_clknrst
    os.environ["DV_UVMA_CLKNRST_PATH"] = f"{CORE_V_VERIF}/lib/uvm_agents/uvma_clknrst"
    # export DV_UVMA_INTERRUPT_PATH = $(CORE_V_VERIF)/lib/uvm_agents/uvma_interrupt
    os.environ["DV_UVMA_INTERRUPT_PATH"] = f"{CORE_V_VERIF}/lib/uvm_agents/uvma_interrupt"
    # export DV_UVMA_DEBUG_PATH     = $(CORE_V_VERIF)/lib/uvm_agents/uvma_debug
    os.environ["DV_UVMA_DEBUG_PATH"] = f"{CORE_V_VERIF}/lib/uvm_agents/uvma_debug"
    # export DV_UVML_TRN_PATH       = $(CORE_V_VERIF)/lib/uvm_libs/uvml_trn
    os.environ["DV_UVML_TRN_PATH"] = f"{CORE_V_VERIF}/lib/uvm_libs/uvml_trn"
    # export DV_UVML_LOGS_PATH      = $(CORE_V_VERIF)/lib/uvm_libs/uvml_logs
    os.environ["DV_UVML_LOGS_PATH"] = f"{CORE_V_VERIF}/lib/uvm_libs/uvml_logs"
    # export DV_UVML_SB_PATH        = $(CORE_V_VERIF)/lib/uvm_libs/uvml_sb
    os.environ["DV_UVML_SB_PATH"] = f"{CORE_V_VERIF}/lib/uvm_libs/uvml_sb"

    # export DV_OVPM_HOME           = $(CORE_V_VERIF)/vendor_lib/imperas
    os.environ["DV_OVPM_HOME"] = f"{CORE_V_VERIF}/vendor_lib/imperas"
    # export DV_OVPM_MODEL          = $(DV_OVPM_HOME)/imperas_DV_COREV
    os.environ["DV_OVPM_MODEL"] = f"{os.environ['DV_OVPM_HOME']}/imperas_DV_COREV"
    # export DV_OVPM_DESIGN         = $(DV_OVPM_HOME)/design
    os.environ["DV_OVPM_DESIGN"] = f"{os.environ['DV_OVPM_HOME']}/design"

    # UVM Environment
    os.environ["DV_UVMT_PATH"] = f"{CORE_V_VERIF}/{CV_CORE_LC}/tb/uvmt"
    os.environ["DV_UVME_PATH"] = f"{CORE_V_VERIF}/{CV_CORE_LC}/env/uvme"
    os.environ["DV_UVML_HRTBT_PATH"] = f"{CORE_V_VERIF}/lib/uvm_libs/uvml_hrtbt"
    os.environ["DV_UVMA_CORE_CNTRL_PATH"] = f"{CORE_V_VERIF}/lib/uvm_agents/uvma_core_cntrl"
    os.environ["DV_UVMA_ISACOV_PATH"] = f"{CORE_V_VERIF}/lib/uvm_agents/uvma_isacov"
    os.environ["DV_UVMA_RVFI_PATH"] = f"{CORE_V_VERIF}/lib/uvm_agents/uvma_rvfi"
    os.environ["DV_UVMA_RVVI_PATH"] = f"{CORE_V_VERIF}/lib/uvm_agents/uvma_rvvi"
    os.environ["DV_UVMA_CVXIF_PATH"] = f"{CORE_V_VERIF}/lib/uvm_agents/uvma_cvxif"
    os.environ["DV_UVMA_RVVI_OVPSIM_PATH"] = (
        f"{CORE_V_VERIF}/lib/uvm_agents/uvma_rvvi_ovpsim"
    )
    os.environ["DV_UVMA_CLKNRST_PATH"] = f"{CORE_V_VERIF}/lib/uvm_agents/uvma_clknrst"
    os.environ["DV_UVMA_INTERRUPT_PATH"] = f"{CORE_V_VERIF}/lib/uvm_agents/uvma_interrupt"
    os.environ["DV_UVMA_DEBUG_PATH"] = f"{CORE_V_VERIF}/lib/uvm_agents/uvma_debug"
    os.environ["DV_UVMA_PMA_PATH"] = f"{CORE_V_VERIF}/lib/uvm_agents/uvma_pma"
    os.environ["DV_UVMA_OBI_MEMORY_PATH"] = f"{CORE_V_VERIF}/lib/uvm_agents/uvma_obi_memory"
    os.environ["DV_UVMA_FENCEI_PATH"] = f"{CORE_V_VERIF}/lib/uvm_agents/uvma_fencei"
    os.environ["DV_UVML_TRN_PATH"] = f"{CORE_V_VERIF}/lib/uvm_libs/uvml_trn"
    os.environ["DV_UVML_LOGS_PATH"] = f"{CORE_V_VERIF}/lib/uvm_libs/uvml_logs"
    os.environ["DV_UVML_SB_PATH"] = f"{CORE_V_VERIF}/lib/uvm_libs/uvml_sb"
    os.environ["DV_UVML_MEM_PATH"] = f"{CORE_V_VERIF}/lib/uvm_libs/uvml_mem"

    os.environ["DV_UVMC_RVFI_SCOREBOARD_PATH"] = (
        f"{CORE_V_VERIF}/lib/uvm_components/uvmc_rvfi_scoreboard/"
    )
    os.environ["DV_UVMC_RVFI_REFERENCE_MODEL_PATH"] = (
        f"{CORE_V_VERIF}/lib/uvm_components/uvmc_rvfi_reference_model/"
    )

    os.environ["DV_OVPM_HOME"] = f"{CORE_V_VERIF}/vendor_lib/imperas"
    os.environ["DV_OVPM_MODEL"] = f"{os.environ['DV_OVPM_HOME']}/imperas_DV_COREV"

    os.environ["DV_OVPM_DESIGN"] = f"{os.environ['DV_OVPM_HOME']}/design"

    os.environ["DV_SVLIB_PATH"] = f"{CORE_V_VERIF}/{CV_CORE_LC}/vendor_lib/verilab"

    # TB source files for the CV32E core
    TBSRC_HOME = f"{CORE_V_VERIF}/{CV_CORE_LC}/tb"
    os.environ["TBSRC_HOME"] = TBSRC_HOME

    # RTL source files for the CV32E core
    # DESIGN_RTL_DIR is used by CV32E40P_MANIFEST file
    CV_CORE_PKG = CORE_RTL_PATH
    CV_CORE_MANIFEST = f"{CV_CORE_PKG}/{CV_CORE_LC}_manifest.flist"
    os.environ["DESIGN_RTL_DIR"] = f"{CV_CORE_PKG}/rtl"

    if args.cop:
        os.environ["RVV_PATH"] = f"{CV_CORE_PKG}/../xcs"
        os.environ["DSL_PATH"] = f"{CV_CORE_PKG}/../xcs/src/dsl"

        additional_filelist += f"-f {CORE_V_VERIF}/core-v-cores/xcs/coproc.fl "
        
        rtl_commit = RTL_COP_COMMIT
        tb_commit = TB_COP_COMMIT
    else:
        rtl_commit = RTL_BASE_COMMIT
        tb_commit = TB_BASE_COMMIT

    if args.dmv:
        os.environ["DSL_PATH"] = f"{CV_CORE_PKG}/../xcs/src/dsl"
        os.environ["DMV_PATH"] = f"{CV_CORE_PKG}/../lsu"

        additional_filelist += f"-f {CORE_V_VERIF}/core-v-cores/lsu/datamover.fl "


    os.environ["DPI_DASM_ROOT"] = "{CORE_V_VERIF}/lib/dpi_dasm"

    ## DRI DEFINITION
    # The output root directory for the compilation and simulation
    if args.out_dir:
        out_dir = args.out_dir
        if not os.path.exists(out_dir):
            os.makedirs(out_dir)
    else:    
        out_dir = (
            os.path.join(CORE_V_VERIF, "log")
            if not args.skip_testcase_comp
            else Path(args.program).parent / "log"
        )

    program_name = args.program

    vcs_out_dir      = os.path.join(out_dir, "default", "vcs_results")
    core_dv_dir      = os.path.join(out_dir, "default", "corev-dv")
    csrc_dir         = os.path.join(vcs_out_dir, "csrc")
    test_program_dir = os.path.join(vcs_out_dir, "default", program_name, "0", "test_program")
    bsp_dir          = os.path.join(test_program_dir, "bsp")
    
    # If the program is a path, extract the program name
    program_path = Path(args.program)
    if program_path.is_absolute() or program_path.parent != Path('.'):
        print("BRANCH0")
        elf_file = Path(args.program).parent / f"{Path(args.program).name}"
        hex_file = Path(args.program).parent / f"{Path(args.program).stem}.hex"
        itb_file = Path(args.program).parent / f"{Path(args.program).stem}.itb"
        program_name = Path(elf_file).stem
        test_program_dir = (
            Path(vcs_out_dir) / "default" / program_name / "0" / "test_program"
        )
        bsp_dir = test_program_dir / "bsp"
        test_program_dir.mkdir(parents=True, exist_ok=True)
        for file in [elf_file, hex_file, itb_file]:
            # copy the file to the test_program_dir
            shutil.copy(file, test_program_dir)
    else:
        elf_file = Path(test_program_dir) / f"{program_name}.elf"
        hex_file = Path(test_program_dir) / f"{program_name}.hex"
        itb_file = Path(test_program_dir) / f"{program_name}.itb"

    if not os.path.exists(core_dv_dir):
        os.makedirs(core_dv_dir)
    if not os.path.exists(csrc_dir):
        os.makedirs(csrc_dir)
    if not os.path.exists(bsp_dir):
        os.makedirs(bsp_dir)

    ## VCS define is needed for the ifdef in the AXI crossbar
    vcs_defines = "+define+VCS +define+GNT "
    # vcs_defines += "+define+__UVMT_CV32E20_TB_SV__ "  # NOTE: we define __UVMT_CV32E20_TB_SV__ so that the top module of the OpenHW is not compiled, we want to compile our own top module
    # vcs_defines += "+define+__UVMT_CV32E20_DUT_WRAP_SV__ "  # NOTE: we define __UVMT_CV32E20_DUT_WRAP_SV__ so we avoid compiling the cor wrapper of OpenHW, which we do not use
    CXR_VERSION_DEFINE = "+define+BASE"

    # mkdir {CORE_V_VERIF}/log/ &&  \
    args_define = f"+define+{args.define}"
    vcs_compile_flags = "+define++define+CV32E20_RVFI+RVFI +define+CV32E20_TRACE_EXECUTION +USE_ISS -lca -sverilog +define+CV32E20_ASSERT_ON -ntb_opts uvm-1.2 -timescale=1ns/1ps -assert svaext -race=all -ignore unique_checks -full64 -reportstats -notice -line -fgp=multisocket +define+UVM"

    # Find absolute path of uvmc_rvfi_decoder_pkg.sv
    decoder_pkg_path = os.path.join(DV_UVMC_RVFI_REFERENCE_MODEL_PATH, "uvmc_rvfi_decoder_pkg.sv")

    # Add path in uvmc_rvfi_decoder_pkg.sv's directory to +incdir
    vcs_compile_flags += f" +incdir+{os.path.dirname(decoder_pkg_path)} "

    # Directly include the file uvmc_rvfi_decoder_pkg.sv into the build
    vcs_compile_flags += f" {decoder_pkg_path} "
    

    optional_flags = "-suppress=PCTI-L -suppress=UII-L -kdb=common_elab -debug_acc+all -debug_region+cell+encrypt -fgp=num_threads:8 -fgp=auto_affinity:allowHyperThreadCpu +gc+high_threshold+5 +UVM_NO_RELNOTES"

    ###################################################################
    ################ SELECT THE CRT0 AND LINKER #######################
    ###################################################################
    if program_name == "riscv_arithmetic_basic_test_0":
        crt0_path = f"{CORE_V_VERIF}/cv32e20/tests/programs/custom/riscv_arithmetic_basic_test_0/riscv_arithmetic_basic_test_0.S"
    elif program_name == "simple_cv_addsub_test":
        crt0_path = f"{CORE_V_VERIF}/cv32e20/tests/programs/custom/simple_cv_addsub_test/simple_cv_addsub_test.S"
    elif program_name == "simple_cv_addsubls3_test":
        crt0_path = f"{CORE_V_VERIF}/cv32e20/tests/programs/custom/simple_cv_addsubls3_test/simple_cv_addsubls3_test.S"
    elif program_name == "simple_cv_clip_test":
        crt0_path = f"{CORE_V_VERIF}/cv32e20/tests/programs/custom/simple_cv_clip_test/simple_cv_clip_test.S"
    elif program_name == "simple_cv_cmpsimd_test":
        crt0_path = f"{CORE_V_VERIF}/cv32e20/tests/programs/custom/simple_cv_cmpsimd_test/simple_cv_cmpsimd_test.S"
    elif program_name == "simple_cv_dotpsimd_test":
        crt0_path = f"{CORE_V_VERIF}/cv32e20/tests/programs/custom/simple_cv_dotpsimd_test/simple_cv_dotpsimd_test.S"
    elif program_name == "simple_cv_genalu_test":
        crt0_path = f"{CORE_V_VERIF}/cv32e20/tests/programs/custom/simple_cv_genalu_test/simple_cv_genalu_test.S"
    elif program_name == "simple_cv_gensimd_test":
        crt0_path = f"{CORE_V_VERIF}/cv32e20/tests/programs/custom/simple_cv_gensimd_test/simple_cv_gensimd_test.S"
    elif program_name == "simple_cv_mac32_test":
        crt0_path = f"{CORE_V_VERIF}/cv32e20/tests/programs/custom/simple_cv_mac32_test/simple_cv_mac32_test.S"
    elif program_name == "simple_cv_mac168_test":
        crt0_path = f"{CORE_V_VERIF}/cv32e20/tests/programs/custom/simple_cv_mac168_test/simple_cv_mac168_test.S"
    elif program_name == "simple_cv_mul168_test":
        crt0_path = f"{CORE_V_VERIF}/cv32e20/tests/programs/custom/simple_cv_mul168_test/simple_cv_mul168_test.S"          
    elif program_name == "simple_cv_postinc_load_store_test":
        crt0_path = f"{CORE_V_VERIF}/cv32e20/tests/programs/custom/simple_cv_postinc_load_store_test/simple_cv_postinc_load_store_test.S" 
    else:
        crt0_path = f"{CORE_TB_PATH}/bsp/crt0.S"
        
    if args.crt0:
        crt0_path = args.crt0
        if not os.path.exists(crt0_path):
            print(f"\033[91mError: crt0.S file {crt0_path} does not exist\033[0m")
            exit()
        print(f"\033[93mUsing custom crt0.S file: {crt0_path}\033[0m")

    # This test is not present anymore, use the default linker
    # # If the test is rec_tb_cor_axi_test_drive_both_computeram_no_fw_preload,
    # # The system need a .ld and crt0.S file wo handle the bootloader
    # if uvm_test_name == "rec_tb_cor_axi_test_drive_both_computeram_no_fw_preload":
    #     crt0_path = f"{CORE_V_VERIF}/design/top/rec/scripts/c/dram_system/crt0.S"

    if program_name in ["hello-world", "fibonacci", "csr_instructions", "branch_zero", "dhrystone"]:
        c_files = f"{CORE_TB_PATH}/tests/programs/custom/{program_name}/{program_name}.c"
    elif program_name == "coremark":
        c_files = f"-DITERATIONS=1 \
            -DVALIDATION_RUN=1 \
            -DFLAGS_STR='\"-Os -g -static -mabi=ilp32 -march={march} -Wall -pedantic\"' \
            {CORE_TB_PATH}/tests/programs/custom/{program_name}/coremark.h \
            {CORE_TB_PATH}/tests/programs/custom/{program_name}/core_portme.h \
            {CORE_TB_PATH}/tests/programs/custom/{program_name}/core_portme.c \
            {CORE_TB_PATH}/tests/programs/custom/{program_name}/core_list_join.c \
            {CORE_TB_PATH}/tests/programs/custom/{program_name}/core_state.c \
            {CORE_TB_PATH}/tests/programs/custom/{program_name}/core_util.c\
            {CORE_TB_PATH}/tests/programs/custom/{program_name}/core_matrix.c \
            {CORE_TB_PATH}/tests/programs/custom/{program_name}/core_main.c"
    elif program_name == "test_read_write":
        linker_script = f"{CORE_V_VERIF}/design/top/rec/scripts/c/link_big_heap.ld"
        c_files = f"{CORE_V_VERIF}/CxR_tests/stream_read_write.cc \
            {CORE_V_VERIF}/CxR_tests/computeram.c \
            {CORE_V_VERIF}/CxR_tests/hardware_tests_utils.cc \
            {CORE_V_VERIF}/CxR_tests/chip_config.c"
    elif program_name == "test_trigger_compute":
        linker_script = f"{CORE_V_VERIF}/design/top/rec/scripts/c/link_big_heap.ld"
        c_files = f"{CORE_V_VERIF}/CxR_tests/trigger_compute.cc \
            {CORE_V_VERIF}/CxR_tests/computeram.c \
            {CORE_V_VERIF}/CxR_tests/hardware_tests_utils.cc \
            {CORE_V_VERIF}/CxR_tests/chip_config.c"
    elif program_name == "simple_test":
        linker_script = f"{CORE_V_VERIF}/design/top/rec/scripts/c/link_big_heap.ld"
        c_files = f"{CORE_V_VERIF}/CxR_tests/simple_test.cc \
            {CORE_V_VERIF}/CxR_tests/computeram.c \
            {CORE_V_VERIF}/CxR_tests/hardware_tests_utils.cc \
            {CORE_V_VERIF}/CxR_tests/chip_config.c"
    else:
        c_files = ""
        print(f"Program {program_name} not found. Assuming it is a precompiled program.")

    if args.ld:
        linker_script = args.ld
    else:
        linker_script = f"{CORE_TB_PATH}/bsp/link.ld"
        
    if args.c:
        c_files = " ".join(args.c)
        if not os.path.exists(c_files):
            print(f"\033[91mError: C file {c_files} does not exist\033[0m")
            exit()
        print(f"\033[93mUsing custom C files: {c_files}\033[0m")

    # This test is not present anymore, use the default linker
    # # If the test is rec_tb_cor_axi_test_drive_both_computeram_no_fw_preload,
    # # The system need a .ld and crt0.S file wo handle the bootloader
    # if uvm_test_name == "rec_tb_cor_axi_test_drive_both_computeram_no_fw_preload":
    #     linker_script = f"{CORE_V_VERIF}/design/top/rec/scripts/c/dram_system/link.ld"

    with open(RISCV_OPCODES_CONFIG_PATH, "r") as f:
        riscv_opcodes_config = json.load(f)
    
    ext_supported = ""
    for el in riscv_opcodes_config["ext_supported"]:
        ext_supported += f"{el} "

    ###################################################################
    ################ FORMAT COMMANDS TEMPLATE   #######################
    ###################################################################
    
    # Put all the information flags into a single dictionary
    # With this dictionary you will format the commands
    fmt_dict = {
        "CORE_V_VERIF": CORE_V_VERIF,
        "CORE_V_VERIF": CORE_V_VERIF,
        "VCS_HOME": VCS_HOME,
        "RISCV_OPCODES_DIR": RISCV_OPCODES_DIR,
        "cv_core": cv_core,
        "CORE_RTL_PATH": CORE_RTL_PATH,
        "CORE_TB_PATH": CORE_TB_PATH,
        "RISCV_EXE_PREFIX": RISCV_EXE_PREFIX,
        "DV_UVMC_RVFI_REFERENCE_MODEL_PATH": DV_UVMC_RVFI_REFERENCE_MODEL_PATH,
        "GCC": GCC,
        "GXX": GCC,
        "march": march,
        "core_dv_dir": core_dv_dir,
        "csrc_dir": csrc_dir,
        "vcs_out_dir": vcs_out_dir,
        "vcs_compile_flags": vcs_compile_flags,
        "vcs_defines": vcs_defines,
        "CXR_VERSION_DEFINE": CXR_VERSION_DEFINE,
        "args_define": args_define,
        "test_define": test_define,
        "kdb": kdb,
        "optional_flags": optional_flags,
        "bsp_dir": bsp_dir,
        "crt0_path": crt0_path,
        "test_program_dir": test_program_dir,
        "program_name": program_name,
        "c_files": c_files,
        "linker_script": linker_script,
        "scoreboard_enable": scoreboard_enable,
        "gui": gui,
        "define_ssm_spike": define_ssm_spike,
        "uvm_test_name": uvm_test_name,
        "fetch_initial_delay": fetch_initial_delay,
        "elf_file": elf_file,
        "hex_file": hex_file,
        "itb_file": itb_file,
        "additional_filelist": additional_filelist,
        "rtl_commit": rtl_commit,
        "tb_commit": tb_commit,
        "ext_supported": ext_supported,
        "additional_string_sim": args.asf
    }

    google_compile_cmd = fmt.google_compile_cmd.format(**fmt_dict)

    dpi_compile_cmd = fmt.dpi_compile_cmd.format(**fmt_dict)

    bsp_compile_cmd = fmt.bsp_compile_cmd.format(**fmt_dict)

    test_program_compile_cmd = fmt.test_program_compile_cmd.format(**fmt_dict)

    hex_compile_cmd = fmt.hex_compile_cmd.format(**fmt_dict)

    sv_compile_cmd = fmt.sv_compile_cmd.format(**fmt_dict)

    sv_sim_cmd = fmt.sv_sim_cmd.format(**fmt_dict)
    
    build_folder_cmd = fmt.build_folder_cmd.format(**fmt_dict)
    
    rtl_git_cmd = fmt.rtl_git_cmd.format(**fmt_dict)
    
    tb_git_cmd = fmt.tb_git_cmd.format(**fmt_dict)
    
    parse_cmd = fmt.parse_cmd.format(**fmt_dict)

    autogen_cmd = fmt.autogen_cmd.format(**fmt_dict)

    sw_cmd_dict = {
        "rtl_git_cmd": rtl_git_cmd,
        "tb_git_cmd": tb_git_cmd,
        "bsp_compile_cmd": bsp_compile_cmd,
        "parse_cmd": parse_cmd,
        "autogen_cmd": autogen_cmd
    }

    ###################################################################
    ################ CREATE THE COMMAND DICT    #######################
    ###################################################################
    if args.bsp_only:
        args.sw_only = True
    elif args.skip_testcase_comp:
        sw_cmd_dict |= {
            # "google_compile_cmd": google_compile_cmd,
            "dpi_compile_cmd": dpi_compile_cmd,
        }
    else:
        sw_cmd_dict |= {
            # "google_compile_cmd": google_compile_cmd,
            "dpi_compile_cmd": dpi_compile_cmd,
            "test_program_compile_cmd": test_program_compile_cmd,
            "hex_compile_cmd": hex_compile_cmd,
        }
        
    # If the folder has not been built, this command is added at the beginning of the sw_cmd_dict
    # in order to build the folder before compiling the SW. The verilab folder will be filled with Spike files
    if not os.path.exists(VERILAB_DIR):
        sw_cmd_dict = {"build_folder_cmd": build_folder_cmd, **sw_cmd_dict}

    hw_cmd_dict = {"sv_compile_cmd": sv_compile_cmd, "sv_sim_cmd": sv_sim_cmd}

    for cmd_idx, (key, cmd) in enumerate(sw_cmd_dict.items()):
        print("\n**********************************************************")
        print(f"{key}:\n{cmd}")
        print("**********************************************************")

        process = subprocess.Popen(cmd, shell=True)
        process.wait()

        if process.returncode != 0:
            print("\033[91m" + f"Error occurred in {key}. Exiting..." + "\033[0m")
            exit()

    if args.sw_only:
        exit()
        
    for cmd_idx, (key, cmd) in enumerate(hw_cmd_dict.items()):
        print("\n**********************************************************")
        print(f"{key}:\n{cmd}")
        print("**********************************************************")

        process = subprocess.Popen(cmd, shell=True)
        process.wait()

        if process.returncode != 0:
            print("\033[91m" + f"Error occurred in {key}. Exiting..." + "\033[0m")
            exit()
