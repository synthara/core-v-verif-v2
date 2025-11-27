rvfi_block = """
{indent}rvfi_instr_seq_item.order     = order++;
{indent}rvfi_instr_seq_item.insn      = instr;
{indent}rvfi_instr_seq_item.rs1_addr  = rs1;
{indent}rvfi_instr_seq_item.rs1_rdata = reg_rs1_prev;
{indent}rvfi_instr_seq_item.rs2_addr  = rs2;
{indent}rvfi_instr_seq_item.rs2_rdata = reg_rs2_prev;
{indent}rvfi_instr_seq_item.rd1_addr  = rd;
{indent}rvfi_instr_seq_item.rd1_wdata = reg_file[rd];
{indent}rvfi_instr_seq_item.pc_rdata  = pc_before;
{indent}rvfi_instr_seq_item.pc_wdata  = pc;
"""

cvx_block = """
{indent}if (is_cv_instr) begin
{indent}{INDENT_ONE}cvx_instr_req_item.issue_req.instr = instr;
{indent}{INDENT_ONE}cvx_instr_req_item.register.rs[0] = reg_rs1_prev;
{indent}{INDENT_ONE}cvx_instr_req_item.register.rs[1] = reg_rs2_prev;
{indent}{INDENT_ONE}cvx_instr_req_item.register.rs[2] = reg_rs3_prev;
{indent}{INDENT_ONE}cvx_instr_req_item.register.rs_valid = 3'b111;
{indent}{INDENT_ONE}cvx_instr_req_item.issue_valid = 1'b1;
{indent}{INDENT_ONE}cvx_instr_req_item.commit_valid = 1'b1;
{indent}{INDENT_ONE}cvx_instr_resp_item.issue_resp.accept = 1'b1;
{indent}{INDENT_ONE}cvx_instr_resp_item.result.rd  = rd;
{indent}{INDENT_ONE}cvx_instr_resp_item.result.data  = reg_file[rd];
{indent}{INDENT_ONE}cvx_instr_resp_item.result_valid = 1'b1;
{indent}{INDENT_ONE}cvx_instr_resp_item.result.we = 1'b1;
{indent}{INDENT_ONE}m_ap_cvxif_resp.write(cvx_instr_resp_item);
{indent}{INDENT_ONE}m_ap_cvxif_req.write(cvx_instr_req_item);
{indent}end
"""

rvfi_seq_item_def = """
{indent}uvma_rvfi_instr_seq_item_c#({ilen}, {xlen}) rvfi_instr_seq_item;
"""

cvx_seq_item_def = """
{indent}uvma_cvxif_resp_item_c cvx_instr_resp_item;
{indent}uvma_cvxif_req_item_c cvx_instr_req_item;
"""

rvfi_seq_item_assign = """
{indent}rvfi_instr_seq_item = uvma_rvfi_instr_seq_item_c#({ilen},{xlen})::type_id::create("rvfi_instr_seq_item", this);
"""

cvx_seq_item_assign = """
{indent}cvx_instr_resp_item = uvma_cvxif_resp_item_c::type_id::create("cvx_instr_resp_item", this);
{indent}cvx_instr_req_item = uvma_cvxif_req_item_c::type_id::create("cvx_instr_req_item", this);
"""

# Class template to be formatted
template_content = """
`ifndef __{class_name}_SV__
`define __{class_name}_SV__

import uvmc_rvfi_decoder_pkg::*;
import uvma_rvfi_pkg::*;

class {class_name} extends {main_class};

    string {path_name} = "";
    int mem[int];
    int incr;
    int order = 0;

    virtual uvma_clknrst_if clknrst_vif;
    virtual uvma_interrupt_if interrupt_vif;
    uvma_rvfi_mode mode = 3;

    {fields_variables}

    // Additional regs
    {additional_regs}

    {seq_item_def}
    `uvm_component_utils_begin({class_name})
    `uvm_component_utils_end

    function new(string name="{class_name}", uvm_component parent={parent});

        super.new(name, parent);

        `uvm_info("[{class_name}]", $sformatf("[%0t]Creating {class_name} instance: %s", $time, name), {uvm_verbosity});

	    if ($value$plusargs("firmware=%s", {path_name})) begin
            `uvm_info("[{class_name}]", $sformatf("Firmware file: %s", {path_name}), {uvm_verbosity});
        end else begin
            $fatal("No +firmware argument provided!");
    	end

        $readmemh({path_name}, mem);

        csr_reg_file[12'hF11] = 32'h00000602; // mvendorid
        csr_reg_file[12'h301] = 32'h40101104; // misa (RV32IMCU)
        csr_reg_file[12'hF12] = 32'h00000023; // marchid
        csr_reg_file[12'hF13] = 32'h00000000; // mimpid
        csr_reg_file[12'h300] = 32'h00001800; // mstatus
        csr_reg_file[12'h344] = 32'h00000000; // mip

    endfunction : new

    function void build_phase(uvm_phase phase);
        st_core_cntrl_cfg st;

        super.build_phase(phase);

        st = cfg.to_struct();

        if (st.boot_addr_valid) begin
            pc = st.boot_addr;
            `uvm_info("BOOT_ADDR", $sformatf("Boot_addr: %0h", st.boot_addr), UVM_MEDIUM)
        end else begin
            `uvm_fatal("BOOT_ADDR not valid, using default value", UVM_MEDIUM)
        end
        if (!uvm_config_db#(virtual uvma_interrupt_if)::get(
            null, "*.env", "intr_vif", interrupt_vif)) begin
            `uvm_fatal("NOINT", "Cannot get interrupt_vif from config_db")
        end

        {constructor_code}
    endfunction : build_phase

    {step_code}
    {run_phase_code}

    function uvma_rvfi_instr_seq_item_c#(ILEN,XLEN) decode_opcode(bit[{instr_width}-1:0] instr);

        {seq_item_assign}

        rvfi_instr_seq_item.mode = mode;

        
        take_nmi         = interrupt_vif.irq[0];         // NMI ignora mstatus/mie
        mie_global       = csr_reg_file[12'h300][3];      // mstatus.MIE

        pend    = csr_reg_file[12'h344] & csr_reg_file[12'h304];

        incr = 4;

        csr_reg_file[12'h344] = (csr_reg_file[12'h344] & ~MIP_MASK)
                | (interrupt_vif.irq & MIP_MASK);


        is_cv_instr = 1'b0;

        rs1 = 5'b0;
        rs2 = 5'b0;
        rd  = 5'b0;

        
        csr_reg_file[12'h344][3]  = interrupt_vif.irq[3];    // MSIP
        csr_reg_file[12'h344][7]  = interrupt_vif.irq[7];    // MTIP
        csr_reg_file[12'h344][11] = interrupt_vif.irq[11];   // MEIP
        for (int i = 16; i <= 30; i++) begin
            csr_reg_file[12'h344][i] = interrupt_vif.irq[i];   // fast[14:0]
        end



    if (trap_armed) begin
        base  = csr_reg_file[12'h305] & 32'hFFFF_FFFC;

        csr_reg_file[12'h341]        = pc;                               // mepc = next PC
        csr_reg_file[12'h342]        = {{1'b1, trap_cause_latched[30:0]}}; // mcause[31]=1
        csr_reg_file[12'h343]        = '0;                               // mtval=0
        csr_reg_file[12'h300][7]     = csr_reg_file[12'h300][3];         // MPIE <- MIE
        csr_reg_file[12'h300][3]     = 1'b0;                             // MIE  <- 0
        csr_reg_file[12'h300][12:11] = 2'b11;                            // MPP  <- M

        pc = base + (trap_cause_latched << 2); // vectored per gli IRQ
        instr = {{mem[pc+3][7:0], mem[pc+2][7:0], mem[pc+1][7:0], mem[pc][7:0]}};
        trap_armed = 1'b0;
    end

            pc_before = pc;



        //pend_now = csr_reg_file[12'h344] & csr_reg_file[12'h304];

        // PATCH #3: detect & take interrupt (vectored), poi refetch al vettore



//if (interrupt_vif.irq[31]) begin
  //trap_armed         = 1'b1;
  //trap_cause_latched = 31;     // NMI
//end
//else if (!trap_armed && mie_global) begin
  //int c = -1;
  //// priorità fast: ID più basso prima
  //for (int i = 16; i <= 31; i++) if (pend[i]) begin c = i; break; end
  //if (c == -1 && pend[11]) c = 11; // MEIP
  //else if (c == -1 && pend[7])  c = 7;  // MTIP
  //else if (c == -1 && pend[3])  c = 3;  // MSIP

  //if (c != -1) begin
    //trap_armed         = 1'b1;
    //trap_cause_latched = c;
  //end
//end

//if (cause != -1) begin
  //logic [31:0] mtvec = csr_reg_file[12'h305];
  //logic [31:0] base  = mtvec & 32'hFFFF_FFFC;        // BASE (mode in [1:0])

  // Salva CSRs d’ingresso trap
  //csr_reg_file[12'h341]        = pc_before;          // mepc
  //csr_reg_file[12'h342]        = {{1'b1, cause[30:0]}};// mcause[31]=1 (interrupt)
  //csr_reg_file[12'h343]        = '0;                 // mtval=0

  // mstatus: MPIE<-MIE; MIE<-0; MPP<-M
  //csr_reg_file[12'h300][7]     = csr_reg_file[12'h300][3];
  //csr_reg_file[12'h300][3]     = 1'b0;
  //csr_reg_file[12'h300][12:11] = 2'b11;

  // Vectored: PC = BASE + 4*cause (CVE2 fa vectored per gli interrupt)
  //pc    = base + (cause << 2);
  //incr  = 0;

  // Refetch subito l'istruzione al vettore (es. JAL x0, handler)
  //instr     = {{mem[pc+3][7:0], mem[pc+2][7:0], mem[pc+1][7:0], mem[pc][7:0]}};
  //pc_before = pc;
//end

    {casez_string}

        reg_file[0] = 32'b0;

        pc += incr;

        {rvfi_block}

        if (interrupt_vif.irq_ack && !interrupt_vif.irq[0]) begin
            // --- IRQ maskabile
            int c = -1;
            for (int i = 16; i <= 30; i++) if (pend[i]) begin c = i; break; end
            if (c == -1 && pend[11]) c = 11;
            else if (c == -1 && pend[7])  c = 7;
            else if (c == -1 && pend[3])  c = 3;
            if (c != -1) begin
                trap_armed         = 1'b1;
                trap_cause_latched = c;
            end
        end

        if (interrupt_vif.irq_ack) begin
            if (interrupt_vif.irq[0]) begin
                base = csr_reg_file[12'h305] & 32'hFFFF_FFFC;

                // Save CSRs trap (NMI indipendente da MIE/mie)
                // mepc = PC of interrupted instruction
                csr_reg_file[12'h341]        = pc;
                csr_reg_file[12'h342]        = {{1'b1, 31'd32}};
                csr_reg_file[12'h343]        = '0;           // mtval = 0
                csr_reg_file[12'h300][7]     = csr_reg_file[12'h300][3]; // MPIE <- MIE
                csr_reg_file[12'h300][3]     = 1'b0;                     // MIE  <- 0
                csr_reg_file[12'h300][12:11] = 2'b11;                    // MPP  <- M

                pc         = csr_reg_file[12'h305] + 127;
                incr       = 0;                        
                instr = {{mem[pc+3][7:0], mem[pc+2][7:0], mem[pc+1][7:0], mem[pc][7:0]}};
                pc_before   = pc;                       

            end
        end

        return rvfi_instr_seq_item;

    endfunction : decode_opcode


endclass : {class_name}

`endif // __{class_name}_SV__
"""