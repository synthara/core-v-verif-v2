`include "uvm_macros.svh"

package uvmt_cv32e20_uvm_model_pkg;

    import uvm_pkg::*;
    import uvmt_cv32e20_pkg::*;
    import uvmc_rvfi_reference_model_pkg::*;
    import uvma_core_cntrl_pkg::*;
    import uvme_cv32e20_pkg::*;
    import uvmc_rvfi_scoreboard_pkg::*;

    `include "uvmc_cvxif_scoreboard.sv"
    `include "uvmt_cv32e20_uvm_model_rvfi.sv"
    `include "uvmt_cv32e20_uvm_model_cvxif.sv"

endpackage