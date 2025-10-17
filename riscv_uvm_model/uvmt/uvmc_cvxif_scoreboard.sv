// Copyright 2023 OpenHW Group
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


// `ifndef __uvmc_cvxif_scoreboard_SV__
// `define __uvmc_cvxif_scoreboard_SV__

`uvm_analysis_imp_decl(_cvx_instr)
`uvm_analysis_imp_decl(_cvx_req_rtl)
`uvm_analysis_imp_decl(_cvx_req_ref_model)
`uvm_analysis_imp_decl(_cvx_resp_ref_model)
`uvm_analysis_imp_decl(_cvx_resp_rtl)

import uvma_cvxif_pkg::*;

/*
 * Scoreboard component which compares CVXIF transactions comming from the
 * core and the reference model
 */
class uvmc_cvxif_scoreboard_c extends uvm_scoreboard;

   uvm_analysis_imp_cvx_resp_rtl#(uvma_cvxif_resp_item_c, uvmc_cvxif_scoreboard_c) m_imp_cvxif_resp_rtl;
   uvm_analysis_imp_cvx_resp_ref_model#(uvma_cvxif_resp_item_c, uvmc_cvxif_scoreboard_c) m_imp_cvxif_resp_ref_model;
   uvm_analysis_imp_cvx_req_rtl#(uvma_cvxif_req_item_c, uvmc_cvxif_scoreboard_c) m_imp_cvxif_req_rtl;
   uvm_analysis_imp_cvx_req_ref_model#(uvma_cvxif_req_item_c, uvmc_cvxif_scoreboard_c) m_imp_cvxif_req_ref_model;

   // Core configuration (used to extract list of CSRs)
   uvma_core_cntrl_cfg_c         cfg;
   bit [XLEN-1:0] sentinel_value;
   bit            sentinel_enable;

   `uvm_component_utils_begin(uvmc_cvxif_scoreboard_c)
      `uvm_field_object(cfg,         UVM_DEFAULT | UVM_REFERENCE)
   `uvm_component_utils_end

    uvma_cvxif_resp_item_c core_cvx_resp[$];
    uvma_cvxif_resp_item_c reference_model_cvx_resp[$];
    uvma_cvxif_req_item_c core_cvx_req[$];
    uvma_cvxif_req_item_c reference_model_cvx_req[$];

   /*
    * Default constructor.
    */
    function new(string name="uvmc_cvxif_scoreboard_c", uvm_component parent=null);

        super.new(name, parent);

        m_imp_cvxif_resp_ref_model = new("m_imp_cvxif_resp_ref_model", this);
        m_imp_cvxif_resp_rtl   = new("m_imp_cvxif_resp_rtl",   this);
        m_imp_cvxif_req_rtl      = new("m_imp_cvxif_req_rtl",       this);
        m_imp_cvxif_req_ref_model = new("m_imp_cvxif_req_ref_model", this);

    endfunction : new

   /**
    * Uses uvm_config_db to retrieve cfg and hand out to sub-components.
    */
   extern function void get_and_set_cfg();

   /*
    *  Build Phase
    */
   extern function void build_phase(uvm_phase phase);

   /*
    *  Run Phase
    */
   extern task run_phase(uvm_phase phase);

   function void write_cvx_resp_ref_model(uvma_cvxif_resp_item_c t);

      reference_model_cvx_resp.push_back(t);

   endfunction

   function void write_cvx_resp_rtl(uvma_cvxif_resp_item_c t);

      core_cvx_resp.push_back(t);

   endfunction

   function void write_cvx_req_rtl(uvma_cvxif_req_item_c t);

      core_cvx_req.push_back(t);

   endfunction

   function void write_cvx_req_ref_model(uvma_cvxif_req_item_c t);

      reference_model_cvx_req.push_back(t);

   endfunction

endclass : uvmc_cvxif_scoreboard_c

function void uvmc_cvxif_scoreboard_c::build_phase(uvm_phase phase);
    st_core_cntrl_cfg st;

    get_and_set_cfg();

    st = cfg.to_struct();

    if($test$plusargs("sentinel_value")) begin
        if ($value$plusargs("sentinel_value=%h", sentinel_value)) begin
            sentinel_enable = '1;
        end
    end

endfunction : build_phase

task uvmc_cvxif_scoreboard_c::run_phase(uvm_phase phase);

    bit sim_finished;

    sim_finished = 0;
    phase.raise_objection(this);

    fork

      // ========================
      // CVXIF thread
      // ========================
      begin : cvxif_thread_resp
        uvma_cvxif_resp_item_c model_trx;
        uvma_cvxif_resp_item_c rtl_trx;

        forever begin
          wait((reference_model_cvx_resp.size() > 0) ||
                sim_finished);
          if (sim_finished) break;

          if (reference_model_cvx_resp.size() > 0) begin
            model_trx = reference_model_cvx_resp.pop_front();
          end

          if (core_cvx_resp.size() > 0) begin
            rtl_trx = core_cvx_resp.pop_front();
          end

          if (!model_trx.compare(rtl_trx, uvm_default_comparer)) begin
            `uvm_error("CVXIF_SB", "CVXIF response mismatch (see field deltas above)")
            `uvm_info("CVXIF_SB",
            $sformatf("EXP: valid=%0b rd=%0d data=0x%08h\nACT: valid=%0b rd=%0d data=0x%08h",
                  model_trx.result_valid, model_trx.result.rd, model_trx.result.data,
                  rtl_trx.result_valid, rtl_trx.result.rd, rtl_trx.result.data),
            UVM_LOW)
          end
        end
      end


      begin : cvxif_thread_req

         uvma_cvxif_req_item_c model_trx;
         uvma_cvxif_req_item_c rtl_trx;

        forever begin
          wait((reference_model_cvx_req.size() > 0) ||
                sim_finished);
          if (sim_finished) break;

          if (reference_model_cvx_req.size() > 0) begin
            model_trx = reference_model_cvx_req.pop_front();
          end

          if (core_cvx_req.size() > 0) begin
            rtl_trx = core_cvx_req.pop_front();
          end

          if (!model_trx.compare(rtl_trx, uvm_default_comparer)) begin
            `uvm_error("CVXIF_SB", "CVXIF response mismatch (see field deltas above)")
            // `uvm_info("CVXIF_SB",
            // $sformatf("EXP: valid=%0b rd=%0d data=0x%08h\nACT: valid=%0b rd=%0d data=0x%08h",
            //       model_trx.result_valid, model_trx.result.rd, model_trx.result.data,
            //       rtl_trx.result_valid, rtl_trx.result.rd, rtl_trx.result.data),
            // UVM_LOW)
          end
        end
      end
    join

    phase.drop_objection(this);

endtask : run_phase

function void uvmc_cvxif_scoreboard_c::get_and_set_cfg();

   if (uvm_config_db#(uvma_core_cntrl_cfg_c)::get(this, "", "cfg", cfg)) begin
      `uvm_info("CFG", $sformatf("Found configuration handle:\n%s", cfg.sprint()), UVM_DEBUG)
      uvm_config_db#(uvma_core_cntrl_cfg_c)::set(this, "*", "cfg", cfg);
   end
   else begin
      `uvm_fatal("CFG", $sformatf("%s: Could not find configuration handle", this.get_full_name()));
   end

endfunction : get_and_set_cfg

// `endif

