`ifndef __UVMT_CV32E20_UVM_MODEL_RVFI_SV__
`define __UVMT_CV32E20_UVM_MODEL_RVFI_SV__

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

    endfunction: create_sbs

endclass: uvme_cv32e20_sb_dual_ref_c

class uvme_cv32e20_env_dual_ref_c extends uvme_cv32e20_env_c;

    uvmc_rvfi_reference_model reference_model2;

    uvme_cv32e20_sb_dual_ref_c dual_sb;

    function new(string name = "uvme_cv32e20_env_dual_ref", uvm_component parent = null);
        super.new(name, parent);

        set_type_override_by_type(uvme_cv32e20_sb_c::get_type(), uvme_cv32e20_sb_dual_ref_c#()::get_type());

    endfunction: new

    `uvm_component_utils_begin(uvme_cv32e20_env_dual_ref_c)
        `uvm_field_object(cfg, UVM_DEFAULT)
        `uvm_field_object(cntxt, UVM_DEFAULT)
    `uvm_component_utils_end

    function void assign_cfg();

        super.assign_cfg();

        if (cfg.scoreboard_enabled) begin
            uvm_config_db#(uvma_core_cntrl_cfg_c)::set(this, "reference_model2", "cfg", cfg);
            uvm_config_db#(uvma_core_cntrl_cfg_c)::set(this, "*m_rvfi_scoreboard2", "cfg", cfg);
        end

    endfunction: assign_cfg

    function void create_env_components();

        super.create_env_components();

        if (cfg.scoreboard_enabled) begin
            reference_model2 = uvmc_rvfi_reference_model#(ILEN, uvme_cv32e20_pkg::XLEN)::type_id::create("reference_model2", this);
        end

    endfunction: create_env_components

    function void connect_scoreboard();

        super.connect_scoreboard();

        // Cast the sb to dual_sb so that the m_rvfi_scoreboard2 is visible
        // m_rvfi_scoreboard2 is not present in the base class but in the extended class
        $cast(dual_sb, sb);

        rvfi_agent.rvfi_core_ap.connect(dual_sb.m_rvfi_scoreboard2.m_imp_core);
        rvfi_agent.rvfi_core_ap.connect(reference_model2.m_analysis_imp);
        reference_model2.m_analysis_port.connect(dual_sb.m_rvfi_scoreboard2.m_imp_reference_model);

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
        super.build_phase(phase);

        // Override the first reference model with spike
        uvmc_rvfi_reference_model::type_id::set_inst_override(uvmc_rvfi_decoder_model::get_type(), "uvm_test_top.env.reference_model");
        // Override the second reference model with the uvmc_rvfi_decoder_model
        uvmc_rvfi_reference_model::type_id::set_inst_override(uvmc_rvfi_spike::get_type(), "uvm_test_top.env.reference_model2");

    endfunction: build_phase

endclass: uvmt_cv32e20_model_test_dual_ref_c

`endif  // __UVMT_CV32E20_MODEL_TEST_SV__
