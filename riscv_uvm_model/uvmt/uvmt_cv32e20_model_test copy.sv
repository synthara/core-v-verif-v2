`ifndef __UVMT_CV32E20_MODEL_TEST_SV__
`define __UVMT_CV32E20_MODEL_TEST_SV__

import uvmc_rvfi_reference_model_pkg::*;
import uvma_core_cntrl_pkg::*;
import uvme_cv32e20_pkg::*;
import uvmc_rvfi_scoreboard_pkg::*;
import uvma_cvxif_pkg::*;


class uvmt_cv32e20_model_test_c extends uvmt_cv32e20_firmware_test_c;

    `uvm_component_utils_begin(uvmt_cv32e20_model_test_c)
    `uvm_object_utils_end

    function new(string name = "uvmt_cv32e20_model_test", uvm_component parent = null);
        super.new(name, parent);
        `uvm_info("TEST", "This is the MODEL TEST", UVM_NONE)
    endfunction: new

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        `uvm_info("model_test", "Overriding Reference Model with UVM model", UVM_NONE)
        set_type_override_by_type(uvmc_rvfi_reference_model#()::get_type(), uvmc_rvfi_decoder_model#()::get_type());

    endfunction: build_phase

endclass: uvmt_cv32e20_model_test_c

class uvme_cv32e20_sb_dual_ref_c extends uvme_cv32e20_sb_c;

    uvmc_rvfi_scoreboard_c#(ILEN, uvme_cv32e20_pkg::XLEN) m_rvfi_scoreboard2;

    uvmc_rvfi_scoreboard_cvxif_c m_rvfi_scoreboard_cvxif;

    `uvm_component_utils_begin(uvme_cv32e20_sb_dual_ref_c)
        `uvm_field_object(cfg, UVM_DEFAULT)
        `uvm_field_object(cntxt, UVM_DEFAULT)
    `uvm_component_utils_end

    function new(string name = "uvme_cv32e20_sb_dual_ref", uvm_component parent = null);

        super.new(name, parent);

    endfunction: new

    function void create_sbs();
        super.create_sbs();

        m_rvfi_scoreboard2 = uvmc_rvfi_scoreboard_c#(ILEN, uvme_cv32e20_pkg::XLEN)::type_id::create("m_rvfi_scoreboard2", this);

         m_rvfi_scoreboard_cvxif = uvmc_rvfi_scoreboard_cvxif_c::type_id::create("m_rvfi_scoreboard_cvxif", this);

    endfunction: create_sbs

endclass: uvme_cv32e20_sb_dual_ref_c

class uvme_cv32e20_env_dual_ref_c extends uvme_cv32e20_env_c;

    uvmc_rvfi_reference_model reference_model2;

    uvme_cv32e20_sb_dual_ref_c dual_sb;

    uvma_cvxif_agent_c cvxif_agent;

    function new(string name = "uvme_cv32e20_env_dual_ref", uvm_component parent = null);
        super.new(name, parent);
        $display("I have been created and i am environment");

        set_type_override_by_type(uvme_cv32e20_sb_c::get_type(), uvme_cv32e20_sb_dual_ref_c::get_type());

    endfunction: new

    `uvm_component_utils_begin(uvme_cv32e20_env_dual_ref_c)
        `uvm_field_object(cfg, UVM_DEFAULT)
        `uvm_field_object(cntxt, UVM_DEFAULT)
    `uvm_component_utils_end

    function void create_agents();

      super.create_agents();
      cvxif_agent             = uvma_cvxif_agent_c     ::type_id::create("cvxif_agent",            this);
      
    endfunction: create_agents

    function void assign_cfg();

        super.assign_cfg();

        uvm_config_db#(uvma_cvxif_cfg_c)::set(this, "cvxif_agent", "cfg", cfg.cvxif_cfg);

            uvm_config_db#(uvma_core_cntrl_cfg_c)::set(this, "reference_model2", "cfg", cfg);
            uvm_config_db#(uvma_core_cntrl_cfg_c)::set(this, "*m_rvfi_scoreboard2", "cfg", cfg);
            uvm_config_db#(uvma_core_cntrl_cfg_c)::set(this, "*m_rvfi_scoreboard_cvxif", "cfg", cfg);


    endfunction: assign_cfg

    function void create_env_components();

        super.create_env_components();


            reference_model2 = uvmc_rvfi_reference_model#(ILEN, uvme_cv32e20_pkg::XLEN)::type_id::create("reference_model2", this);


    endfunction: create_env_components

    function void connect_scoreboard();

        super.connect_scoreboard();

        // Cast the sb to dual_sb so that the m_rvfi_scoreboard2 is visible
        // m_rvfi_scoreboard2 is not present in the base class but in the extended class
        $cast(dual_sb, sb);
        if (! $cast(dual_sb, sb)) begin
            `uvm_fatal("DUAL_SB", "Factory override failed")
        end

        rvfi_agent.rvfi_core_ap.connect(dual_sb.m_rvfi_scoreboard2.m_imp_core);
        rvfi_agent.rvfi_core_ap.connect(reference_model2.m_analysis_imp);
        reference_model2.m_analysis_port.connect(dual_sb.m_rvfi_scoreboard2.m_imp_reference_model);

        // //New connections to new cvxif scoreboard
         rvfi_agent.rvfi_core_ap.connect(dual_sb.m_rvfi_scoreboard_cvxif.m_imp_core);
         reference_model2.m_analysis_port.connect(dual_sb.m_rvfi_scoreboard_cvxif.m_imp_reference_model);
         cvxif_agent.monitor.req_ap.connect(dual_sb.m_rvfi_scoreboard_cvxif.m_imp_cvxif);

    endfunction: connect_scoreboard

endclass: uvme_cv32e20_env_dual_ref_c

class uvmt_cv32e20_model_test_dual_ref_c extends uvmt_cv32e20_firmware_test_c;

    `uvm_component_utils_begin(uvmt_cv32e20_model_test_dual_ref_c)
    `uvm_object_utils_end

    function new(string name = "uvmt_cv32e20_model_test_dual_ref", uvm_component parent = null);
        super.new(name, parent);
        `uvm_info("TEST", "This is the MODEL TEST", UVM_NONE)
    endfunction: new

    function void build_phase(uvm_phase phase);

        // set_type_override_by_type(uvme_cv32e20_env_c::get_type(),uvme_cv32e20_env_dual_ref_c::get_type());

        // // Override the first reference model with spike
        // uvmc_rvfi_reference_model::type_id::set_inst_override(uvmc_rvfi_decoder_model::get_type(), "uvm_test_top.env.reference_model");
        // // Override the second reference model with the uvmc_rvfi_decoder_model
        // uvmc_rvfi_reference_model::type_id::set_inst_override(uvmc_rvfi_spike::get_type(), "uvm_test_top.env.reference_model2");

        // super.build_phase(phase);

       set_type_override_by_type(uvme_cv32e20_env_c::get_type(),uvme_cv32e20_env_dual_ref_c::get_type());

               // // Override the first reference model with spike
        uvmc_rvfi_reference_model::type_id::set_inst_override(uvmc_rvfi_decoder_model::get_type(), "uvm_test_top.env.reference_model");
        // Override the second reference model with the uvmc_rvfi_decoder_model
        uvmc_rvfi_reference_model::type_id::set_inst_override(uvmc_rvfi_spike::get_type(), "uvm_test_top.env.reference_model2");


//   env_cfg.cvxif_cfg.enabled_cvxif                = 1;
// env_cfg.cvxif_cfg.issue_ready_mode          = UVMA_CVXIF_ISSUE_READY_RANDOMIZED;
// env_cfg.cvxif_cfg.compressed_ready_mode     = UVMA_CVXIF_COMPRESSED_READY_RANDOMIZED;
//   env_cfg.cvxif_cfg.hold_issue_ready             = 1;
//   env_cfg.cvxif_cfg.hold_issue_not_ready         = 0;
//   env_cfg.cvxif_cfg.hold_compressed_ready        = 1;
//   env_cfg.cvxif_cfg.hold_compressed_not_ready    = 0;
//   env_cfg.cvxif_cfg.zero_delay_mode              = 1;
//   env_cfg.cvxif_cfg.instr_delayed                = 0;
//   env_cfg.cvxif_cfg.ordering_mode                = UVMA_CVXIF_ORDERING_MODE_IN_ORDER;
//   env_cfg.cvxif_cfg.rand_mode(0);

   super.build_phase(phase);

   uvm_factory::get().print();
   uvm_root::get().print_topology();

    endfunction: build_phase

endclass: uvmt_cv32e20_model_test_dual_ref_c

`endif  // __UVMT_CV32E20_MODEL_TEST_SV__
