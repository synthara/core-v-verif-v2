import os

class Config:

    def __init__(self, args, root_dir):

        self.RISCV_EXE_PREFIX                      = args.toolchain
        self.VCS_HOME                              = os.path.join(os.sep, "opt", "eda", "synopsys", "tools", "vcs", "latest")
        self.CORE_RTL_PATH                         = os.path.join(root_dir, "core-v-cores", args.core)
        self.CORE_TB_PATH                          = os.path.join(root_dir, args.core)
        self.VERILAB_DIR                           = os.path.join(self.CORE_TB_PATH, "vendor_lib", "verilab", "svlib")
        self.RISCV_OPCODES_DIR                     = os.path.join(root_dir, "riscv-opcodes")
        self.RISCV_OPCODES_CONFIG_PATH             = os.path.join(root_dir, "riscv_uvm_model", "autogen", "config", "model_config.json")
        self.DV_UVMC_RVFI_REFERENCE_MODEL_DIR      = os.path.join(root_dir, "lib", "uvm_components", "uvmc_rvfi_reference_model")
        self.DV_UVMC_RVFI_REFERENCE_MODEL_PATH     = self.DV_UVMC_RVFI_REFERENCE_MODEL_DIR
        self.DV_UVMC_RVFI_REFERENCE_MODEL_PKG_PATH = os.path.join(self.DV_UVMC_RVFI_REFERENCE_MODEL_DIR, "uvmc_rvfi_decoder_pkg.sv")
        self.UVMT_CV32E20_UVM_MODEL_PKG_PATH       = os.path.join(root_dir, "riscv_uvm_model", "uvmt")
        self.CV_SW_TOOLCHAIN                       = self.RISCV_EXE_PREFIX.split("/bin/")[0]
        self.SPIKE_PATH                            = os.path.join(root_dir, "vendor", "riscv", "riscv-isa-sim")
        self.CV_CORE_LC                            = args.core
        self.OUT_DIR                               = args.out_dir
        self.VCS_OUT_DIR                           = os.path.join(self.OUT_DIR, "default", "vcs_results")
        self.CORE_DV_DIR                           = os.path.join(self.OUT_DIR, "default", "corev-dv")
        self.CSRC_DIR                              = os.path.join(self.VCS_OUT_DIR, "csrc")
        self.TEST_PROGRAM_DIR                      = os.path.join(self.VCS_OUT_DIR, "default", args.program, str(args.test_idx), "test_program")
        self.BSP_DIR                               = os.path.join(self.TEST_PROGRAM_DIR, "bsp")
        self.VCS_DEFINES = [
            "+define+VCS",
            "+define+GNT",
            "+define+BASE",
            "+define+UVM",
            "+define+CV32E20_RVFI+RVFI",
            "+define+CV32E20_TRACE_EXECUTION",
            "+define+CV32E20_ASSERT_ON"
        ]
        self.VCS_COMPILE_FLAGS = [
            "-suppress=PCTI-L",
            "-suppress=UII-L",
            "-kdb=common_elab",
            "-debug_acc+all",
            "-debug_region+cell+encrypt",
            "-fgp=num_threads:8",
            "-fgp=auto_affinity:allowHyperThreadCpu",
            "+gc+high_threshold+5",
            "+UVM_NO_RELNOTES",
            "+USE_ISS",
            "-lca",
            "-sverilog",
            "-ntb_opts uvm-1.2",
            "-timescale=1ns/1ps",
            "-assert svaext",
            "-race=all",
            "-ignore unique_checks",
            "-full64",
            "-reportstats",
            "-notice",
            "-line",
            "-fgp=multisocket"
        ]

        self.CORE_V_VERIF = root_dir
        self.DV_UVMT_PATH = os.path.join(self.CORE_V_VERIF, self.CV_CORE_LC, "tb", "uvmt")
        self.DV_UVME_PATH = os.path.join(self.CORE_V_VERIF, self.CV_CORE_LC, "env", "uvme")
        self.DV_UVML_HRTBT_PATH = os.path.join(self.CORE_V_VERIF, "lib", "uvm_libs", "uvml_hrtbt")
        self.DV_UVMA_ISACOV_PATH = os.path.join(self.CORE_V_VERIF, "lib", "uvm_agents", "uvma_isacov")
        self.DV_UVMA_CLKNRST_PATH = os.path.join(self.CORE_V_VERIF, "lib", "uvm_agents", "uvma_clknrst")
        self.DV_UVMA_INTERRUPT_PATH = os.path.join(self.CORE_V_VERIF, "lib", "uvm_agents", "uvma_interrupt")
        self.DV_UVMA_DEBUG_PATH = os.path.join(self.CORE_V_VERIF, "lib", "uvm_agents", "uvma_debug")
        self.DV_UVML_TRN_PATH = os.path.join(self.CORE_V_VERIF, "lib", "uvm_libs", "uvml_trn")
        self.DV_UVML_LOGS_PATH = os.path.join(self.CORE_V_VERIF, "lib", "uvm_libs", "uvml_logs")
        self.DV_UVML_SB_PATH = os.path.join(self.CORE_V_VERIF, "lib", "uvm_libs", "uvml_sb")
        self.DV_OVPM_HOME = os.path.join(self.CORE_V_VERIF, "vendor_lib", "imperas")
        self.DV_OVPM_MODEL = os.path.join(self.DV_OVPM_HOME, "imperas_DV_COREV")
        self.DV_OVPM_DESIGN = os.path.join(self.DV_OVPM_HOME, "design")
        self.DV_UVMA_CORE_CNTRL_PATH = os.path.join(self.CORE_V_VERIF, "lib", "uvm_agents", "uvma_core_cntrl")
        self.DV_UVMA_RVFI_PATH = os.path.join(self.CORE_V_VERIF, "lib", "uvm_agents", "uvma_rvfi")
        self.DV_UVMA_RVVI_PATH = os.path.join(self.CORE_V_VERIF, "lib", "uvm_agents", "uvma_rvvi")
        self.DV_UVMA_CVXIF_PATH = os.path.join(self.CORE_V_VERIF, "lib", "uvm_agents", "uvma_cvxif")
        self.DV_UVMA_RVVI_OVPSIM_PATH = os.path.join(self.CORE_V_VERIF, "lib", "uvm_agents", "uvma_rvvi_ovpsim")
        self.DV_UVMA_PMA_PATH = os.path.join(self.CORE_V_VERIF, "lib", "uvm_agents", "uvma_pma")
        self.DV_UVMA_OBI_MEMORY_PATH = os.path.join(self.CORE_V_VERIF, "lib", "uvm_agents", "uvma_obi_memory")
        self.DV_UVMA_FENCEI_PATH = os.path.join(self.CORE_V_VERIF, "lib", "uvm_agents", "uvma_fencei")
        self.DV_UVML_MEM_PATH = os.path.join(self.CORE_V_VERIF, "lib", "uvm_libs", "uvml_mem")
        self.DV_UVMC_RVFI_SCOREBOARD_PATH = os.path.join(self.CORE_V_VERIF, "lib", "uvm_components", "uvmc_rvfi_scoreboard")
        self.DV_SVLIB_PATH = os.path.join(self.CORE_V_VERIF, self.CV_CORE_LC, "vendor_lib", "verilab")
        self.TBSRC_HOME = os.path.join(self.CORE_V_VERIF, self.CV_CORE_LC, "tb")
        self.DESIGN_RTL_DIR = os.path.join(self.CORE_RTL_PATH, "rtl")
        self.CV_CORE_MANIFEST = os.path.join(self.CORE_RTL_PATH, f"{self.CV_CORE_LC}_manifest.flist")
        self.DPI_DASM_ROOT = os.path.join(self.CORE_V_VERIF, "lib", "dpi_dasm")

        self.RVV_PATH = os.path.join(self.CORE_RTL_PATH, "..", "xcs")
        self.DSL_PATH = os.path.join(self.CORE_RTL_PATH, "..", "xcs", "src", "dsl")
        self.DMV_PATH = os.path.join(self.CORE_RTL_PATH, "..", "lsu")

    def export_env(self):
        os.environ["RISCV_EXE_PREFIX"] = self.RISCV_EXE_PREFIX
        os.environ["VCS_HOME"] = self.VCS_HOME

        os.environ["CORE_RTL_PATH"]                     = self.CORE_RTL_PATH
        os.environ["CORE_TB_PATH"]                      = self.CORE_TB_PATH
        os.environ["VERILAB_DIR"]                       = self.VERILAB_DIR
        os.environ["RISCV_OPCODES_DIR"]                 = self.RISCV_OPCODES_DIR
        os.environ["RISCV_OPCODES_CONFIG_PATH"]         = self.RISCV_OPCODES_CONFIG_PATH
        os.environ["DV_UVMC_RVFI_REFERENCE_MODEL_DIR"]  = self.DV_UVMC_RVFI_REFERENCE_MODEL_DIR
        os.environ["DV_UVMC_RVFI_REFERENCE_MODEL_PATH"]  = self.DV_UVMC_RVFI_REFERENCE_MODEL_PATH
        os.environ["DV_UVMC_RVFI_REFERENCE_MODEL_PKG_PATH"]  = self.DV_UVMC_RVFI_REFERENCE_MODEL_PKG_PATH
        os.environ["UVMT_CV32E20_UVM_MODEL_PKG_PATH"]   = self.UVMT_CV32E20_UVM_MODEL_PKG_PATH
        os.environ["CV_SW_TOOLCHAIN"]                   = self.CV_SW_TOOLCHAIN
        os.environ["SPIKE_PATH"]                        = self.SPIKE_PATH
        os.environ["CV_CORE_LC"]                        = self.CV_CORE_LC

        os.environ["DV_UVMT_PATH"]                  = self.DV_UVMT_PATH
        os.environ["DV_UVME_PATH"]                  = self.DV_UVME_PATH
        os.environ["DV_UVML_HRTBT_PATH"]            = self.DV_UVML_HRTBT_PATH
        os.environ["DV_UVMA_ISACOV_PATH"]           = self.DV_UVMA_ISACOV_PATH
        os.environ["DV_UVMA_CLKNRST_PATH"]          = self.DV_UVMA_CLKNRST_PATH
        os.environ["DV_UVMA_INTERRUPT_PATH"]        = self.DV_UVMA_INTERRUPT_PATH
        os.environ["DV_UVMA_DEBUG_PATH"]            = self.DV_UVMA_DEBUG_PATH
        os.environ["DV_UVML_TRN_PATH"]              = self.DV_UVML_TRN_PATH
        os.environ["DV_UVML_LOGS_PATH"]             = self.DV_UVML_LOGS_PATH
        os.environ["DV_UVML_SB_PATH"]               = self.DV_UVML_SB_PATH
        os.environ["DV_OVPM_HOME"]                  = self.DV_OVPM_HOME
        os.environ["DV_OVPM_MODEL"]                 = self.DV_OVPM_MODEL
        os.environ["DV_OVPM_DESIGN"]                = self.DV_OVPM_DESIGN
        os.environ["DV_UVMA_CORE_CNTRL_PATH"]       = self.DV_UVMA_CORE_CNTRL_PATH
        os.environ["DV_UVMA_RVFI_PATH"]             = self.DV_UVMA_RVFI_PATH
        os.environ["DV_UVMA_RVVI_PATH"]             = self.DV_UVMA_RVVI_PATH
        os.environ["DV_UVMA_CVXIF_PATH"]            = self.DV_UVMA_CVXIF_PATH
        os.environ["DV_UVMA_RVVI_OVPSIM_PATH"]      = self.DV_UVMA_RVVI_OVPSIM_PATH
        os.environ["DV_UVMA_PMA_PATH"]              = self.DV_UVMA_PMA_PATH
        os.environ["DV_UVMA_OBI_MEMORY_PATH"]       = self.DV_UVMA_OBI_MEMORY_PATH
        os.environ["DV_UVMA_FENCEI_PATH"]           = self.DV_UVMA_FENCEI_PATH
        os.environ["DV_UVML_MEM_PATH"]              = self.DV_UVML_MEM_PATH
        os.environ["DV_UVMC_RVFI_SCOREBOARD_PATH"]  = self.DV_UVMC_RVFI_SCOREBOARD_PATH
        os.environ["DV_UVMC_RVFI_REFERENCE_MODEL_DIR"] = self.DV_UVMC_RVFI_REFERENCE_MODEL_DIR
        os.environ["DV_SVLIB_PATH"]                 = self.DV_SVLIB_PATH
        os.environ["TBSRC_HOME"]                    = self.TBSRC_HOME
        os.environ["DESIGN_RTL_DIR"]                = self.DESIGN_RTL_DIR
        os.environ["CV_CORE_MANIFEST"]              = self.CV_CORE_MANIFEST
        os.environ["DPI_DASM_ROOT"]                 = self.DPI_DASM_ROOT

        os.environ["RVV_PATH"]                      = self.RVV_PATH
        os.environ["DSL_PATH"]                      = self.DSL_PATH
        os.environ["DMV_PATH"]                      = self.DMV_PATH