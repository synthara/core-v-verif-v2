// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Copyright 2020,2023 OpenHW Group
// Copyright 2020 Datum Technology Corporation
// Copyright 2020 Silicon Labs, Inc.
//
// Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://solderpad.org/licenses/
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
///////////////////////////////////////////////////////////////////////////////


`ifndef __UVMT_CV32E20_DUT_WRAP_WITH_CVXIF_SV__
`define __UVMT_CV32E20_DUT_WRAP_WITH_CVXIF_SV__

import uvm_pkg::*; // needed for the UVM messaging service (`uvm_info(), etc.)
import cve2_pkg::*;// definitions of enumerated types used by cve2
import uvmt_cv32e20_pkg::*;

/**
 * Wrapper for the CV32E20 RTL DUT.
 * Includes the RVFI Tracer and the IBEX core.
 */
module uvmt_cv32e20_dut_wrap #(
                            // CV32E20 parameters.  See User Manual.
                            parameter int unsigned MHPMCounterNum    = 10,
                            parameter int unsigned MHPMCounterWidth  = 40,
                            parameter bit          RV32E             = 1'b0,
                            parameter rv32m_e      RV32M             = RV32MFast,
                            parameter bit          BranchPredictor   = 1'b0,
                            parameter int unsigned DmHaltAddr        = 32'h1A11_0800,
                            parameter int unsigned DmExceptionAddr   = 32'h1A14_0000,
                            // Remaining parameters are used by TB components only
                            parameter int unsigned INSTR_ADDR_WIDTH    =  32,
                            parameter int unsigned INSTR_RDATA_WIDTH   =  32,
                            parameter int unsigned RAM_ADDR_WIDTH      =  22
                           )

                           (
                            uvma_clknrst_if              clknrst_if,
                            uvma_interrupt_if            interrupt_if,
                            // vp_status_if is driven by ENV and used in TB
                            uvma_interrupt_if            vp_interrupt_if,
                            uvme_cv32e20_core_cntrl_if   core_cntrl_if,
                            uvmt_cv32e20_core_status_if  core_status_if,
                            uvma_obi_memory_if           obi_memory_instr_if,
                            uvma_obi_memory_if           obi_memory_data_if,
                            uvma_cvxif_intf              cvxif_if
                           );

    // signals connecting core to memory
    logic                         instr_req;
    logic                         instr_gnt;
    logic                         instr_rvalid;
    logic [INSTR_ADDR_WIDTH-1 :0] instr_addr;
    logic [INSTR_RDATA_WIDTH-1:0] instr_rdata;

    logic                         data_req;
    logic                         data_gnt;
    logic                         data_rvalid;
    logic [31:0]                  data_addr;
    logic                         data_we;
    logic [3:0]                   data_be;
    logic [31:0]                  data_rdata;
    logic [31:0]                  data_wdata;

    logic [31:0]                  irq_vp;
    logic [31:0]                  irq_uvma;
    logic [31:0]                  irq;
    logic                         irq_ack;
    logic [ 4:0]                  irq_id;

    logic                         debug_req_vp;
    logic                         debug_req_uvma;
    logic                         debug_req;
    logic                         debug_havereset;
    logic                         debug_running;
    logic                         debug_halted;

    assign debug_if.clk      = clknrst_if.clk;
    assign debug_if.reset_n  = clknrst_if.reset_n;
    assign debug_req_uvma    = debug_if.debug_req;

    assign debug_req = debug_req_vp | debug_req_uvma;

    // --------------------------------------------
    // Instruction bus is read-only, OBI v1.0
    assign obi_memory_instr_if.we        = 'b0;
    assign obi_memory_instr_if.be        = '1;
    // Data bus is read/write, OBI v1.0

    // --------------------------------------------
    // Connect to uvma_interrupt_if
    assign interrupt_if.clk                     = clknrst_if.clk;
    assign interrupt_if.reset_n                 = clknrst_if.reset_n;
    assign irq_uvma                             = interrupt_if.irq;
    assign interrupt_if.irq_id                  = cv32e20_top_i.u_cve2_top.u_cve2_core.id_stage_i.controller_i.exc_cause_o[4:0]; //irq_id;
//    assign interrupt_if.irq_ack                 = cv32e20_top_i.u_cve2_top.u_cve2_core.id_stage_i.controller_i.handle_irq; //irq_ack;
    assign interrupt_if.irq_ack                 = (cv32e20_top_i.u_cve2_top.u_cve2_core.id_stage_i.controller_i.ctrl_fsm_cs == 4'h7);//irq_ack

    assign vp_interrupt_if.clk                  = clknrst_if.clk;
    assign vp_interrupt_if.reset_n              = clknrst_if.reset_n;
    assign irq_vp                               = irq_uvma;
    // {irq_q[31:16], pending_enabled_irq_q[11], pending_enabled_irq_q[3], pending_enabled_irq_q[7]}
    // was vp_interrupt_if.irq;
    assign vp_interrupt_if.irq_id               = cv32e20_top_i.u_cve2_top.u_cve2_core.id_stage_i.controller_i.exc_cause_o[4:0];    //irq_id;
    assign vp_interrupt_if.irq_ack              = (cv32e20_top_i.u_cve2_top.u_cve2_core.id_stage_i.controller_i.ctrl_fsm_cs == 4'h7);//irq_ack

    assign irq = irq_uvma | irq_vp;

//---------------------------------------------------------------------------------
    // CV-X-IF intermediate signals
    logic          x_issue_valid;
    logic          x_issue_ready;
    x_issue_req_t  x_issue_req;
    x_issue_resp_t x_issue_resp;

    // Register Interface   
    x_register_t   x_register;

    // Commit Interface   
    logic          x_commit_valid;
    x_commit_t     x_commit;

    // Result Interface   
    logic          x_result_valid;
    logic          x_result_ready;
    x_result_t     x_result;

    // CSR vec mode
    logic[DATA_WIDTH-1:0]          csr_vec_mode;

    // DMV intermediate signals
    snt_std_if dmv_std();
    always_comb dmv_std.clk = clknrst_if.clk;   
    always_comb dmv_std.resetn = clknrst_if.reset_n;

    // Signals used for datamover integration
    logic [NUM_RF_SSR_PORT-1:0] ssr_valid;
    logic [NUM_RF_SSR_PORT-1:0] ssr_ready;
    logic [NUM_RF_SSR_PORT-1:0][4:0] ssr_addr;
    logic [NUM_RF_SSR_READ_PORT-1:0][31:0] ssr_rdata;
    logic [31:0] ssr_wdata;

    logic data_req, data_gnt, data_rvalid, data_we;
    logic [31:0] data_addr, data_wdata, data_rdata;
    logic [3:0] data_be;

    logic [31:0] csr_ssr_start;
//---------------------------------------------------------------------------------

// --------------------------------------------------------------------------------
    // Instantiate the core
    //cve2_top #(
    cve2_top_tracing #(
               .MHPMCounterNum   (MHPMCounterNum),
               .MHPMCounterWidth (MHPMCounterWidth),
               .RV32E            (RV32E),
               .RV32M            (RV32M),
               .DmHaltAddr       (DmHaltAddr),
               .DmExceptionAddr  (DmExceptionAddr),
               .XInterface       (1'b1)
              )
    cv32e20_top_i
        (
         .clk_i                  ( clknrst_if.clk                      ),
         .rst_ni                 ( clknrst_if.reset_n                  ),

         .test_en_i              ( 1'b1                                ), // enable all clock gates for testing
         .ram_cfg_i              ( prim_ram_1p_pkg::RAM_1P_CFG_DEFAULT ),

         .hart_id_i              ( 32'h0000_0000                       ),
         .boot_addr_i            ( core_cntrl_if.boot_addr             ), //<---MJS changing to 0

         // Instruction memory interface
         .instr_req_o            ( obi_memory_instr_if.req             ), // core to agent
         .instr_gnt_i            ( obi_memory_instr_if.gnt             ), // agent to core
         .instr_rvalid_i         ( obi_memory_instr_if.rvalid          ),
         .instr_addr_o           ( obi_memory_instr_if.addr            ),
         .instr_rdata_i          ( obi_memory_instr_if.rdata           ),
         .instr_err_i            ( '0                                  ),

         // Data memory interface
         .data_req_o             ( data_req                            ),
         .data_gnt_i             ( data_gnt                            ),
         .data_rvalid_i          ( data_rvalid                         ),
         .data_we_o              ( data_we                             ),
         .data_be_o              ( data_be                             ),
         .data_addr_o            ( data_addr                           ), 
         .data_wdata_o           ( data_wdata                          ),
         .data_rdata_i           ( data_rdata                          ),
         .data_err_i             ( '0                                  ),

//---------------------------------------------------------------------------------

         // Core-V eXtension Interface
         // Issue Interface
         .x_issue_valid_o        ( x_issue_valid                       ),
         .x_issue_ready_i        ( x_issue_ready                       ),
         .x_issue_req_o          ( x_issue_req                         ),
         .x_issue_resp_i         ( x_issue_resp                        ),

         // Register Interface   
         .x_register_o           ( x_register                          ),

         // Commit Interface   
         .x_commit_valid_o       ( x_commit_valid                      ),
         .x_commit_o             ( x_commit                            ),

         // Result Interface   
         .x_result_valid_i       ( x_result_valid                      ),
         .x_result_ready_o       ( x_result_ready                      ),
         .x_result_i             ( x_result                            ),

         // CSR vec mode
         .csr_vec_mode_o         ( csr_vec_mode                        ),
  //---------------------------------------------------------------------------------

         // SSR interfaces
         .ssr_valid_o            ( ssr_valid                           ),
         .ssr_ready_i            ( ssr_ready                           ),
         .ssr_addr_o             ( ssr_addr                            ),
         .ssr_rdata_i            ( ssr_rdata                           ),
         .ssr_wdata_o            ( ssr_wdata                           ),

         // SSR config CSR register 
         .csr_ssr_start_o        ( csr_ssr_start                         ),
//---------------------------------------------------------------------------------

         // Interrupt inputs
         .irq_software_i         ( irq_uvma[3]                         ),
         .irq_timer_i            ( irq_uvma[7]                         ),
         .irq_external_i         ( irq_uvma[11]                        ),
         .irq_fast_i             ( irq_uvma[31:16]                     ),
         .irq_nm_i               ( irq_uvma[0]                         ),       // non-maskeable interrupt

         // Debug Interface
         .debug_req_i             (debug_req_uvma                      ),
         .crash_dump_o            (),

         // RISC-V Formal Interface
         // Does not comply with the coding standards of _i/_o suffixes, but follows
         // the convention of RISC-V Formal Interface Specification.
         // CPU Control Signals

         .fetch_enable_i          (core_cntrl_if.fetch_en              ), // fetch_enable_t
         .core_sleep_o            ()
        );

        //=== CVXIF Interface Binding ===
        assign cvxif_if.issue_valid                = x_issue_valid;
        assign cvxif_if.issue_req.instr            = x_issue_req.instr;
        assign cvxif_if.issue_resp.accept          = x_issue_resp.accept;
        assign cvxif_if.issue_resp.writeback       = x_issue_resp.writeback;
        assign cvxif_if.issue_resp.register_read   = x_issue_resp.register_read;
        assign cvxif_if.issue_ready                = x_issue_ready;
        assign cvxif_if.register.rs_valid          = x_register.rs_valid;
        assign cvxif_if.register.rs[0]             = x_register.rs[0];
        assign cvxif_if.register.rs[1]             = x_register.rs[1];
        assign cvxif_if.register.rs[2]             = x_register.rs[2];
        assign cvxif_if.commit_valid               = x_commit_valid;
        assign cvxif_if.commit_req.commit_kill     = x_commit.commit_kill;
        assign cvxif_if.result_valid               = x_result_valid;
        assign cvxif_if.result_ready               = x_result_ready;
        assign cvxif_if.result.data                = x_result.data;
        assign cvxif_if.result.rd                  = x_result.rd;
        assign cvxif_if.result.we                  = x_result.we;

//---------------------------------------------------------------------------------
      // Coprocessor instance
       rvv_xcs_wrp i_rvv_xcs_wrp
         (
          // std if signals
          .clk(clknrst_if.clk),
          .resetn(clknrst_if.reset_n),

          // CV-X-IF Issue interface signals.
          .issue_valid(x_issue_valid),
          .issue_ready(x_issue_ready),
          .issue_req_flatten(x_issue_req),
          .issue_resp_flatten(x_issue_resp),

          // CV-X-IF Register interface signals.
          .register_valid(),
          .register_ready(),
          .register_flatten(x_register),

          // CV-X-IF Commit interface signals.
          .commit_valid(x_commit_valid),
          .commit_flatten(x_commit),

          // CV-X-IF Result interface signals.
          .result_ready(x_result_ready),
          .result_valid(x_result_valid),
          .result_flatten(x_result),

          //CSR vec mode.
          .csr_vec_mode_flatten(csr_vec_mode)
         );

//---------------------------------------------------------------------------------
      // Datamover instance

      // Enable interface
      status_if#(.DTYPE(cpu_dmv_start_status_dtype)) cpu_dmv_start_status();
      always_comb cpu_dmv_start_status.packet = csr_ssr_start[NUM_AGU-1:0];

      // Config request interface
      val_ena_if#(.DTYPE(cpu_dmv_lsu_request_packet_dtype)) cpu_dmv_lsu_request();
      always_comb cpu_dmv_lsu_request.valid = data_req;
      always_comb data_gnt = cpu_dmv_lsu_request.enable;
      always_comb cpu_dmv_lsu_request.packet.address = data_addr;
      always_comb cpu_dmv_lsu_request.packet.data = data_wdata;
      always_comb cpu_dmv_lsu_request.packet.we = data_we;
      always_comb cpu_dmv_lsu_request.packet.be = data_be;

      // Config response interface
      val_if#(.DTYPE(data_dtype)) dmv_cpu_lsu_response();
      always_comb data_rvalid = dmv_cpu_lsu_response.valid;
      always_comb data_rdata = dmv_cpu_lsu_response.packet;

      // Read interface 
      val_ena_req_resp_if#(.DTYPE_REQ(stream_addr_dtype), .DTYPE_RESP(data_dtype)) cpu_dmv_read[NUM_RF_SSR_READ_PORT-1:0]();
      for(genvar RF_SSR_READ_PORT_IDX = 0; RF_SSR_READ_PORT_IDX < NUM_RF_SSR_READ_PORT; RF_SSR_READ_PORT_IDX++) begin
          always_comb cpu_dmv_read[RF_SSR_READ_PORT_IDX].valid = ssr_valid[RF_SSR_READ_PORT_IDX];
          always_comb ssr_ready[RF_SSR_READ_PORT_IDX] = cpu_dmv_read[RF_SSR_READ_PORT_IDX].enable;
          always_comb cpu_dmv_read[RF_SSR_READ_PORT_IDX].req_packet = ssr_addr[RF_SSR_READ_PORT_IDX];
          always_comb ssr_rdata[RF_SSR_READ_PORT_IDX] = cpu_dmv_read[RF_SSR_READ_PORT_IDX].resp_packet;
      end

      // Write interface
      val_ena_if#(.DTYPE(cpu_dmv_write_packet_dtype)) cpu_dmv_write[NUM_WRITE_STREAM-1:0]();
      always_comb cpu_dmv_write[0].valid = ssr_valid[NUM_RF_SSR_PORT-1];
      always_comb ssr_ready[NUM_RF_SSR_PORT-1] = cpu_dmv_write[0].enable;
      always_comb cpu_dmv_write[0].packet.address = ssr_addr[NUM_RF_SSR_PORT-1];
      always_comb cpu_dmv_write[0].packet.data = ssr_wdata;



      // Memory request interface
      val_ena_if#(.DTYPE(dmv_mem_packet_dtype)) dmv_mem[NUM_AGU-1:0]();
      assign obi_memory_data_if.req = dmv_mem[0].valid;
      assign dmv_mem[0].enable = obi_memory_data_if.gnt;
      assign obi_memory_data_if.addr = dmv_mem[0].packet.address;
      assign obi_memory_data_if.wdata = dmv_mem[0].packet.data;
      assign obi_memory_data_if.we = dmv_mem[0].packet.we;
      assign obi_memory_data_if.be = dmv_mem[0].packet.be;

      // Memory response interface
      val_if#(.DTYPE(data_dtype)) mem_dmv[NUM_AGU-1:0]();
      always_comb mem_dmv[0].valid = obi_memory_data_if.rvalid;
      always_comb mem_dmv[0].packet = obi_memory_data_if.rdata;

      localparam stream_addr_dtype LANE_ADDR[NUM_AGU-1:0] = '{5'd30};

      sls_dmv#(
        .LANE_ADDR(LANE_ADDR)
      ) i_sls_dmv (
        .dmv_std(dmv_std),
        .cpu_dmv_start_status(cpu_dmv_start_status),
        .cpu_dmv_lsu_request(cpu_dmv_lsu_request),
        .dmv_cpu_lsu_response(dmv_cpu_lsu_response),
        .cpu_dmv_read(cpu_dmv_read),
        .cpu_dmv_write(cpu_dmv_write),
        .dmv_mem(dmv_mem),
        .mem_dmv(mem_dmv)
      );
//---------------------------------------------------------------------------------

`define RVFI_INSTR_PATH rvfi_instr_if
`define RVFI_CSR_PATH   rvfi_csr_if
`define DUT_PATH        cv32e20_top_i
`define CSR_PATH        `DUT_PATH.u_cve2_top.u_cve2_core.cs_registers_i


endmodule : uvmt_cv32e20_dut_wrap

`endif // __UVMT_CV32E20_DUT_WRAP_WITH_CVXIF_SV__


