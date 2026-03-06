from pathlib import Path
import os
import sys
import argparse
import shutil
import subprocess
import json
import yaml
from compileSpike import main as compile_spike_main

# Commit on branch feature/fdm_dev_tristan
RTL_COP_COMMIT = "e5e7c6e82e8e6d6b46e4f5ae61e2a1331e41d607"
# Commit on branch feature/rvfi_improvements
RTL_BASE_COMMIT = "e027937aef36f95723b05f19eecdd2f567495e57"

# Commit on branch pab_uvm_tristan
# TB_COP_COMMIT = "a7e008b1c88c880898bacc785659319cba76bf9b"
# Commit on branch feature/interrupts
TB_COP_COMMIT = "e892f368f831b0df7d5da00a93c5ef6d5b7998cc"
TB_BASE_COMMIT = "e892f368f831b0df7d5da00a93c5ef6d5b7998cc"

allowed_tests = [
    "uvmt_cv32e20_firmware_test_c",
    "uvmt_cv32e20_model_test_c",
    "uvmt_cv32e20_model_test_dual_ref_c",
    "uvmt_cv32e20_model_test_with_cvxif_c"
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

TOOLCHAIN_CONFIG_PATH = Path(__file__).resolve().parent / "config" / "toolchain.yml"

def load_allowed_toolchains(config_path: Path) -> list[str]:
    if not config_path.exists():
        raise RuntimeError(f"Toolchain config file not found: {config_path}")

    with config_path.open("r", encoding="utf-8") as f:
        data = yaml.safe_load(f) or {}

    allowed = data.get("allowed_toolchains", [])
    if not isinstance(allowed, list):
        raise RuntimeError("allowed_toolchains must be a list in toolchain.yml")

    allowed = [toolchain for toolchain in allowed if isinstance(toolchain, str) and toolchain.strip()]
    if not allowed:
        raise RuntimeError(f"No toolchains configured in {config_path}")

    return allowed


allowed_toolchains = load_allowed_toolchains(TOOLCHAIN_CONFIG_PATH)

# Argparse the input in search of the flag -gui
parser = argparse.ArgumentParser()
parser.add_argument("-asf", help="ASF flag (accepts a string)", default="", type=str)
parser.add_argument("-out_dir", help="Output directory for the simulation results", default=os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.realpath(__file__)))), "log"))
parser.add_argument("-gui", help="Run the simulation in GUI mode", action="store_true")
parser.add_argument("-test_idx", help="Specify the test index (integer)", type=int, default=0)
parser.add_argument("-cop", help="Compile the coprocessor as well", action="store_true")
parser.add_argument("-dmv", help="Compile the data mover as well", action="store_true")
parser.add_argument("-uvm_verbosity", help='Set UVM verbosity level (default: "UVM_LOW")', type=str, default="UVM_LOW")
parser.add_argument("--rtl-only", help="Only compiles and simulates the RTL", action="store_true")
parser.add_argument("--rtl-compile-only", help="Only compiles the RTL", action="store_true")
parser.add_argument("--rtl-sim-only", help="Only simulates the RTL", action="store_true")
parser.add_argument("--sw-compile-only", help="Compile only the SW, not the HW", action="store_true")
parser.add_argument("--sw-compile-only-bsp", help="Compile only the BSP", action="store_true")
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

    additional_filelist = ""

    args = parser.parse_args()

    # Get path to the current directory
    CORE_V_VERIF = os.path.dirname(os.path.dirname(os.path.dirname(os.path.realpath(__file__))))
    os.environ["CORE_V_VERIF"] = CORE_V_VERIF

    RISCV_UVM_MODEL_DIR = os.path.join(CORE_V_VERIF, "riscv_uvm_model")
    sys.path.insert(0, CORE_V_VERIF)  # so riscv_uvm_model can be found

    from riscv_uvm_model.utils import fmt
    from riscv_uvm_model.utils.config import Config

    config = Config(args, CORE_V_VERIF)

    # Default define
    sv_comp_define = " ".join(config.VCS_DEFINES)
    
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
    program = args.program
    
    if args.mem_dump is True:
        sv_comp_define += "+define+DUMP_MEMORY"
        
    if args.bm is True:
        sv_comp_define += "+define+BEHAVIORAL_MODEL"

    sv_comp_define += f"+define+{args.define}"

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
    CORE_RTL_PATH                      = config.CORE_RTL_PATH
    CORE_TB_PATH                       = config.CORE_TB_PATH
    VERILAB_DIR                        = config.VERILAB_DIR
    RISCV_OPCODES_DIR                  = config.RISCV_OPCODES_DIR
    RISCV_OPCODES_CONFIG_PATH          = config.RISCV_OPCODES_CONFIG_PATH
    DV_UVMC_RVFI_REFERENCE_MODEL_DIR   = config.DV_UVMC_RVFI_REFERENCE_MODEL_DIR
    DV_UVMC_RVFI_REFERENCE_MODEL_PKG_PATH  = config.DV_UVMC_RVFI_REFERENCE_MODEL_PKG_PATH
    VCS_HOME                           = config.VCS_HOME
    RISCV_EXE_PREFIX                   = config.RISCV_EXE_PREFIX

    if args.march not in allowed_marches:
        print("\033[91m" + f"Error: {args.march} is not a valid march definition. Exiting..." + "\033[0m")
    
    if not shutil.which(RISCV_EXE_PREFIX + "gcc"):
        print(f"\033[91mError: Toolchain not found at {RISCV_EXE_PREFIX} (missing gcc). Exiting...\033[0m")
        exit()

    GCC = "gcc"  # BSP is compiled with gcc
    GXX = "g++"  # Test program is compiled with g++
    
    config.export_env()

    # Switch branch depending on the presence of the coprocessor and data mover
    if args.cop:
        # Defining this variable __UVMT_CV32E20_DUT_WRAP_SV__ means the compilation of the
        # wrapper without CVXIF will be skipped
        sv_comp_define += "+define+__UVMT_CV32E20_DUT_WRAP_SV__ "
        sv_comp_define += "+define+__UVMT_CV32E20_TB_SV__ "

        if "cvxif" not in args.test:
            raise ValueError(f"\033[31mSubstring 'cvxif' not found in string {args.test} : you are trying to use the coprocessor but the test does not support CVX if\033[0m")

        additional_filelist += f"-f {CORE_V_VERIF}/core-v-cores/xcs/coproc.fl "
        
        rtl_commit = RTL_COP_COMMIT
        tb_commit = TB_COP_COMMIT
    else:
        # Defining this variable __UVMT_CV32E20_DUT_WRAP_WITH_CVXIF_SV__ means the compilation of the
        # wrapper with CVXIF will be skipped
        sv_comp_define += "+define+__UVMT_CV32E20_DUT_WRAP_WITH_CVXIF_SV__ "
        sv_comp_define += "+define+__UVMT_CV32E20_TB_CVXIF_SV__ "

        rtl_commit = RTL_BASE_COMMIT
        tb_commit = TB_BASE_COMMIT

    # Still compile the cvxif agent even if the coprocessor is not compiled, as it is used to drive the custom instructions
    additional_filelist += f"-f {CORE_V_VERIF}/lib/uvm_agents/uvma_cvxif/src/uvma_cvxif_pkg.flist "

    if args.dmv:
        additional_filelist += f"-f {CORE_V_VERIF}/core-v-cores/lsu/datamover.fl "

    ## OUT DIR DEFINITION
    # The output root directory for the compilation and simulation
    OUT_DIR = config.OUT_DIR
    if not os.path.exists(OUT_DIR):
        os.makedirs(OUT_DIR)

    vcs_out_dir      = config.VCS_OUT_DIR
    core_dv_dir      = config.CORE_DV_DIR
    csrc_dir         = config.CSRC_DIR
    test_program_dir = config.TEST_PROGRAM_DIR
    bsp_dir          = config.BSP_DIR
    
    # Create the output directories if they do not exist
    for dir_path in [core_dv_dir, csrc_dir, bsp_dir]:
        os.makedirs(dir_path, exist_ok=True)
        print(f"\033[93mCreated directory: {dir_path}\033[0m")

    # If the program is a path, extract the program name
    program_path = Path(args.program)
    if program_path.is_absolute() or program_path.parent != Path('.'):
        raise RuntimeError("Program path is absolute or not in current directory. Please check the input.")
        # print("BRANCH0")
        # elf_file = Path(args.program).parent / f"{Path(args.program).name}.elf"
        # hex_file = Path(args.program).parent / f"{Path(args.program).stem}.hex"
        # itb_file = Path(args.program).parent / f"{Path(args.program).stem}.itb"
        # program = Path(elf_file).stem
        # test_program_dir = (
        #     Path(vcs_out_dir) / "default" / program / "0" / "test_program"
        # )
        # bsp_dir = test_program_dir / "bsp"
        # test_program_dir.mkdir(parents=True, exist_ok=True)
        # for file in [elf_file, hex_file, itb_file]:
        #     # copy the file to the test_program_dir
        #     shutil.copy(file, test_program_dir)
    else:
        elf_file = Path(test_program_dir) / f"{program}.elf"
        hex_file = Path(test_program_dir) / f"{program}.hex"
        itb_file = Path(test_program_dir) / f"{program}.itb"

    # VCS compile flags setup
    vcs_compile_flags = " ".join(config.VCS_COMPILE_FLAGS)

    # Add uvmc_rvfi_decoder_pkg.sv to include path and file list
    vcs_compile_flags += f" +incdir+{DV_UVMC_RVFI_REFERENCE_MODEL_DIR} {DV_UVMC_RVFI_REFERENCE_MODEL_PKG_PATH} "

    vcs_compile_flags += sv_comp_define

    ###################################################################
    ################ SELECT THE CRT0 AND LINKER #######################
    ###################################################################
    if program == "riscv_arithmetic_basic_test_0":
        crt0_path = f"{CORE_V_VERIF}/cv32e20/tests/programs/custom/riscv_arithmetic_basic_test_0/riscv_arithmetic_basic_test_0.S"
    elif program == "simple_cv_addsub_test":
        crt0_path = f"{CORE_V_VERIF}/cv32e20/tests/programs/custom/simple_cv_addsub_test/simple_cv_addsub_test.S"
    elif program == "simple_cv_addsubls3_test":
        crt0_path = f"{CORE_V_VERIF}/cv32e20/tests/programs/custom/simple_cv_addsubls3_test/simple_cv_addsubls3_test.S"
    elif program == "simple_cv_clip_test":
        crt0_path = f"{CORE_V_VERIF}/cv32e20/tests/programs/custom/simple_cv_clip_test/simple_cv_clip_test.S"
    elif program == "simple_cv_cmpsimd_test":
        crt0_path = f"{CORE_V_VERIF}/cv32e20/tests/programs/custom/simple_cv_cmpsimd_test/simple_cv_cmpsimd_test.S"
    elif program == "simple_cv_dotpsimd_test":
        crt0_path = f"{CORE_V_VERIF}/cv32e20/tests/programs/custom/simple_cv_dotpsimd_test/simple_cv_dotpsimd_test.S"
    elif program == "simple_cv_genalu_test":
        crt0_path = f"{CORE_V_VERIF}/cv32e20/tests/programs/custom/simple_cv_genalu_test/simple_cv_genalu_test.S"
    elif program == "simple_cv_gensimd_test":
        crt0_path = f"{CORE_V_VERIF}/cv32e20/tests/programs/custom/simple_cv_gensimd_test/simple_cv_gensimd_test.S"
    elif program == "simple_cv_mac32_test":
        crt0_path = f"{CORE_V_VERIF}/cv32e20/tests/programs/custom/simple_cv_mac32_test/simple_cv_mac32_test.S"
    elif program == "simple_cv_mac168_test":
        crt0_path = f"{CORE_V_VERIF}/cv32e20/tests/programs/custom/simple_cv_mac168_test/simple_cv_mac168_test.S"
    elif program == "simple_cv_mul168_test":
        crt0_path = f"{CORE_V_VERIF}/cv32e20/tests/programs/custom/simple_cv_mul168_test/simple_cv_mul168_test.S"          
    elif program == "simple_cv_postinc_load_store_test":
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

    if program in ["hello-world", "fibonacci", "csr_instructions", "branch_zero", "dhrystone", "interrupt_test"]:
        c_files = f"{CORE_TB_PATH}/tests/programs/custom/{program}/{program}.c"
    elif program == "coremark":
        c_files = f"-DITERATIONS=1 \
            -DVALIDATION_RUN=1 \
            -DFLAGS_STR='\"-Os -g -static -mabi=ilp32 -march={march} -Wall -pedantic\"' \
            {CORE_TB_PATH}/tests/programs/custom/{program}/coremark.h \
            {CORE_TB_PATH}/tests/programs/custom/{program}/core_portme.h \
            {CORE_TB_PATH}/tests/programs/custom/{program}/core_portme.c \
            {CORE_TB_PATH}/tests/programs/custom/{program}/core_list_join.c \
            {CORE_TB_PATH}/tests/programs/custom/{program}/core_state.c \
            {CORE_TB_PATH}/tests/programs/custom/{program}/core_util.c\
            {CORE_TB_PATH}/tests/programs/custom/{program}/core_matrix.c \
            {CORE_TB_PATH}/tests/programs/custom/{program}/core_main.c"
    elif program == "test_read_write":
        linker_script = f"{CORE_V_VERIF}/design/top/rec/scripts/c/link_big_heap.ld"
        c_files = f"{CORE_V_VERIF}/CxR_tests/stream_read_write.cc \
            {CORE_V_VERIF}/CxR_tests/computeram.c \
            {CORE_V_VERIF}/CxR_tests/hardware_tests_utils.cc \
            {CORE_V_VERIF}/CxR_tests/chip_config.c"
    elif program == "test_trigger_compute":
        linker_script = f"{CORE_V_VERIF}/design/top/rec/scripts/c/link_big_heap.ld"
        c_files = f"{CORE_V_VERIF}/CxR_tests/trigger_compute.cc \
            {CORE_V_VERIF}/CxR_tests/computeram.c \
            {CORE_V_VERIF}/CxR_tests/hardware_tests_utils.cc \
            {CORE_V_VERIF}/CxR_tests/chip_config.c"
    elif program == "simple_test":
        linker_script = f"{CORE_V_VERIF}/design/top/rec/scripts/c/link_big_heap.ld"
        c_files = f"{CORE_V_VERIF}/CxR_tests/simple_test.cc \
            {CORE_V_VERIF}/CxR_tests/computeram.c \
            {CORE_V_VERIF}/CxR_tests/hardware_tests_utils.cc \
            {CORE_V_VERIF}/CxR_tests/chip_config.c"
    else:
        c_files = ""
        print(f"Program {program} not found. Assuming it is a precompiled program.")

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

    decoder_autogen_flags = ""

    if args.cop:
        decoder_autogen_flags += "--instantiate_cvxif"

    ###################################################################
    ################ FORMAT COMMANDS TEMPLATE   #######################
    ###################################################################
    
    # Put all the information flags into a single dictionary
    # With this dictionary you will format the commands
    fmt_dict = {
        "CORE_V_VERIF": CORE_V_VERIF,
        "VCS_HOME": VCS_HOME,
        "RISCV_OPCODES_DIR": RISCV_OPCODES_DIR,
        "cv_core": cv_core,
        "CORE_RTL_PATH": CORE_RTL_PATH,
        "CORE_TB_PATH": CORE_TB_PATH,
        "RISCV_EXE_PREFIX": RISCV_EXE_PREFIX,
        "DV_UVMC_RVFI_REFERENCE_MODEL_PKG_PATH": DV_UVMC_RVFI_REFERENCE_MODEL_PKG_PATH,
        "GCC": GCC,
        "GXX": GCC,
        "march": march,
        "core_dv_dir": core_dv_dir,
        "csrc_dir": csrc_dir,
        "vcs_out_dir": vcs_out_dir,
        "vcs_compile_flags": vcs_compile_flags,
        "kdb": kdb,
        "bsp_dir": bsp_dir,
        "crt0_path": crt0_path,
        "test_program_dir": test_program_dir,
        "program": program,
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
        "additional_string_sim": args.asf,
        "decoder_autogen_flags": decoder_autogen_flags,
        "uvm_verbosity": args.uvm_verbosity
    }

    google_compile_cmd = fmt.google_compile_cmd.format(**fmt_dict)

    dpi_compile_cmd = fmt.dpi_compile_cmd.format(**fmt_dict)

    bsp_compile_cmd = fmt.bsp_compile_cmd.format(**fmt_dict)

    test_program_compile_cmd = fmt.test_program_compile_cmd.format(**fmt_dict)

    hex_compile_cmd = fmt.hex_compile_cmd.format(**fmt_dict)

    sv_compile_cmd = fmt.sv_compile_cmd.format(**fmt_dict)

    sv_sim_cmd = fmt.sv_sim_cmd.format(**fmt_dict)
    
    rtl_git_cmd = fmt.rtl_git_cmd.format(**fmt_dict)
    
    tb_git_cmd = fmt.tb_git_cmd.format(**fmt_dict)
    
    parse_cmd = fmt.parse_cmd.format(**fmt_dict)

    autogen_cmd = fmt.autogen_cmd.format(**fmt_dict)

    ###################################################################
    ################ CREATE THE COMMAND DICT    #######################
    ###################################################################
    
    # These are always executed
    cmd_dict = {
        "rtl_git_cmd": rtl_git_cmd,
        "tb_git_cmd": tb_git_cmd,
        "parse_cmd": parse_cmd,
        "autogen_cmd": autogen_cmd
    }

    if args.sw_compile_only:
        cmd_dict |= {
            "bsp_compile_cmd": bsp_compile_cmd,
            "dpi_compile_cmd": dpi_compile_cmd,
            "test_program_compile_cmd": test_program_compile_cmd,
            "hex_compile_cmd": hex_compile_cmd,
        }
    elif args.sw_compile_only_bsp:
        cmd_dict |= {
            "bsp_compile_cmd": bsp_compile_cmd
        }
    elif args.rtl_only:
        cmd_dict |= {
            "sv_compile_cmd": sv_compile_cmd, 
            "sv_sim_cmd": sv_sim_cmd
        }
    elif args.rtl_compile_only:
        cmd_dict |= {
            "sv_compile_cmd": sv_compile_cmd
        }
    elif args.rtl_sim_only:
        cmd_dict |= {
            "sv_sim_cmd": sv_sim_cmd
        }
    else:
        cmd_dict |= {
            "bsp_compile_cmd": bsp_compile_cmd,
            "dpi_compile_cmd": dpi_compile_cmd,
            "test_program_compile_cmd": test_program_compile_cmd,
            "hex_compile_cmd": hex_compile_cmd,
            "sv_compile_cmd": sv_compile_cmd, 
            "sv_sim_cmd": sv_sim_cmd
        }

    # If the folder has not been built, this command is added at the beginning of the sw_cmd_dict
    # in order to build the folder before compiling the SW. The verilab folder will be filled with Spike files
    if not os.path.exists(VERILAB_DIR):
        spike_rc = compile_spike_main([])
        if spike_rc != 0:
            print("\033[91m" + "Error occurred in compileSpike. Exiting..." + "\033[0m")
            exit()

    for cmd_idx, (key, cmd) in enumerate(cmd_dict.items()):
        print("\n**********************************************************")
        print(f"{key}:\n{cmd}")
        print("**********************************************************")

        process = subprocess.Popen(cmd, shell=True)
        process.wait()

        if process.returncode != 0:
            print("\033[91m" + f"Error occurred in {key}. Exiting..." + "\033[0m")
            exit()
