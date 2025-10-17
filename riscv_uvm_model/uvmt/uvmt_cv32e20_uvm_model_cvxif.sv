
import uvmc_rvfi_reference_model_pkg::*;
import uvma_core_cntrl_pkg::*;
import uvme_cv32e20_pkg::*;
import uvmc_rvfi_scoreboard_pkg::*;
import uvma_cvxif_pkg::*;

class uvme_cv32e20_sb_with_cvxif_c extends uvme_cv32e20_sb_c;

    uvmc_rvfi_scoreboard_c#(ILEN, uvme_cv32e20_pkg::XLEN) m_cvxif_scoreboard;

    `uvm_component_utils_begin(uvme_cv32e20_sb_with_cvxif_c)
        `uvm_field_object(cfg, UVM_DEFAULT)
        `uvm_field_object(cntxt, UVM_DEFAULT)
    `uvm_component_utils_end

    function new(string name = "uvme_cv32e20_sb_with_cvxif_c", uvm_component parent = null);

        super.new(name, parent);

    endfunction: new

    function void create_sbs();
        super.create_sbs();

        m_cvxif_scoreboard = uvmc_cvxif_scoreboard_c#(ILEN, uvme_cv32e20_pkg::XLEN)::type_id::create("m_cvxif_scoreboard", this);

    endfunction: create_sbs

endclass: uvme_cv32e20_sb_with_cvxif_c

class uvme_cv32e20_env_with_cvxif_c extends uvme_cv32e20_env_c;

    uvme_cv32e20_sb_with_cvxif_c dual_sb;

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

        if (cfg.scoreboard_enabled) begin
            uvm_config_db#(uvma_core_cntrl_cfg_c)::set(this, "*m_cvxif_scoreboard", "cfg", cfg);
        end

    endfunction: assign_cfg

    function void create_env_components();

        super.create_env_components();

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

endclass: uvme_cv32e20_env_with_cvxif_c