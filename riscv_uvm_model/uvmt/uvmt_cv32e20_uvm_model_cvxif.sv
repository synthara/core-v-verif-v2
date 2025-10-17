`ifndef __UVMT_CV32E20_UVM_MODEL_CVXIF_SV__
`define __UVMT_CV32E20_UVM_MODEL_CVXIF_SV__

import uvma_cvxif_pkg::*;
class uvme_cv32e20_sb_with_cvxif_c extends uvme_cv32e20_sb_c;

    uvmc_cvxif_scoreboard_c m_cvxif_scoreboard;

    `uvm_component_utils_begin(uvme_cv32e20_sb_with_cvxif_c)
        `uvm_field_object(cfg, UVM_DEFAULT)
        `uvm_field_object(cntxt, UVM_DEFAULT)
    `uvm_component_utils_end

    function new(string name = "uvme_cv32e20_sb_with_cvxif_c", uvm_component parent = null);

        super.new(name, parent);

    endfunction: new

    function void create_sbs();
        super.create_sbs();

        m_cvxif_scoreboard = uvmc_cvxif_scoreboard_c::type_id::create("m_cvxif_scoreboard", this);

    endfunction: create_sbs

endclass: uvme_cv32e20_sb_with_cvxif_c

class uvme_cv32e20_env_with_cvxif_c extends uvme_cv32e20_env_c;

    uvme_cv32e20_sb_with_cvxif_c dual_sb;
    uvma_cvxif_agent_c       cvxif_agent;
    uvma_cvxif_cfg_c         cvxif_cfg;

    function new(string name = "uvme_cv32e20_env_with_cvxif", uvm_component parent = null);
        super.new(name, parent);

        set_type_override_by_type(uvme_cv32e20_sb_c::get_type(), uvme_cv32e20_sb_with_cvxif_c#()::get_type());

    endfunction: new

    `uvm_component_utils_begin(uvme_cv32e20_env_with_cvxif_c)
        `uvm_field_object(cfg, UVM_DEFAULT)
        `uvm_field_object(cntxt, UVM_DEFAULT)
    `uvm_component_utils_end

    function void assign_cfg();

        super.assign_cfg();

        uvm_config_db#(uvma_cvxif_cfg_c) ::set(this, "cvxif_agent", "cvxif_cfg", cvxif_cfg);

        if (cfg.scoreboard_enabled) begin
            uvm_config_db#(uvma_core_cntrl_cfg_c)::set(this, "*m_cvxif_scoreboard", "cfg", cfg);
        end

    endfunction: assign_cfg

    function void create_agents();

        super.create_agents();
        
        cvxif_agent = uvma_cvxif_agent_c ::type_id::create("cvxif_agent", this);

    endfunction: create_agents

    function void create_env_components();

        super.create_env_components();

    endfunction: create_env_components

    function void connect_scoreboard();

        super.connect_scoreboard();

        // Cast the sb to dual_sb so that the m_rvfi_scoreboard2 is visible
        // m_rvfi_scoreboard2 is not present in the base class but in the extended class
        $cast(dual_sb, sb);

        cvxif_agent.monitor.resp_ap.connect(dual_sb.m_cvxif_scoreboard.m_imp_cvxif_resp_rtl);
        reference_model.m_ap_cvxif_resp.connect(dual_sb.m_cvxif_scoreboard.m_imp_cvxif_resp_ref_model);
        cvxif_agent.monitor.req_ap.connect(dual_sb.m_cvxif_scoreboard.m_imp_cvxif_req_rtl);
        reference_model.m_ap_cvxif_req.connect(dual_sb.m_cvxif_scoreboard.m_imp_cvxif_req_ref_model);

    
    endfunction: connect_scoreboard

endclass: uvme_cv32e20_env_with_cvxif_c

class uvmt_cv32e20_model_test_with_cvxif_c extends uvmt_cv32e20_firmware_test_c;

    `uvm_component_utils_begin(uvmt_cv32e20_model_test_with_cvxif_c)
    `uvm_object_utils_end

    function new(string name = "uvmt_cv32e20_model_test_with_cvxif", uvm_component parent = null);
        super.new(name, parent);
        `uvm_info("TEST", "This is the MODEL TEST with CVXIF", UVM_NONE)
    endfunction: new

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        `uvm_info("model_test", "Overriding Reference Model with UVM model", UVM_NONE)
        set_type_override_by_type(uvmc_rvfi_reference_model#()::get_type(), uvmc_rvfi_decoder_model#()::get_type());

    endfunction: build_phase

endclass: uvmt_cv32e20_model_test_with_cvxif_c

`endif // __UVMT_CV32E20_UVM_MODEL_CVXIF_SV__