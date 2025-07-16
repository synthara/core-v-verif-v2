
`ifndef __uvmc_rvfi_decoder_model_SV__
`define __uvmc_rvfi_decoder_model_SV__

import uvmc_rvfi_decoder_pkg::*;
import uvma_rvfi_pkg::*;

class uvmc_rvfi_decoder_model extends uvmc_rvfi_reference_model#(32, 32);

    string file_path = "";
    int mem[int];
    int incr;
    int order = 0;

    virtual uvma_clknrst_if clknrst_vif;
    uvma_rvfi_mode mode = 3;

    bit [4:0] rd;
    bit [4:0] rt;
    bit [4:0] rs1;
    bit [4:0] rs2;
    bit [4:0] rs3;
    bit [1:0] aqrl;
    bit aq;
    bit rl;
    bit [3:0] fm;
    bit [3:0] pred;
    bit [3:0] succ;
    bit [2:0] rm;
    bit [2:0] funct3;
    bit [1:0] funct2;
    bit [19:0] imm20;
    bit [19:0] jimm20;
    bit [11:0] imm12;
    bit [11:0] csr;
    bit [6:0] imm12hi;
    bit [6:0] bimm12hi;
    bit [4:0] imm12lo;
    bit [4:0] bimm12lo;
    bit [6:0] shamtq;
    bit [4:0] shamtw;
    bit [3:0] shamtw4;
    bit [5:0] shamtd;
    bit [1:0] bs;
    bit [3:0] rnum;
    bit [4:0] rc;
    bit [1:0] imm2;
    bit [2:0] imm3;
    bit [3:0] imm4;
    bit [4:0] imm5;
    bit [5:0] imm6;
    bit [6:0] opcode;
    bit [6:0] funct7;
    bit [4:0] vd;
    bit [4:0] vs3;
    bit [4:0] vs1;
    bit [4:0] vs2;
    bit vm;
    bit wd;
    bit [4:0] amoop;
    bit [2:0] nf;
    bit [4:0] simm5;
    bit [4:0] zimm5;
    bit [9:0] zimm10;
    bit [10:0] zimm11;
    bit zimm6hi;
    bit [4:0] zimm6lo;
    bit [7:0] c_nzuimm10;
    bit [1:0] c_uimm7lo;
    bit [2:0] c_uimm7hi;
    bit [1:0] c_uimm8lo;
    bit [2:0] c_uimm8hi;
    bit [1:0] c_uimm9lo;
    bit [2:0] c_uimm9hi;
    bit [4:0] c_nzimm6lo;
    bit c_nzimm6hi;
    bit [4:0] c_imm6lo;
    bit c_imm6hi;
    bit c_nzimm10hi;
    bit [4:0] c_nzimm10lo;
    bit c_nzimm18hi;
    bit [4:0] c_nzimm18lo;
    bit [10:0] c_imm12;
    bit [4:0] c_bimm9lo;
    bit [2:0] c_bimm9hi;
    bit [4:0] c_nzuimm5;
    bit [4:0] c_nzuimm6lo;
    bit c_nzuimm6hi;
    bit [4:0] c_uimm8splo;
    bit c_uimm8sphi;
    bit [5:0] c_uimm8sp_s;
    bit [4:0] c_uimm10splo;
    bit c_uimm10sphi;
    bit [4:0] c_uimm9splo;
    bit c_uimm9sphi;
    bit [5:0] c_uimm10sp_s;
    bit [5:0] c_uimm9sp_s;
    bit [1:0] c_uimm2;
    bit c_uimm1;
    bit [3:0] c_rlist;
    bit [1:0] c_spimm;
    bit [7:0] c_index;
    bit [2:0] rs1_p;
    bit [2:0] rs2_p;
    bit [2:0] rd_p;
    bit [4:0] rd_rs1_n0;
    bit [2:0] rd_rs1_p;
    bit [4:0] rd_rs1;
    bit [4:0] rd_n2;
    bit [4:0] rd_n0;
    bit [4:0] rs1_n0;
    bit [4:0] c_rs2_n0;
    bit [4:0] c_rs1_n0;
    bit [4:0] c_rs2;
    bit [2:0] c_sreg1;
    bit [2:0] c_sreg2;
    bit [4:0] ls3;
    bit [4:0] ls2;
    bit L;
    
    //Added by hand (not present in arg_lut.csv)
    bit [31:0] instruction;
    bit [31:0] reg_file[31:0];
    bit [31:0] csr_reg_file[4095:0];
    bit [11:0] imms;
    bit [12:0] immsb; 
    bit [31:0] immuj; 
    bit [31:0] pc; 
    bit [63:0] reg_mul;
    bit [31:0] imm12_ext;
    bit [31:0] imms_ext;
    bit [31:0] immsb_ext;
    bit [31:0] pc_before;
    bit [31:0] c_imm_ext;
    bit [31:0] addr;
    bit [31:0] reg_rs1_prev;
    bit [31:0] reg_rs2_prev;
    bit [31:0] rs2_masked;
    bit [31:0] imm6_ext;
    bit [31:0] reg_result;
    bit iteration_mx = 0;
    bit [15:0] reg_mac_mul_prov;
    bit [31:0] lpstart[1:0];
    bit [31:0] lpend[1:0];
    bit [31:0] lpcount[1:0];


    uvma_rvfi_instr_seq_item_c#(32, 32) rvfi_instr_seq_item;
    `uvm_component_utils_begin(uvmc_rvfi_decoder_model)
    `uvm_component_utils_end

    function new(string name="uvmc_rvfi_decoder_model", uvm_component parent=null);

        super.new(name, parent);

        $display("[%0t]Creating uvmc_rvfi_decoder_model instance: %s", $time, name);

	    if ($value$plusargs("firmware=%s", file_path)) begin
            $display("Firmware file: %s", file_path);
        end else begin
            $fatal("No +firmware argument provided!");
    	end

        $readmemh(file_path, mem);

        csr_reg_file[12'hF11] = 32'h00000602; // mvendorid
        csr_reg_file[12'h301] = 32'h40101104; // misa (RV32IMCU)
        csr_reg_file[12'hF12] = 32'h00000023; // marchid
        csr_reg_file[12'hF13] = 32'h00000000; // mimpid
        csr_reg_file[12'h300] = 32'h00001800; // mstatus

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
        
    endfunction : build_phase

    
    function uvma_rvfi_instr_seq_item_c#(ILEN,XLEN) step (int i, uvma_rvfi_instr_seq_item_c#(ILEN,XLEN) t);
        uvma_rvfi_instr_seq_item_c#(ILEN,XLEN) t_reference_model_prov;
        instruction = {mem[pc+3][7:0], mem[pc+2][7:0], mem[pc+1][7:0], mem[pc][7:0]};
        t_reference_model_prov = decode_opcode(instruction);
        `uvm_info(get_type_name(), "Dummy step function called", UVM_MEDIUM)
        return t_reference_model_prov;
    endfunction 

    function void write_rvfi_instr(uvma_rvfi_instr_seq_item_c#(ILEN,XLEN) t);
        uvma_rvfi_instr_seq_item_c#(ILEN,XLEN) t_reference_model = step(1, t);
        m_analysis_port.write(t_reference_model);
        `uvm_info(get_type_name(), "Dummy write_rvfi_instr function called", UVM_MEDIUM)
    endfunction : write_rvfi_instr

    

    function uvma_rvfi_instr_seq_item_c#(ILEN,XLEN) decode_opcode(bit[32-1:0] instr);

        rvfi_instr_seq_item = uvma_rvfi_instr_seq_item_c#(32,32)::type_id::create("rvfi_instr_seq_item", this);

        rvfi_instr_seq_item.mode = mode;

        incr = 4;

        pc_before = pc;

        rs1 = 5'b0;
        rs2 = 5'b0;
        rd  = 5'b0;

    
        casez (instr)

            C_JALR : begin

                `uvm_info("C_JALR", "Instruction C_JALR detected successfully", UVM_MEDIUM)
                c_rs1_n0 = instr[11:7];
                reg_rs1_prev = reg_file[c_rs1_n0];
				reg_rs2_prev = reg_file[rs2];
				instr = instr & 32'h0000FFFF;
				pc = (reg_file[c_rs1_n0]) & ~1;
				reg_file[1] = pc_before + 2;
				rs1 = c_rs1_n0;
				rd = 1;
				incr = 0;

            end

            C_ADD : begin

                `uvm_info("C_ADD", "Instruction C_ADD detected successfully", UVM_MEDIUM)
                rd_rs1_n0 = instr[11:7];
                c_rs2_n0 = instr[6:2];
                reg_rs1_prev = reg_file[rd_rs1_n0];
				reg_rs2_prev = reg_file[c_rs2_n0];
				instr = instr & 32'h0000FFFF;
				reg_file[rd_rs1_n0] = reg_file[rd_rs1_n0] + reg_file[c_rs2_n0];
				rd = rd_rs1_n0;
				rs1 = rd_rs1_n0;
				rs2 = c_rs2_n0;
				incr = 2;

            end

            ADD : begin

                `uvm_info("ADD", "Instruction ADD detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				reg_file[rd] = reg_file[rs1] + reg_file[rs2];

            end

            ADDI : begin

                `uvm_info("ADDI", "Instruction ADDI detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                imm12 = instr[31:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				imm12_ext = {{20{imm12[11]}}, imm12};
				reg_file[rd] = reg_file[rs1] + imm12_ext;

            end

            AND : begin

                `uvm_info("AND", "Instruction AND detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				reg_file[rd] = reg_file[rs1] & reg_file[rs2];

            end

            ANDI : begin

                `uvm_info("ANDI", "Instruction ANDI detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                imm12 = instr[31:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				imm12_ext = {{20{imm12[11]}}, imm12};
				reg_file[rd] = reg_file[rs1] & imm12_ext;

            end

            AUIPC : begin

                `uvm_info("AUIPC", "Instruction AUIPC detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                imm20 = instr[31:12];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				reg_file[rd] = pc + (imm20 << 12);

            end

            BEQ : begin

                `uvm_info("BEQ", "Instruction BEQ detected successfully", UVM_MEDIUM)
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                bimm12hi = instr[31:25];
                bimm12lo = instr[11:7];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				immsb = {bimm12hi[6], bimm12lo[0], bimm12hi[5:0], bimm12lo[4:1], 1'b0};
				immsb_ext = {{19{immsb[12]}}, immsb};
				if (reg_file[rs1] == reg_file[rs2]) begin
					pc = pc + immsb_ext;
					incr = 0;
				end

            end

            BGE : begin

                `uvm_info("BGE", "Instruction BGE detected successfully", UVM_MEDIUM)
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                bimm12hi = instr[31:25];
                bimm12lo = instr[11:7];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				immsb = {bimm12hi[6], bimm12lo[0], bimm12hi[5:0], bimm12lo[4:1], 1'b0};
				immsb_ext = {{19{immsb[12]}}, immsb};
				if ($signed(reg_file[rs1]) >= $signed(reg_file[rs2])) begin
					pc = pc + immsb_ext;
					incr = 0;
				end

            end

            BGEU : begin

                `uvm_info("BGEU", "Instruction BGEU detected successfully", UVM_MEDIUM)
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                bimm12hi = instr[31:25];
                bimm12lo = instr[11:7];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				immsb = {bimm12hi[6], bimm12lo[0], bimm12hi[5:0], bimm12lo[4:1], 1'b0};
				immsb_ext = {{19{immsb[12]}}, immsb};
				if (reg_file[rs1] >= reg_file[rs2]) begin
					pc = pc + immsb_ext;
					incr = 0;
				end

            end

            BLT : begin

                `uvm_info("BLT", "Instruction BLT detected successfully", UVM_MEDIUM)
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                bimm12hi = instr[31:25];
                bimm12lo = instr[11:7];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				immsb = {bimm12hi[6], bimm12lo[0], bimm12hi[5:0], bimm12lo[4:1], 1'b0};
				immsb_ext = {{19{immsb[12]}}, immsb};
				if ($signed(reg_file[rs1]) < $signed(reg_file[rs2])) begin
					pc = pc + immsb_ext;
					incr = 0;
				end

            end

            BLTU : begin

                `uvm_info("BLTU", "Instruction BLTU detected successfully", UVM_MEDIUM)
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                bimm12hi = instr[31:25];
                bimm12lo = instr[11:7];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				immsb = {bimm12hi[6], bimm12lo[0], bimm12hi[5:0], bimm12lo[4:1], 1'b0};
				immsb_ext = {{19{immsb[12]}}, immsb};
				if (reg_file[rs1] < reg_file[rs2]) begin
					pc = pc + immsb_ext;
					incr = 0;
				end

            end

            BNE : begin

                `uvm_info("BNE", "Instruction BNE detected successfully", UVM_MEDIUM)
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                bimm12hi = instr[31:25];
                bimm12lo = instr[11:7];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				immsb = {bimm12hi[6], bimm12lo[0], bimm12hi[5:0], bimm12lo[4:1], 1'b0};
				immsb_ext = {{19{immsb[12]}}, immsb};
				if (reg_file[rs1] != reg_file[rs2]) begin
					pc = pc + immsb_ext;
					incr = 0;
				end

            end

            C_ADDI : begin

                `uvm_info("C_ADDI", "Instruction C_ADDI detected successfully", UVM_MEDIUM)
                c_nzimm6lo = instr[6:2];
                c_nzimm6hi = instr[12];
                rd_rs1_n0 = instr[11:7];
                reg_rs1_prev = reg_file[rd_rs1_n0];
				reg_rs2_prev = reg_file[rs2];
				instr = instr & 32'h0000FFFF;
				c_imm_ext = {{26{c_nzimm6hi}}, c_nzimm6hi, c_nzimm6lo};
				reg_file[rd_rs1_n0] = reg_file[rd_rs1_n0] + c_imm_ext;
				rd = rd_rs1_n0;
				rs1 = rd_rs1_n0;
				incr = 2;

            end

            C_ADDI16SP : begin

                `uvm_info("C_ADDI16SP", "Instruction C_ADDI16SP detected successfully", UVM_MEDIUM)
                c_nzimm10hi = instr[12];
                c_nzimm10lo = instr[6:2];
                rs1 = 2;
				reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				instr = instr & 32'h0000FFFF;
				c_imm_ext = {{22{c_nzimm10hi}}, c_nzimm10hi, c_nzimm10lo[2:1], c_nzimm10lo[3], c_nzimm10lo[0], c_nzimm10lo[4], 4'b0000};
				reg_file[2] = reg_file[2] + c_imm_ext;
				rd = 2;
				incr = 2;

            end

            C_ADDI4SPN : begin

                `uvm_info("C_ADDI4SPN", "Instruction C_ADDI4SPN detected successfully", UVM_MEDIUM)
                c_nzuimm10 = instr[12:5];
                rd_p = instr[4:2];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				instr = instr & 32'h0000FFFF;
				c_imm_ext = {22'b0, c_nzuimm10[5:2], c_nzuimm10[7:6], c_nzuimm10[0], c_nzuimm10[1], 2'b00};
				reg_file[rd_p+8] = reg_file[2] + c_imm_ext;
				rs1 = 2;
				rd = rd_p + 8;
				incr = 2;

            end

            C_AND : begin

                `uvm_info("C_AND", "Instruction C_AND detected successfully", UVM_MEDIUM)
                rs2_p = instr[4:2];
                rd_rs1_p = instr[9:7];
                reg_rs1_prev = reg_file[rd_rs1_p+8];
				reg_rs2_prev = reg_file[rs2_p+8];
				instr = instr & 32'h0000FFFF;
				reg_file[rd_rs1_p+8] = reg_file[rd_rs1_p+8] & reg_file[rs2_p+8];
				rs1 = rd_rs1_p + 8;
				rs2 = rs2_p + 8;
				rd = rd_rs1_p + 8;
				incr = 2;

            end

            C_ANDI : begin

                `uvm_info("C_ANDI", "Instruction C_ANDI detected successfully", UVM_MEDIUM)
                c_imm6lo = instr[6:2];
                c_imm6hi = instr[12];
                rd_rs1_p = instr[9:7];
                reg_rs1_prev = reg_file[rd_rs1_p+8];
				reg_rs2_prev = reg_file[rs2];
				instr = instr & 32'h0000FFFF;
				c_imm_ext = {{26{c_imm6hi}}, c_imm6hi, c_imm6lo};
				reg_file[rd_rs1_p+8] = reg_file[rd_rs1_p+8] & c_imm_ext;
				rs1 = rd_rs1_p + 8;
				rd = rd_rs1_p + 8;
				incr = 2;

            end

            C_BEQZ : begin

                `uvm_info("C_BEQZ", "Instruction C_BEQZ detected successfully", UVM_MEDIUM)
                c_bimm9lo = instr[6:2];
                c_bimm9hi = instr[12:10];
                rs1_p = instr[9:7];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				instr = instr & 32'h0000FFFF;
				c_imm_ext = {{23{c_bimm9hi[2]}}, c_bimm9hi[2], c_bimm9lo[4:3], c_bimm9lo[0], c_bimm9hi[1:0], c_bimm9lo[2:1], 1'b0};
				rs1 = rs1_p + 8;
				if (reg_file[rs1_p+8] == 0) begin
					pc = pc + c_imm_ext;
					incr = 0;
				end else begin
					incr = 2;
				end

            end

            C_BNEZ : begin

                `uvm_info("C_BNEZ", "Instruction C_BNEZ detected successfully", UVM_MEDIUM)
                c_bimm9lo = instr[6:2];
                c_bimm9hi = instr[12:10];
                rs1_p = instr[9:7];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				instr = instr & 32'h0000FFFF;
				c_imm_ext = {{23{c_bimm9hi[2]}}, c_bimm9hi[2], c_bimm9lo[4:3], c_bimm9lo[0], c_bimm9hi[1:0], c_bimm9lo[2:1], 1'b0};
				rs1 = rs1_p + 8;
				if (reg_file[rs1_p+8] != 0) begin
					pc = pc + c_imm_ext;
					incr = 0;
				end else begin
					incr = 2;
				end

            end

            C_EBREAK : begin

                `uvm_info("C_EBREAK", "Instruction C_EBREAK detected successfully", UVM_MEDIUM)
                // c_ebreak
				instr = instr & 32'h0000FFFF;
				incr = 2;

            end

            C_J : begin

                `uvm_info("C_J", "Instruction C_J detected successfully", UVM_MEDIUM)
                c_imm12 = instr[12:2];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				instr = instr & 32'h0000FFFF;
				c_imm_ext = {{20{c_imm12[10]}}, c_imm12[10], c_imm12[6], c_imm12[8:7], c_imm12[4], c_imm12[5], c_imm12[0], c_imm12[9], c_imm12[3:1], 1'b0};
				pc = pc + c_imm_ext;
				incr = 0;

            end

            C_JAL : begin

                `uvm_info("C_JAL", "Instruction C_JAL detected successfully", UVM_MEDIUM)
                c_imm12 = instr[12:2];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				instr = instr & 32'h0000FFFF;
				c_imm_ext = {{20{c_imm12[10]}}, c_imm12[10], c_imm12[6], c_imm12[8:7], c_imm12[4], c_imm12[5], c_imm12[0], c_imm12[9], c_imm12[3:1], 1'b0};
				reg_file[1] = pc + 2;
				pc = pc + c_imm_ext;
				rd = 1;
				incr = 0;

            end

            C_JR : begin

                `uvm_info("C_JR", "Instruction C_JR detected successfully", UVM_MEDIUM)
                rs1_n0 = instr[11:7];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				instr = instr & 32'h0000FFFF;
				pc = (reg_file[rs1_n0]) & ~1;
				rs1 = rs1_n0;
				incr = 0;

            end

            C_LI : begin

                `uvm_info("C_LI", "Instruction C_LI detected successfully", UVM_MEDIUM)
                c_imm6lo = instr[6:2];
                c_imm6hi = instr[12];
                rd_n0 = instr[11:7];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				instr = instr & 32'h0000FFFF;
				c_imm_ext = {{26{c_imm6hi}}, c_imm6hi, c_imm6lo};
				reg_file[rd_n0] = c_imm_ext;
				rd = rd_n0;
				incr = 2;

            end

            C_LUI : begin

                `uvm_info("C_LUI", "Instruction C_LUI detected successfully", UVM_MEDIUM)
                c_nzimm18hi = instr[12];
                c_nzimm18lo = instr[6:2];
                rd_n2 = instr[11:7];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				instr = instr & 32'h0000FFFF;
				c_imm_ext = {{14{c_nzimm18hi}}, c_nzimm18hi, c_nzimm18lo, 12'b0};
				reg_file[rd_n2] = c_imm_ext;
				rd = rd_n2;
				incr = 2;

            end

            C_LW : begin

                `uvm_info("C_LW", "Instruction C_LW detected successfully", UVM_MEDIUM)
                c_uimm7lo = instr[6:5];
                c_uimm7hi = instr[12:10];
                rs1_p = instr[9:7];
                rd_p = instr[4:2];
                reg_rs1_prev = reg_file[rs1_p+8];
				reg_rs2_prev = reg_file[rs2];
				instr = instr & 32'h0000FFFF;
				addr = reg_file[rs1_p+8] + {c_uimm7lo[0], c_uimm7hi, c_uimm7lo[1], 2'b00};
				reg_file[rd_p+8] = {mem[addr + 3][7:0], mem[addr + 2][7:0], mem[addr + 1][7:0], mem[addr][7:0]};
				rd = rd_p + 8;
				rs1 = rs1_p + 8;
				incr = 2;

            end

            C_LWSP : begin

                `uvm_info("C_LWSP", "Instruction C_LWSP detected successfully", UVM_MEDIUM)
                c_uimm8splo = instr[6:2];
                c_uimm8sphi = instr[12];
                rd_n0 = instr[11:7];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				instr = instr & 32'h0000FFFF;
				addr = reg_file[2] + {c_uimm8splo[1:0], c_uimm8sphi, c_uimm8splo[4:2], 2'b00};
				reg_file[rd_n0] = {mem[addr + 3][7:0], mem[addr + 2][7:0], mem[addr + 1][7:0], mem[addr][7:0]};
				rs1 = 2;
				rd = rd_n0;
				incr = 2;

            end

            C_MV : begin

                `uvm_info("C_MV", "Instruction C_MV detected successfully", UVM_MEDIUM)
                rd_n0 = instr[11:7];
                c_rs2_n0 = instr[6:2];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[c_rs2_n0];
				instr = instr & 32'h0000FFFF;
				reg_file[rd_n0] = reg_file[c_rs2_n0];
				rd = rd_n0;
				rs2 = c_rs2_n0;
				incr = 2;

            end

            C_NOP : begin

                `uvm_info("C_NOP", "Instruction C_NOP detected successfully", UVM_MEDIUM)
                c_nzimm6lo = instr[6:2];
                c_nzimm6hi = instr[12];
                // c_nop
				instr = instr & 32'h0000FFFF;
				incr = 2;

            end

            C_OR : begin

                `uvm_info("C_OR", "Instruction C_OR detected successfully", UVM_MEDIUM)
                rs2_p = instr[4:2];
                rd_rs1_p = instr[9:7];
                reg_rs1_prev = reg_file[rd_rs1_p+8];
				reg_rs2_prev = reg_file[rs2_p+8];
				instr = instr & 32'h0000FFFF;
				reg_file[rd_rs1_p+8] = reg_file[rd_rs1_p+8] | reg_file[rs2_p+8];
				rs1 = rd_rs1_p + 8;
				rs2 = rs2_p + 8;
				rd = rd_rs1_p + 8;
				incr = 2;

            end

            C_SLLI : begin

                `uvm_info("C_SLLI", "Instruction C_SLLI detected successfully", UVM_MEDIUM)
                c_nzuimm6lo = instr[6:2];
                rd_rs1_n0 = instr[11:7];
                reg_rs1_prev = reg_file[rd_rs1_n0];
				reg_rs2_prev = reg_file[rs2];
				instr = instr & 32'h0000FFFF;
				reg_file[rd_rs1_n0] = reg_file[rd_rs1_n0] << c_nzuimm6lo;
				rs1 = rd_rs1_n0;
				rd = rd_rs1_n0;
				incr = 2;

            end

            C_SRAI : begin

                `uvm_info("C_SRAI", "Instruction C_SRAI detected successfully", UVM_MEDIUM)
                c_nzuimm5 = instr[6:2];
                rd_rs1_p = instr[9:7];
                reg_rs1_prev = reg_file[rd_rs1_p+8];
				reg_rs2_prev = reg_file[rs2];
				instr = instr & 32'h0000FFFF;
				reg_file[rd_rs1_p+8] = $signed(reg_file[rd_rs1_p+8]) >>> c_nzuimm5;
				rs1 = rd_rs1_p + 8;
				rd = rd_rs1_p + 8;
				incr = 2;

            end

            C_SRLI : begin

                `uvm_info("C_SRLI", "Instruction C_SRLI detected successfully", UVM_MEDIUM)
                c_nzuimm5 = instr[6:2];
                rd_rs1_p = instr[9:7];
                reg_rs1_prev = reg_file[rd_rs1_p+8];
				reg_rs2_prev = reg_file[rs2];
				instr = instr & 32'h0000FFFF;
				reg_file[rd_rs1_p+8] = reg_file[rd_rs1_p+8] >> c_nzuimm5;
				rs1 = rd_rs1_p + 8;
				rd = rd_rs1_p + 8;
				incr = 2;

            end

            C_SUB : begin

                `uvm_info("C_SUB", "Instruction C_SUB detected successfully", UVM_MEDIUM)
                rs2_p = instr[4:2];
                rd_rs1_p = instr[9:7];
                reg_rs1_prev = reg_file[rd_rs1+8];
				reg_rs2_prev = reg_file[rs2_p+8];
				instr = instr & 32'h0000FFFF;
				reg_file[rd_rs1_p+8] = reg_file[rd_rs1_p+8] - reg_file[rs2_p+8];
				rs1 = rd_rs1_p + 8;
				rs2 = rs2_p + 8;
				rd = rd_rs1_p + 8;
				incr = 2;

            end

            C_SW : begin

                `uvm_info("C_SW", "Instruction C_SW detected successfully", UVM_MEDIUM)
                c_uimm7lo = instr[6:5];
                c_uimm7hi = instr[12:10];
                rs1_p = instr[9:7];
                rs2_p = instr[4:2];
                reg_rs1_prev = reg_file[rs1_p+8];
				reg_rs2_prev = reg_file[rs2_p+8];
				instr = instr & 32'h0000FFFF;
				addr = reg_file[rs1_p+8] + {c_uimm7lo[0], c_uimm7hi, c_uimm7lo[1], 2'b00};
				mem[addr] = reg_file[rs2_p+8][7:0];
				mem[addr + 1] = reg_file[rs2_p+8][15:8];
				mem[addr + 2] = reg_file[rs2_p+8][23:16];
				mem[addr + 3] = reg_file[rs2_p+8][31:24];
				incr = 2;

            end

            C_SWSP : begin

                `uvm_info("C_SWSP", "Instruction C_SWSP detected successfully", UVM_MEDIUM)
                c_uimm8sp_s = instr[12:7];
                c_rs2 = instr[6:2];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[c_rs2];
				instr = instr & 32'h0000FFFF;
				addr = reg_file[2] + {c_uimm8sp_s[1:0], c_uimm8sp_s[5:2], 2'b00};
				mem[addr] = reg_file[c_rs2][7:0];
				mem[addr + 1] = reg_file[c_rs2][15:8];
				mem[addr + 2] = reg_file[c_rs2][23:16];
				mem[addr + 3] = reg_file[c_rs2][31:24];
				rs1 = 2;
				rs2 = c_rs2;
				incr = 2;

            end

            C_XOR : begin

                `uvm_info("C_XOR", "Instruction C_XOR detected successfully", UVM_MEDIUM)
                rs2_p = instr[4:2];
                rd_rs1_p = instr[9:7];
                reg_rs1_prev = reg_file[rd_rs1_p+8];
				reg_rs2_prev = reg_file[rs2_p+8];
				instr = instr & 32'h0000FFFF;
				reg_file[rd_rs1_p+8] = reg_file[rd_rs1_p+8] ^ reg_file[rs2_p+8];
				rs1 = rd_rs1_p+8;
				rs2 = rs2_p+8;
				rd = rd_rs1_p+8;
				incr = 2;

            end

            CSRRC : begin

                `uvm_info("CSRRC", "Instruction CSRRC detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                csr = instr[31:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				reg_file[rd] = csr_reg_file[csr];
				if (rs1 != 0) begin
					csr_reg_file[csr] = csr_reg_file[csr] & ~reg_rs1_prev;
				end

            end

            CSRRCI : begin

                `uvm_info("CSRRCI", "Instruction CSRRCI detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                csr = instr[31:20];
                zimm5 = instr[19:15];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				reg_file[rd] = csr_reg_file[csr];
				if (zimm5 != 0) begin
					csr_reg_file[csr] = csr_reg_file[csr] & ~zimm5;
				end

            end

            CSRRS : begin

                `uvm_info("CSRRS", "Instruction CSRRS detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                csr = instr[31:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				reg_file[rd] = csr_reg_file[csr];
				if (rs1 != 0) begin
					csr_reg_file[csr] = csr_reg_file[csr] | reg_rs1_prev;
				end

            end

            CSRRSI : begin

                `uvm_info("CSRRSI", "Instruction CSRRSI detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                csr = instr[31:20];
                zimm5 = instr[19:15];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				reg_file[rd] = csr_reg_file[csr];
				if (zimm5 != 0) begin
					csr_reg_file[csr] = csr_reg_file[csr] | zimm5;
				end

            end

            CSRRW : begin

                `uvm_info("CSRRW", "Instruction CSRRW detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                csr = instr[31:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				if (rd != 0) begin
					reg_file[rd] = csr_reg_file[csr];
				end
				csr_reg_file[csr] = reg_rs1_prev;

            end

            CSRRWI : begin

                `uvm_info("CSRRWI", "Instruction CSRRWI detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                csr = instr[31:20];
                zimm5 = instr[19:15];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				if (rd != 0) begin
					reg_file[rd] = csr_reg_file[csr];
				end
				csr_reg_file[csr] = zimm5;

            end

            CV_ABS : begin

                `uvm_info("CV_ABS", "Instruction CV_ABS detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				if (csr_reg_file[12'h0A0] == 2) begin
					`uvm_info("CV_ABS_H", "Instruction CV_ABS_H detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 2; i++) begin
						if ($signed(reg_file[rs1][(i*16)+:16]) < 0) begin
							reg_file[rd][(i*16)+:16] = -reg_file[rs1][(i*16)+:16];
						end else begin
							reg_file[rd][(i*16)+:16] = reg_file[rs1][(i*16)+:16];
						end
					end
				end else if (csr_reg_file[12'h0A0] == 1) begin
					`uvm_info("CV_ABS_B", "Instruction CV_ABS_B detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 4; i++) begin
						if ($signed(reg_file[rs1][(i*8)+:8]) < 0) begin
							reg_file[rd][(i*8)+:8] = -reg_file[rs1][(i*8)+:8];
						end else begin
							reg_file[rd][(i*8)+:8] = reg_file[rs1][(i*8)+:8];;
						end
					end
				end

            end

            CV_ABS_W : begin

                `uvm_info("CV_ABS_W", "Instruction CV_ABS_W detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				if ($signed(reg_file[rs1]) < 0) begin
					reg_file[rd] = -reg_file[rs1];
				end else begin
					reg_file[rd] = reg_file[rs1];
				end

            end

            CV_ADD : begin

                `uvm_info("CV_ADD", "Instruction CV_ADD detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				if (csr_reg_file[12'h0A0] == 2) begin
					`uvm_info("CV_ADD_H", "Instruction CV_ADD_H detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 2; i++) begin
						reg_file[rd][(i*16)+:16] = (reg_file[rs1][(i*16)+:16] + reg_file[rs2][(i*16)+:16]) & 16'hFFFF;
					end
				end else if (csr_reg_file[12'h0A0] == 1) begin
					`uvm_info("CV_ADD_B", "Instruction CV_ADD_B detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 4; i++) begin
						reg_file[rd][(i*8)+:8] = (reg_file[rs1][(i*8)+:8] + reg_file[rs2][(i*8)+:8]) & 8'hFF;
					end
				end

            end

            CV_ADDN : begin

                `uvm_info("CV_ADDN", "Instruction CV_ADDN detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                ls3 = instr[29:25];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				reg_file[rd] = ($signed(reg_file[rs1]) + $signed(reg_file[rs2])) >>> ls3;

            end

            CV_ADDNR : begin

                `uvm_info("CV_ADDNR", "Instruction CV_ADDNR detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				reg_file[rd] = ($signed(reg_file[rd]) + $signed(reg_file[rs1])) >>> reg_file[rs2][4:0];

            end

            CV_ADDRN : begin

                `uvm_info("CV_ADDRN", "Instruction CV_ADDRN detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                ls3 = instr[29:25];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				if (ls3 != 0) begin
					reg_file[rd] = ($signed(reg_file[rs1]) + $signed(reg_file[rs2]) + $signed(1 << (ls3-1))) >>> ls3;
				end else begin
					reg_file[rd] = ($signed(reg_file[rs1]) + $signed(reg_file[rs2])) >>> ls3;
				end

            end

            CV_ADDRNR : begin

                `uvm_info("CV_ADDRNR", "Instruction CV_ADDRNR detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				if (reg_file[rs2] != 0) begin
					reg_file[rd] = ($signed(reg_file[rd]) + $signed(reg_file[rs1]) + $signed(1 << (reg_file[rs2][4:0]-1))) >>> reg_file[rs2][4:0];
				end else begin
					reg_file[rd] = ($signed(reg_file[rd]) + $signed(reg_file[rs1])) >>> reg_file[rs2][4:0];
				end

            end

            CV_ADD_SC : begin

                `uvm_info("CV_ADD_SC", "Instruction CV_ADD_SC detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				if (csr_reg_file[12'h0A0] == 2) begin
					`uvm_info("CV_ADD_SC_H", "Instruction CV_ADD_SC_H detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 2; i++) begin
						reg_file[rd][(i*16)+:16] = (reg_file[rs1][(i*16)+:16] + reg_file[rs2][15:0]) & 16'hFFFF;
					end
				end else if (csr_reg_file[12'h0A0] == 1) begin
					`uvm_info("CV_ADD_SC_B", "Instruction CV_ADD_SC_B detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 4; i++) begin
						reg_file[rd][(i*8)+:8] = (reg_file[rs1][(i*8)+:8] + reg_file[rs2][7:0]) & 8'hFF;
					end
				end

            end

            CV_ADD_SCI : begin

                `uvm_info("CV_ADD_SCI", "Instruction CV_ADD_SCI detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                imm6 = instr[25:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				imm6_ext = {{27{imm6[4]}}, imm6[3:0], imm6[5]};
				if (csr_reg_file[12'h0A0] == 2) begin
					`uvm_info("CV_ADD_SCI_H", "Instruction CV_ADD_SCI_H detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 2; i++) begin
						reg_file[rd][(i*16)+:16] = (reg_file[rs1][(i*16)+:16] + imm6_ext[15:0]) & 16'hFFFF;
					end
				end else if (csr_reg_file[12'h0A0] == 1) begin
					`uvm_info("CV_ADD_SCI_B", "Instruction CV_ADD_SCI_B detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 4; i++) begin
						reg_file[rd][(i*8)+:8] = (reg_file[rs1][(i*8)+:8] + imm6_ext[7:0]) & 8'hFF;
					end
				end

            end

            CV_ADDUN : begin

                `uvm_info("CV_ADDUN", "Instruction CV_ADDUN detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                ls3 = instr[29:25];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				reg_file[rd] = ($unsigned(reg_file[rs1]) + $unsigned(reg_file[rs2])) >> ls3;

            end

            CV_ADDUNR : begin

                `uvm_info("CV_ADDUNR", "Instruction CV_ADDUNR detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				reg_file[rd] = ($unsigned(reg_file[rd]) + $unsigned(reg_file[rs1])) >> reg_file[rs2][4:0];

            end

            CV_ADDURN : begin

                `uvm_info("CV_ADDURN", "Instruction CV_ADDURN detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                ls3 = instr[29:25];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				if (ls3 != 0) begin
					reg_file[rd] = ($unsigned(reg_file[rs1]) + $unsigned(reg_file[rs2]) + $unsigned(1 << (ls3-1))) >> ls3;
				end else begin
					reg_file[rd] = ($unsigned(reg_file[rs1]) + $unsigned(reg_file[rs2])) >> ls3;
				end

            end

            CV_ADDURNR : begin

                `uvm_info("CV_ADDURNR", "Instruction CV_ADDURNR detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				if (reg_file[rs2] != 0) begin
					reg_file[rd] = ($unsigned(reg_file[rd]) + $unsigned(reg_file[rs1]) + $unsigned(1 << (reg_file[rs2][4:0]-1))) >> reg_file[rs2][4:0];
				end else begin
					reg_file[rd] = ($unsigned(reg_file[rd]) + $unsigned(reg_file[rs1])) >> reg_file[rs2][4:0];
				end

            end

            CV_AND : begin

                `uvm_info("CV_AND", "Instruction CV_AND detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				if (csr_reg_file[12'h0A0] == 2) begin
					`uvm_info("CV_AND_H", "Instruction CV_AND_H detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 2; i++) begin
						reg_file[rd][(i*16)+:16] = reg_file[rs1][(i*16)+:16] & reg_file[rs2][(i*16)+:16];
					end
				end else if (csr_reg_file[12'h0A0] == 1) begin
					`uvm_info("CV_AND_B", "Instruction CV_AND_B detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 4; i++) begin
						reg_file[rd][(i*8)+:8] = reg_file[rs1][(i*8)+:8] & reg_file[rs2][(i*8)+:8];
					end
				end

            end

            CV_AND_SC : begin

                `uvm_info("CV_AND_SC", "Instruction CV_AND_SC detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				if (csr_reg_file[12'h0A0] == 2) begin
					`uvm_info("CV_AND_SC_H", "Instruction CV_AND_SC_H detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 2; i++) begin
						reg_file[rd][(i*16)+:16] = reg_file[rs1][(i*16)+:16] & reg_file[rs2][15:0];
					end
				end else if (csr_reg_file[12'h0A0] == 1) begin
					`uvm_info("CV_AND_SC_B", "Instruction CV_AND_SC_B detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 4; i++) begin
						reg_file[rd][(i*8)+:8] = reg_file[rs1][(i*8)+:8] & reg_file[rs2][7:0];
					end
				end

            end

            CV_AND_SCI : begin

                `uvm_info("CV_AND_SCI", "Instruction CV_AND_SCI detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                imm6 = instr[25:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				imm6_ext = {{27{imm6[4]}}, imm6[3:0], imm6[5]};
				if (csr_reg_file[12'h0A0] == 2) begin
					`uvm_info("CV_AND_SCI_H", "Instruction CV_AND_SCI_H detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 2; i++) begin
						reg_file[rd][(i*16)+:16] = reg_file[rs1][(i*16)+:16] & imm6_ext[15:0];
					end
				end else if (csr_reg_file[12'h0A0] == 1) begin
					`uvm_info("CV_AND_SCI_B", "Instruction CV_AND_SCI_B detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 4; i++) begin
						reg_file[rd][(i*8)+:8] = reg_file[rs1][(i*8)+:8] & imm6_ext[7:0];
					end
				end

            end

            CV_AVG : begin

                `uvm_info("CV_AVG", "Instruction CV_AVG detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				if (csr_reg_file[12'h0A0] == 2) begin
					`uvm_info("CV_AVG_H", "Instruction CV_AVG_H detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 2; i++) begin
						reg_file[rd][(i*16)+:16] = $signed((reg_file[rs1][(i*16)+:16] + reg_file[rs2][(i*16)+:16]) & 16'hFFFF) >>> 1;
					end
				end else if (csr_reg_file[12'h0A0] == 1) begin
					`uvm_info("CV_AVG_B", "Instruction CV_AVG_B detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 4; i++) begin
						reg_file[rd][(i*8)+:8] = $signed((reg_file[rs1][(i*8)+:8] + reg_file[rs2][(i*8)+:8]) & 8'hFF) >>> 1;
					end
				end

            end

            CV_AVG_SC : begin

                `uvm_info("CV_AVG_SC", "Instruction CV_AVG_SC detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				if (csr_reg_file[12'h0A0] == 2) begin
					`uvm_info("CV_AVG_SC_H", "Instruction CV_AVG_SC_H detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 2; i++) begin
						reg_file[rd][(i*16)+:16] = $signed((reg_file[rs1][(i*16)+:16] + reg_file[rs2][15:0]) & 16'hFFFF) >>> 1;
					end
				end else if (csr_reg_file[12'h0A0] == 1) begin
					`uvm_info("CV_AVG_SC_B", "Instruction CV_AVG_SC_B detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 4; i++) begin
						reg_file[rd][(i*8)+:8] = $signed((reg_file[rs1][(i*8)+:8] + reg_file[rs2][7:0]) & 8'hFF) >>> 1;
					end
				end

            end

            CV_AVG_SCI : begin

                `uvm_info("CV_AVG_SCI", "Instruction CV_AVG_SCI detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                imm6 = instr[25:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				imm6_ext = {{27{imm6[4]}}, imm6[3:0], imm6[5]};
				if (csr_reg_file[12'h0A0] == 2) begin
					`uvm_info("CV_AVG_SCI_H", "Instruction CV_AVG_SCI_H detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 2; i++) begin
						reg_file[rd][(i*16)+:16] = $signed((reg_file[rs1][(i*16)+:16] + imm6_ext[15:0]) & 16'hFFFF) >>> 1;
					end
				end else if (csr_reg_file[12'h0A0] == 1) begin
					`uvm_info("CV_AVG_SCI_B", "Instruction CV_AVG_SCI_B detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 4; i++) begin
						reg_file[rd][(i*8)+:8] = $signed((reg_file[rs1][(i*8)+:8] + imm6_ext[7:0]) & 8'hFF) >>> 1;
					end
				end

            end

            CV_AVGU : begin

                `uvm_info("CV_AVGU", "Instruction CV_AVGU detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				if (csr_reg_file[12'h0A0] == 2) begin
					`uvm_info("CV_AVGU_H", "Instruction CV_AVGU_H detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 2; i++) begin
						reg_file[rd][(i*16)+:16] = ((reg_file[rs1][(i*16)+:16] + reg_file[rs2][(i*16)+:16]) & 16'hFFFF) >> 1;
					end
				end else if (csr_reg_file[12'h0A0] == 1) begin
					`uvm_info("CV_AVGU_B", "Instruction CV_AVGU_B detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 4; i++) begin
						reg_file[rd][(i*8)+:8] = ((reg_file[rs1][(i*8)+:8] + reg_file[rs2][(i*8)+:8]) & 8'hFF) >> 1;
					end
				end

            end

            CV_AVGU_SC : begin

                `uvm_info("CV_AVGU_SC", "Instruction CV_AVGU_SC detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				if (csr_reg_file[12'h0A0] == 2) begin
					`uvm_info("CV_AVGU_SC_H", "Instruction CV_AVGU_SC_H detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 2; i++) begin
						reg_file[rd][(i*16)+:16] = ((reg_file[rs1][(i*16)+:16] + reg_file[rs2][15:0]) & 16'hFFFF) >> 1;
					end
				end else if (csr_reg_file[12'h0A0] == 1) begin
					`uvm_info("CV_AVGU_SC_B", "Instruction CV_AVGU_SC_B detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 4; i++) begin
						reg_file[rd][(i*8)+:8] = ((reg_file[rs1][(i*8)+:8] + reg_file[rs2][7:0]) & 8'hFF) >> 1;
					end
				end

            end

            CV_AVGU_SCI : begin

                `uvm_info("CV_AVGU_SCI", "Instruction CV_AVGU_SCI detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                imm6 = instr[25:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				imm6_ext = {26'b0, imm6[4], imm6[3:0], imm6[5]};
				if (csr_reg_file[12'h0A0] == 2) begin
					`uvm_info("CV_AVGU_SCI_H", "Instruction CV_AVGU_SCI_H detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 2; i++) begin
						reg_file[rd][(i*16)+:16] = ((reg_file[rs1][(i*16)+:16] + imm6_ext[15:0]) & 16'hFFFF) >> 1;
					end
				end else if (csr_reg_file[12'h0A0] == 1) begin
					`uvm_info("CV_AVGU_SCI_B", "Instruction CV_AVGU_SCI_B detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 4; i++) begin
						reg_file[rd][(i*8)+:8] = ((reg_file[rs1][(i*8)+:8] + imm6_ext[7:0]) & 8'hFF) >> 1;
					end
				end

            end

            CV_CLIP : begin

                `uvm_info("CV_CLIP", "Instruction CV_CLIP detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                ls2 = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				if (ls2 != 0) begin
					if ($signed(reg_file[rs1]) <= -$signed(1 <<< (ls2 - 1))) begin
						reg_file[rd] = -$signed(1 <<< (ls2 - 1));
					end else if ($signed(reg_file[rs1]) >= $signed((1 <<< (ls2 - 1)) - 1)) begin
						reg_file[rd] = $signed((1 <<< (ls2 - 1)) - 1);
					end else begin
						reg_file[rd] = reg_file[rs1];
					end
				end else begin
					if ($signed(reg_file[rs1]) <= -1) begin
						reg_file[rd] = -1;
					end else if ($signed(reg_file[rs1]) >= 0) begin
						reg_file[rd] = 0;
					end else begin
						reg_file[rd] = reg_file[rs1];
					end
				end

            end

            CV_CLIPR : begin

                `uvm_info("CV_CLIPR", "Instruction CV_CLIPR detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				rs2_masked = reg_file[rs2] & 32'h7FFFFFFF;
				if ($signed(reg_file[rs1]) <= -$signed(rs2_masked + 1)) begin
					reg_file[rd] = -$signed(rs2_masked + 1);
				end else if ($signed(reg_file[rs1]) >= $signed(rs2_masked)) begin
					reg_file[rd] = $signed(rs2_masked);
				end else begin
					reg_file[rd] = reg_file[rs1];
				end

            end

            CV_CLIPU : begin

                `uvm_info("CV_CLIPU", "Instruction CV_CLIPU detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                ls2 = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				if (ls2 != 0) begin
					if ($signed(reg_file[rs1]) <= 0) begin
						reg_file[rd] = 0;
					end else if (reg_file[rs1] >= (1 <<< (ls2 - 1)) - 1) begin
						reg_file[rd] = (1 <<< (ls2 - 1)) - 1;
					end else begin
						reg_file[rd] = reg_file[rs1];
					end
				end else begin
					reg_file[rd] = 0;
				end

            end

            CV_CLIPUR : begin

                `uvm_info("CV_CLIPUR", "Instruction CV_CLIPUR detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				rs2_masked = reg_file[rs2] & 32'h7FFFFFFF;
				if ($signed(reg_file[rs1]) <= 0) begin
					reg_file[rd] = 0;
				end else if (reg_file[rs1] >= rs2_masked) begin
					reg_file[rd] = rs2_masked;
				end else begin
					reg_file[rd] = reg_file[rs1];
				end

            end

            CV_CMPEQ : begin

                `uvm_info("CV_CMPEQ", "Instruction CV_CMPEQ detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				if (csr_reg_file[12'h0A0] == 2) begin
					`uvm_info("CV_CMPEQ_H", "Instruction CV_CMPEQ_H detected successfully", UVM_MEDIUM);
					if ($signed(reg_file[rs1][31:16]) == $signed(reg_file[rs2][31:16])) begin
						reg_file[rd][31:16] = 16'hFFFF;
					end else begin
						reg_file[rd][31:16] = 16'h0000;
					end
					if ($signed(reg_file[rs1][15:0]) == $signed(reg_file[rs2][15:0])) begin
						reg_file[rd][15:0] = 16'hFFFF;
					end else begin
						reg_file[rd][15:0] = 16'h0000;
					end
				end else if (csr_reg_file[12'h0A0] == 1) begin
					`uvm_info("CV_CMPEQ_B", "Instruction CV_CMPEQ_B detected successfully", UVM_MEDIUM);
					if ($signed(reg_file[rs1][31:24]) == $signed(reg_file[rs2][31:24])) begin
						reg_file[rd][31:24] = 8'hFF;
					end else begin
						reg_file[rd][31:24] = 8'h00;
					end
					if ($signed(reg_file[rs1][23:16]) == $signed(reg_file[rs2][23:16])) begin
						reg_file[rd][23:16] = 8'hFF;
					end else begin
						reg_file[rd][23:16] = 8'h00;
					end
					if ($signed(reg_file[rs1][15:8]) == $signed(reg_file[rs2][15:8])) begin
						reg_file[rd][15:8] = 8'hFF;
					end else begin
						reg_file[rd][15:8] = 8'h00;
					end
					if ($signed(reg_file[rs1][7:0]) == $signed(reg_file[rs2][7:0])) begin
						reg_file[rd][7:0] = 8'hFF;
					end else begin
						reg_file[rd][7:0] = 8'h00;
					end
				end

            end

            CV_CMPEQ_SC : begin

                `uvm_info("CV_CMPEQ_SC", "Instruction CV_CMPEQ_SC detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				if (csr_reg_file[12'h0A0] == 2) begin
					`uvm_info("CV_CMPEQ_SC_H", "Instruction CV_CMPEQ_SC_H detected successfully", UVM_MEDIUM);
					if ($signed(reg_file[rs1][31:16]) == $signed(reg_file[rs2][15:0])) begin
						reg_file[rd][31:16] = 16'hFFFF;
					end else begin
						reg_file[rd][31:16] = 16'h0000;
					end
					if ($signed(reg_file[rs1][15:0]) == $signed(reg_file[rs2][15:0])) begin
						reg_file[rd][15:0] = 16'hFFFF;
					end else begin
						reg_file[rd][15:0] = 16'h0000;
					end
				end else if (csr_reg_file[12'h0A0] == 1) begin
					`uvm_info("CV_CMPEQ_SC_B", "Instruction CV_CMPEQ_SC_B detected successfully", UVM_MEDIUM);
					if ($signed(reg_file[rs1][31:24]) == $signed(reg_file[rs2][7:0])) begin
						reg_file[rd][31:24] = 8'hFF;
					end else begin
						reg_file[rd][31:24] = 8'h00;
					end
					if ($signed(reg_file[rs1][23:16]) == $signed(reg_file[rs2][7:0])) begin
						reg_file[rd][23:16] = 8'hFF;
					end else begin
						reg_file[rd][23:16] = 8'h00;
					end
					if ($signed(reg_file[rs1][15:8]) == $signed(reg_file[rs2][7:0])) begin
						reg_file[rd][15:8] = 8'hFF;
					end else begin
						reg_file[rd][15:8] = 8'h00;
					end
					if ($signed(reg_file[rs1][7:0]) == $signed(reg_file[rs2][7:0])) begin
						reg_file[rd][7:0] = 8'hFF;
					end else begin
						reg_file[rd][7:0] = 8'h00;
					end
				end

            end

            CV_CMPEQ_SCI : begin

                `uvm_info("CV_CMPEQ_SCI", "Instruction CV_CMPEQ_SCI detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                imm6 = instr[25:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				imm6_ext = {{27{imm6[4]}}, imm6[3:0], imm6[5]};
				if (csr_reg_file[12'h0A0] == 2) begin
					`uvm_info("CV_CMPEQ_SCI_H", "Instruction CV_CMPEQ_SCI_H detected successfully", UVM_MEDIUM);
					if ($signed(reg_file[rs1][31:16]) == $signed(imm6_ext[15:0])) begin
						reg_file[rd][31:16] = 16'hFFFF;
					end else begin
						reg_file[rd][31:16] = 16'h0000;
					end
					if ($signed(reg_file[rs1][15:0]) == $signed(imm6_ext[15:0])) begin
						reg_file[rd][15:0] = 16'hFFFF;
					end else begin
						reg_file[rd][15:0] = 16'h0000;
					end
				end else if (csr_reg_file[12'h0A0] == 1) begin
					`uvm_info("CV_CMPEQ_SCI_B", "Instruction CV_CMPEQ_SCI_B detected successfully", UVM_MEDIUM);
					if ($signed(reg_file[rs1][31:24]) == $signed(imm6_ext[7:0])) begin
						reg_file[rd][31:24] = 8'hFF;
					end else begin
						reg_file[rd][31:24] = 8'h00;
					end
					if ($signed(reg_file[rs1][23:16]) == $signed(imm6_ext[7:0])) begin
						reg_file[rd][23:16] = 8'hFF;
					end else begin
						reg_file[rd][23:16] = 8'h00;
					end
					if ($signed(reg_file[rs1][15:8]) == $signed(imm6_ext[7:0])) begin
						reg_file[rd][15:8] = 8'hFF;
					end else begin
						reg_file[rd][15:8] = 8'h00;
					end
					if ($signed(reg_file[rs1][7:0]) == $signed(imm6_ext[7:0])) begin
						reg_file[rd][7:0] = 8'hFF;
					end else begin
						reg_file[rd][7:0] = 8'h00;
					end
				end

            end

            CV_CMPGE : begin

                `uvm_info("CV_CMPGE", "Instruction CV_CMPGE detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				if (csr_reg_file[12'h0A0] == 2) begin
					`uvm_info("CV_CMPGE_H", "Instruction CV_CMPGE_H detected successfully", UVM_MEDIUM);
					if ($signed(reg_file[rs1][31:16]) >= $signed(reg_file[rs2][31:16])) begin
						reg_file[rd][31:16] = 16'hFFFF;
					end else begin
						reg_file[rd][31:16] = 16'h0000;
					end
					if ($signed(reg_file[rs1][15:0]) >= $signed(reg_file[rs2][15:0])) begin
						reg_file[rd][15:0] = 16'hFFFF;
					end else begin
						reg_file[rd][15:0] = 16'h0000;
					end
				end else if (csr_reg_file[12'h0A0] == 1) begin
					`uvm_info("CV_CMPGE_B", "Instruction CV_CMPGE_B detected successfully", UVM_MEDIUM);
					if ($signed(reg_file[rs1][31:24]) >= $signed(reg_file[rs2][31:24])) begin
						reg_file[rd][31:24] = 8'hFF;
					end else begin
						reg_file[rd][31:24] = 8'h00;
					end
					if ($signed(reg_file[rs1][23:16]) >= $signed(reg_file[rs2][23:16])) begin
						reg_file[rd][23:16] = 8'hFF;
					end else begin
						reg_file[rd][23:16] = 8'h00;
					end
					if ($signed(reg_file[rs1][15:8]) >= $signed(reg_file[rs2][15:8])) begin
						reg_file[rd][15:8] = 8'hFF;
					end else begin
						reg_file[rd][15:8] = 8'h00;
					end
					if ($signed(reg_file[rs1][7:0]) >= $signed(reg_file[rs2][7:0])) begin
						reg_file[rd][7:0] = 8'hFF;
					end else begin
						reg_file[rd][7:0] = 8'h00;
					end
				end

            end

            CV_CMPGE_SC : begin

                `uvm_info("CV_CMPGE_SC", "Instruction CV_CMPGE_SC detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				if (csr_reg_file[12'h0A0] == 2) begin
					`uvm_info("CV_CMPGE_SC_H", "Instruction CV_CMPGE_SC_H detected successfully", UVM_MEDIUM);
					if ($signed(reg_file[rs1][31:16]) >= $signed(reg_file[rs2][15:0])) begin
						reg_file[rd][31:16] = 16'hFFFF;
					end else begin
						reg_file[rd][31:16] = 16'h0000;
					end
					if ($signed(reg_file[rs1][15:0]) >= $signed(reg_file[rs2][15:0])) begin
						reg_file[rd][15:0] = 16'hFFFF;
					end else begin
						reg_file[rd][15:0] = 16'h0000;
					end
				end else if (csr_reg_file[12'h0A0] == 1) begin
					`uvm_info("CV_CMPGE_SC_B", "Instruction CV_CMPGE_SC_B detected successfully", UVM_MEDIUM);
					if ($signed(reg_file[rs1][31:24]) >= $signed(reg_file[rs2][7:0])) begin
						reg_file[rd][31:24] = 8'hFF;
					end else begin
						reg_file[rd][31:24] = 8'h00;
					end
					if ($signed(reg_file[rs1][23:16]) >= $signed(reg_file[rs2][7:0])) begin
						reg_file[rd][23:16] = 8'hFF;
					end else begin
						reg_file[rd][23:16] = 8'h00;
					end
					if ($signed(reg_file[rs1][15:8]) >= $signed(reg_file[rs2][7:0])) begin
						reg_file[rd][15:8] = 8'hFF;
					end else begin
						reg_file[rd][15:8] = 8'h00;
					end
					if ($signed(reg_file[rs1][7:0]) >= $signed(reg_file[rs2][7:0])) begin
						reg_file[rd][7:0] = 8'hFF;
					end else begin
						reg_file[rd][7:0] = 8'h00;
					end
				end

            end

            CV_CMPGE_SCI : begin

                `uvm_info("CV_CMPGE_SCI", "Instruction CV_CMPGE_SCI detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                imm6 = instr[25:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				imm6_ext = {{27{imm6[4]}}, imm6[3:0], imm6[5]};
				if (csr_reg_file[12'h0A0] == 2) begin
					`uvm_info("CV_CMPGE_SCI_H", "Instruction CV_CMPGE_SCI_H detected successfully", UVM_MEDIUM);
					if ($signed(reg_file[rs1][31:16]) >= $signed(imm6_ext[15:0])) begin
						reg_file[rd][31:16] = 16'hFFFF;
					end else begin
						reg_file[rd][31:16] = 16'h0000;
					end
					if ($signed(reg_file[rs1][15:0]) >= $signed(imm6_ext[15:0])) begin
						reg_file[rd][15:0] = 16'hFFFF;
					end else begin
						reg_file[rd][15:0] = 16'h0000;
					end
				end else if (csr_reg_file[12'h0A0] == 1) begin
					`uvm_info("CV_CMPGE_SCI_B", "Instruction CV_CMPGE_SCI_B detected successfully", UVM_MEDIUM);
					if ($signed(reg_file[rs1][31:24]) >= $signed(imm6_ext[7:0])) begin
						reg_file[rd][31:24] = 8'hFF;
					end else begin
						reg_file[rd][31:24] = 8'h00;
					end
					if ($signed(reg_file[rs1][23:16]) >= $signed(imm6_ext[7:0])) begin
						reg_file[rd][23:16] = 8'hFF;
					end else begin
						reg_file[rd][23:16] = 8'h00;
					end
					if ($signed(reg_file[rs1][15:8]) >= $signed(imm6_ext[7:0])) begin
						reg_file[rd][15:8] = 8'hFF;
					end else begin
						reg_file[rd][15:8] = 8'h00;
					end
					if ($signed(reg_file[rs1][7:0]) >= $signed(imm6_ext[7:0])) begin
						reg_file[rd][7:0] = 8'hFF;
					end else begin
						reg_file[rd][7:0] = 8'h00;
					end
				end

            end

            CV_CMPGEU : begin

                `uvm_info("CV_CMPGEU", "Instruction CV_CMPGEU detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				if (csr_reg_file[12'h0A0] == 2) begin
					`uvm_info("CV_CMPGEU_H", "Instruction CV_CMPGEU_H detected successfully", UVM_MEDIUM);
					if (reg_file[rs1][31:16] >= reg_file[rs2][31:16]) begin
						reg_file[rd][31:16] = 16'hFFFF;
					end else begin
						reg_file[rd][31:16] = 16'h0000;
					end
					if (reg_file[rs1][15:0] >= reg_file[rs2][15:0]) begin
						reg_file[rd][15:0] = 16'hFFFF;
					end else begin
						reg_file[rd][15:0] = 16'h0000;
					end
				end else if (csr_reg_file[12'h0A0] == 1) begin
					`uvm_info("CV_CMPGEU_B", "Instruction CV_CMPGEU_B detected successfully", UVM_MEDIUM);
					if (reg_file[rs1][31:24] >= reg_file[rs2][31:24]) begin
						reg_file[rd][31:24] = 8'hFF;
					end else begin
						reg_file[rd][31:24] = 8'h00;
					end
					if (reg_file[rs1][23:16] >= reg_file[rs2][23:16]) begin
						reg_file[rd][23:16] = 8'hFF;
					end else begin
						reg_file[rd][23:16] = 8'h00;
					end
					if (reg_file[rs1][15:8] >= reg_file[rs2][15:8]) begin
						reg_file[rd][15:8] = 8'hFF;
					end else begin
						reg_file[rd][15:8] = 8'h00;
					end
					if (reg_file[rs1][7:0] >= reg_file[rs2][7:0]) begin
						reg_file[rd][7:0] = 8'hFF;
					end else begin
						reg_file[rd][7:0] = 8'h00;
					end
				end

            end

            CV_CMPGEU_SC : begin

                `uvm_info("CV_CMPGEU_SC", "Instruction CV_CMPGEU_SC detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				if (csr_reg_file[12'h0A0] == 2) begin
					`uvm_info("CV_CMPGEU_SC_H", "Instruction CV_CMPGEU_SC_H detected successfully", UVM_MEDIUM);
					if (reg_file[rs1][31:16] >= reg_file[rs2][15:0]) begin
						reg_file[rd][31:16] = 16'hFFFF;
					end else begin
						reg_file[rd][31:16] = 16'h0000;
					end
					if (reg_file[rs1][15:0] >= reg_file[rs2][15:0]) begin
						reg_file[rd][15:0] = 16'hFFFF;
					end else begin
						reg_file[rd][15:0] = 16'h0000;
					end
				end else if (csr_reg_file[12'h0A0] == 1) begin
					`uvm_info("CV_CMPGEU_SC_B", "Instruction CV_CMPGEU_SC_B detected successfully", UVM_MEDIUM);
					if (reg_file[rs1][31:24] >= reg_file[rs2][7:0]) begin
						reg_file[rd][31:24] = 8'hFF;
					end else begin
						reg_file[rd][31:24] = 8'h00;
					end
					if (reg_file[rs1][23:16] >= reg_file[rs2][7:0]) begin
						reg_file[rd][23:16] = 8'hFF;
					end else begin
						reg_file[rd][23:16] = 8'h00;
					end
					if (reg_file[rs1][15:8] >= reg_file[rs2][7:0]) begin
						reg_file[rd][15:8] = 8'hFF;
					end else begin
						reg_file[rd][15:8] = 8'h00;
					end
					if (reg_file[rs1][7:0] >= reg_file[rs2][7:0]) begin
						reg_file[rd][7:0] = 8'hFF;
					end else begin
						reg_file[rd][7:0] = 8'h00;
					end
				end

            end

            CV_CMPGEU_SCI : begin

                `uvm_info("CV_CMPGEU_SCI", "Instruction CV_CMPGEU_SCI detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                imm6 = instr[25:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				imm6_ext = {{27{imm6[4]}}, imm6[3:0], imm6[5]};
				if (csr_reg_file[12'h0A0] == 2) begin
					`uvm_info("CV_CMPGEU_SCI_H", "Instruction CV_CMPGEU_SCI_H detected successfully", UVM_MEDIUM);
					if (reg_file[rs1][31:16] >= imm6_ext[15:0]) begin
						reg_file[rd][31:16] = 16'hFFFF;
					end else begin
						reg_file[rd][31:16] = 16'h0000;
					end
					if (reg_file[rs1][15:0] >= imm6_ext[15:0]) begin
						reg_file[rd][15:0] = 16'hFFFF;
					end else begin
						reg_file[rd][15:0] = 16'h0000;
					end
				end else if (csr_reg_file[12'h0A0] == 1) begin
					`uvm_info("CV_CMPGEU_SCI_B", "Instruction CV_CMPGEU_SCI_B detected successfully", UVM_MEDIUM);
					if (reg_file[rs1][31:24] >= imm6_ext[7:0]) begin
						reg_file[rd][31:24] = 8'hFF;
					end else begin
						reg_file[rd][31:24] = 8'h00;
					end
					if (reg_file[rs1][23:16] >= imm6_ext[7:0]) begin
						reg_file[rd][23:16] = 8'hFF;
					end else begin
						reg_file[rd][23:16] = 8'h00;
					end
					if (reg_file[rs1][15:8] >= imm6_ext[7:0]) begin
						reg_file[rd][15:8] = 8'hFF;
					end else begin
						reg_file[rd][15:8] = 8'h00;
					end
					if (reg_file[rs1][7:0] >= imm6_ext[7:0]) begin
						reg_file[rd][7:0] = 8'hFF;
					end else begin
						reg_file[rd][7:0] = 8'h00;
					end
				end

            end

            CV_CMPGT : begin

                `uvm_info("CV_CMPGT", "Instruction CV_CMPGT detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				if (csr_reg_file[12'h0A0] == 2) begin
					`uvm_info("CV_CMPGT_H", "Instruction CV_CMPGT_H detected successfully", UVM_MEDIUM);
					if ($signed(reg_file[rs1][31:16]) > $signed(reg_file[rs2][31:16])) begin
						reg_file[rd][31:16] = 16'hFFFF;
					end else begin
						reg_file[rd][31:16] = 16'h0000;
					end
					if ($signed(reg_file[rs1][15:0]) > $signed(reg_file[rs2][15:0])) begin
						reg_file[rd][15:0] = 16'hFFFF;
					end else begin
						reg_file[rd][15:0] = 16'h0000;
					end
				end else if (csr_reg_file[12'h0A0] == 1) begin
					`uvm_info("CV_CMPGT_B", "Instruction CV_CMPGT_B detected successfully", UVM_MEDIUM);
					if ($signed(reg_file[rs1][31:24]) > $signed(reg_file[rs2][31:24])) begin
						reg_file[rd][31:24] = 8'hFF;
					end else begin
						reg_file[rd][31:24] = 8'h00;
					end
					if ($signed(reg_file[rs1][23:16]) > $signed(reg_file[rs2][23:16])) begin
						reg_file[rd][23:16] = 8'hFF;
					end else begin
						reg_file[rd][23:16] = 8'h00;
					end
					if ($signed(reg_file[rs1][15:8]) > $signed(reg_file[rs2][15:8])) begin
						reg_file[rd][15:8] = 8'hFF;
					end else begin
						reg_file[rd][15:8] = 8'h00;
					end
					if ($signed(reg_file[rs1][7:0]) > $signed(reg_file[rs2][7:0])) begin
						reg_file[rd][7:0] = 8'hFF;
					end else begin
						reg_file[rd][7:0] = 8'h00;
					end
				end

            end

            CV_CMPGT_SC : begin

                `uvm_info("CV_CMPGT_SC", "Instruction CV_CMPGT_SC detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				if (csr_reg_file[12'h0A0] == 2) begin
					`uvm_info("CV_CMPGT_SC_H", "Instruction CV_CMPGT_SC_H detected successfully", UVM_MEDIUM);
					if ($signed(reg_file[rs1][31:16]) > $signed(reg_file[rs2][15:0])) begin
						reg_file[rd][31:16] = 16'hFFFF;
					end else begin
						reg_file[rd][31:16] = 16'h0000;
					end
					if ($signed(reg_file[rs1][15:0]) > $signed(reg_file[rs2][15:0])) begin
						reg_file[rd][15:0] = 16'hFFFF;
					end else begin
						reg_file[rd][15:0] = 16'h0000;
					end
				end else if (csr_reg_file[12'h0A0] == 1) begin
					`uvm_info("CV_CMPGT_SC_B", "Instruction CV_CMPGT_SC_B detected successfully", UVM_MEDIUM);
					if ($signed(reg_file[rs1][31:24]) > $signed(reg_file[rs2][7:0])) begin
						reg_file[rd][31:24] = 8'hFF;
					end else begin
						reg_file[rd][31:24] = 8'h00;
					end
					if ($signed(reg_file[rs1][23:16]) > $signed(reg_file[rs2][7:0])) begin
						reg_file[rd][23:16] = 8'hFF;
					end else begin
						reg_file[rd][23:16] = 8'h00;
					end
					if ($signed(reg_file[rs1][15:8]) > $signed(reg_file[rs2][7:0])) begin
						reg_file[rd][15:8] = 8'hFF;
					end else begin
						reg_file[rd][15:8] = 8'h00;
					end
					if ($signed(reg_file[rs1][7:0]) > $signed(reg_file[rs2][7:0])) begin
						reg_file[rd][7:0] = 8'hFF;
					end else begin
						reg_file[rd][7:0] = 8'h00;
					end
				end

            end

            CV_CMPGT_SCI : begin

                `uvm_info("CV_CMPGT_SCI", "Instruction CV_CMPGT_SCI detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                imm6 = instr[25:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				imm6_ext = {{27{imm6[4]}}, imm6[3:0], imm6[5]};
				if (csr_reg_file[12'h0A0] == 2) begin
					`uvm_info("CV_CMPGT_SCI_H", "Instruction CV_CMPGT_SCI_H detected successfully", UVM_MEDIUM);
					if ($signed(reg_file[rs1][31:16]) > $signed(imm6_ext[15:0])) begin
						reg_file[rd][31:16] = 16'hFFFF;
					end else begin
						reg_file[rd][31:16] = 16'h0000;
					end
					if ($signed(reg_file[rs1][15:0]) > $signed(imm6_ext[15:0])) begin
						reg_file[rd][15:0] = 16'hFFFF;
					end else begin
						reg_file[rd][15:0] = 16'h0000;
					end
				end else if (csr_reg_file[12'h0A0] == 1) begin
					`uvm_info("CV_CMPGT_SCI_B", "Instruction CV_CMPGT_SCI_B detected successfully", UVM_MEDIUM);
					if ($signed(reg_file[rs1][31:24]) > $signed(imm6_ext[7:0])) begin
						reg_file[rd][31:24] = 8'hFF;
					end else begin
						reg_file[rd][31:24] = 8'h00;
					end
					if ($signed(reg_file[rs1][23:16]) > $signed(imm6_ext[7:0])) begin
						reg_file[rd][23:16] = 8'hFF;
					end else begin
						reg_file[rd][23:16] = 8'h00;
					end
					if ($signed(reg_file[rs1][15:8]) > $signed(imm6_ext[7:0])) begin
						reg_file[rd][15:8] = 8'hFF;
					end else begin
						reg_file[rd][15:8] = 8'h00;
					end
					if ($signed(reg_file[rs1][7:0]) > $signed(imm6_ext[7:0])) begin
						reg_file[rd][7:0] = 8'hFF;
					end else begin
						reg_file[rd][7:0] = 8'h00;
					end
				end

            end

            CV_CMPGTU : begin

                `uvm_info("CV_CMPGTU", "Instruction CV_CMPGTU detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				if (csr_reg_file[12'h0A0] == 2) begin
					`uvm_info("CV_CMPGTU_H", "Instruction CV_CMPGTU_H detected successfully", UVM_MEDIUM);
					if (reg_file[rs1][31:16] > reg_file[rs2][31:16]) begin
						reg_file[rd][31:16] = 16'hFFFF;
					end else begin
						reg_file[rd][31:16] = 16'h0000;
					end
					if (reg_file[rs1][15:0] > reg_file[rs2][15:0]) begin
						reg_file[rd][15:0] = 16'hFFFF;
					end else begin
						reg_file[rd][15:0] = 16'h0000;
					end
				end else if (csr_reg_file[12'h0A0] == 1) begin
					`uvm_info("CV_CMPGTU_B", "Instruction CV_CMPGTU_B detected successfully", UVM_MEDIUM);
					if (reg_file[rs1][31:24] > reg_file[rs2][31:24]) begin
						reg_file[rd][31:24] = 8'hFF;
					end else begin
						reg_file[rd][31:24] = 8'h00;
					end
					if (reg_file[rs1][23:16] > reg_file[rs2][23:16]) begin
						reg_file[rd][23:16] = 8'hFF;
					end else begin
						reg_file[rd][23:16] = 8'h00;
					end
					if (reg_file[rs1][15:8] > reg_file[rs2][15:8]) begin
						reg_file[rd][15:8] = 8'hFF;
					end else begin
						reg_file[rd][15:8] = 8'h00;
					end
					if (reg_file[rs1][7:0] > reg_file[rs2][7:0]) begin
						reg_file[rd][7:0] = 8'hFF;
					end else begin
						reg_file[rd][7:0] = 8'h00;
					end
				end

            end

            CV_CMPGTU_SC : begin

                `uvm_info("CV_CMPGTU_SC", "Instruction CV_CMPGTU_SC detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				if (csr_reg_file[12'h0A0] == 2) begin
					`uvm_info("CV_CMPGTU_SC_H", "Instruction CV_CMPGTU_SC_H detected successfully", UVM_MEDIUM);
					if (reg_file[rs1][31:16] > reg_file[rs2][15:0]) begin
						reg_file[rd][31:16] = 16'hFFFF;
					end else begin
						reg_file[rd][31:16] = 16'h0000;
					end
					if (reg_file[rs1][15:0] > reg_file[rs2][15:0]) begin
						reg_file[rd][15:0] = 16'hFFFF;
					end else begin
						reg_file[rd][15:0] = 16'h0000;
					end
				end else if (csr_reg_file[12'h0A0] == 1) begin
					`uvm_info("CV_CMPGTU_SC_B", "Instruction CV_CMPGTU_SC_B detected successfully", UVM_MEDIUM);
					if (reg_file[rs1][31:24] > reg_file[rs2][7:0]) begin
						reg_file[rd][31:24] = 8'hFF;
					end else begin
						reg_file[rd][31:24] = 8'h00;
					end
					if (reg_file[rs1][23:16] > reg_file[rs2][7:0]) begin
						reg_file[rd][23:16] = 8'hFF;
					end else begin
						reg_file[rd][23:16] = 8'h00;
					end
					if (reg_file[rs1][15:8] > reg_file[rs2][7:0]) begin
						reg_file[rd][15:8] = 8'hFF;
					end else begin
						reg_file[rd][15:8] = 8'h00;
					end
					if (reg_file[rs1][7:0] > reg_file[rs2][7:0]) begin
						reg_file[rd][7:0] = 8'hFF;
					end else begin
						reg_file[rd][7:0] = 8'h00;
					end
				end

            end

            CV_CMPGTU_SCI : begin

                `uvm_info("CV_CMPGTU_SCI", "Instruction CV_CMPGTU_SCI detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                imm6 = instr[25:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				imm6_ext = {{27{imm6[4]}}, imm6[3:0], imm6[5]};
				if (csr_reg_file[12'h0A0] == 2) begin
					`uvm_info("CV_CMPGTU_SCI_H", "Instruction CV_CMPGTU_SCI_H detected successfully", UVM_MEDIUM);
					if (reg_file[rs1][31:16] > imm6_ext[15:0]) begin
						reg_file[rd][31:16] = 16'hFFFF;
					end else begin
						reg_file[rd][31:16] = 16'h0000;
					end
					if (reg_file[rs1][15:0] > imm6_ext[15:0]) begin
						reg_file[rd][15:0] = 16'hFFFF;
					end else begin
						reg_file[rd][15:0] = 16'h0000;
					end
				end else if (csr_reg_file[12'h0A0] == 1) begin
					`uvm_info("CV_CMPGTU_SCI_B", "Instruction CV_CMPGTU_SCI_B detected successfully", UVM_MEDIUM);
					if (reg_file[rs1][31:24] > imm6_ext[7:0]) begin
						reg_file[rd][31:24] = 8'hFF;
					end else begin
						reg_file[rd][31:24] = 8'h00;
					end
					if (reg_file[rs1][23:16] > imm6_ext[7:0]) begin
						reg_file[rd][23:16] = 8'hFF;
					end else begin
						reg_file[rd][23:16] = 8'h00;
					end
					if (reg_file[rs1][15:8] > imm6_ext[7:0]) begin
						reg_file[rd][15:8] = 8'hFF;
					end else begin
						reg_file[rd][15:8] = 8'h00;
					end
					if (reg_file[rs1][7:0] > imm6_ext[7:0]) begin
						reg_file[rd][7:0] = 8'hFF;
					end else begin
						reg_file[rd][7:0] = 8'h00;
					end
				end

            end

            CV_CMPLE : begin

                `uvm_info("CV_CMPLE", "Instruction CV_CMPLE detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				if (csr_reg_file[12'h0A0] == 2) begin
					`uvm_info("CV_CMPLE_H", "Instruction CV_CMPLE_H detected successfully", UVM_MEDIUM);
					if ($signed(reg_file[rs1][31:16]) <= $signed(reg_file[rs2][31:16])) begin
						reg_file[rd][31:16] = 16'hFFFF;
					end else begin
						reg_file[rd][31:16] = 16'h0000;
					end
					if ($signed(reg_file[rs1][15:0]) <= $signed(reg_file[rs2][15:0])) begin
						reg_file[rd][15:0] = 16'hFFFF;
					end else begin
						reg_file[rd][15:0] = 16'h0000;
					end
				end else if (csr_reg_file[12'h0A0] == 1) begin
					`uvm_info("CV_CMPLE_B", "Instruction CV_CMPLE_B detected successfully", UVM_MEDIUM);
					if ($signed(reg_file[rs1][31:24]) <= $signed(reg_file[rs2][31:24])) begin
						reg_file[rd][31:24] = 8'hFF;
					end else begin
						reg_file[rd][31:24] = 8'h00;
					end
					if ($signed(reg_file[rs1][23:16]) <= $signed(reg_file[rs2][23:16])) begin
						reg_file[rd][23:16] = 8'hFF;
					end else begin
						reg_file[rd][23:16] = 8'h00;
					end
					if ($signed(reg_file[rs1][15:8]) <= $signed(reg_file[rs2][15:8])) begin
						reg_file[rd][15:8] = 8'hFF;
					end else begin
						reg_file[rd][15:8] = 8'h00;
					end
					if ($signed(reg_file[rs1][7:0]) <= $signed(reg_file[rs2][7:0])) begin
						reg_file[rd][7:0] = 8'hFF;
					end else begin
						reg_file[rd][7:0] = 8'h00;
					end
				end

            end

            CV_CMPLE_SC : begin

                `uvm_info("CV_CMPLE_SC", "Instruction CV_CMPLE_SC detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				if (csr_reg_file[12'h0A0] == 2) begin
					`uvm_info("CV_CMPLE_SC_H", "Instruction CV_CMPLE_SC_H detected successfully", UVM_MEDIUM);
					if ($signed(reg_file[rs1][31:16]) <= $signed(reg_file[rs2][15:0])) begin
						reg_file[rd][31:16] = 16'hFFFF;
					end else begin
						reg_file[rd][31:16] = 16'h0000;
					end
					if ($signed(reg_file[rs1][15:0]) <= $signed(reg_file[rs2][15:0])) begin
						reg_file[rd][15:0] = 16'hFFFF;
					end else begin
						reg_file[rd][15:0] = 16'h0000;
					end
				end else if (csr_reg_file[12'h0A0] == 1) begin
					`uvm_info("CV_CMPLE_SC_B", "Instruction CV_CMPLE_SC_B detected successfully", UVM_MEDIUM);
					if ($signed(reg_file[rs1][31:24]) <= $signed(reg_file[rs2][7:0])) begin
						reg_file[rd][31:24] = 8'hFF;
					end else begin
						reg_file[rd][31:24] = 8'h00;
					end
					if ($signed(reg_file[rs1][23:16]) <= $signed(reg_file[rs2][7:0])) begin
						reg_file[rd][23:16] = 8'hFF;
					end else begin
						reg_file[rd][23:16] = 8'h00;
					end
					if ($signed(reg_file[rs1][15:8]) <= $signed(reg_file[rs2][7:0])) begin
						reg_file[rd][15:8] = 8'hFF;
					end else begin
						reg_file[rd][15:8] = 8'h00;
					end
					if ($signed(reg_file[rs1][7:0]) <= $signed(reg_file[rs2][7:0])) begin
						reg_file[rd][7:0] = 8'hFF;
					end else begin
						reg_file[rd][7:0] = 8'h00;
					end
				end

            end

            CV_CMPLE_SCI : begin

                `uvm_info("CV_CMPLE_SCI", "Instruction CV_CMPLE_SCI detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                imm6 = instr[25:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				imm6_ext = {{27{imm6[4]}}, imm6[3:0], imm6[5]};
				if (csr_reg_file[12'h0A0] == 2) begin
					`uvm_info("CV_CMPLE_SCI_H", "Instruction CV_CMPLE_SCI_H detected successfully", UVM_MEDIUM);
					if ($signed(reg_file[rs1][31:16]) <= $signed(imm6_ext[15:0])) begin
						reg_file[rd][31:16] = 16'hFFFF;
					end else begin
						reg_file[rd][31:16] = 16'h0000;
					end
					if ($signed(reg_file[rs1][15:0]) <= $signed(imm6_ext[15:0])) begin
						reg_file[rd][15:0] = 16'hFFFF;
					end else begin
						reg_file[rd][15:0] = 16'h0000;
					end
				end else if (csr_reg_file[12'h0A0] == 1) begin
					`uvm_info("CV_CMPLE_SCI_B", "Instruction CV_CMPLE_SCI_B detected successfully", UVM_MEDIUM);
					if ($signed(reg_file[rs1][31:24]) <= $signed(imm6_ext[7:0])) begin
						reg_file[rd][31:24] = 8'hFF;
					end else begin
						reg_file[rd][31:24] = 8'h00;
					end
					if ($signed(reg_file[rs1][23:16]) <= $signed(imm6_ext[7:0])) begin
						reg_file[rd][23:16] = 8'hFF;
					end else begin
						reg_file[rd][23:16] = 8'h00;
					end
					if ($signed(reg_file[rs1][15:8]) <= $signed(imm6_ext[7:0])) begin
						reg_file[rd][15:8] = 8'hFF;
					end else begin
						reg_file[rd][15:8] = 8'h00;
					end
					if ($signed(reg_file[rs1][7:0]) <= $signed(imm6_ext[7:0])) begin
						reg_file[rd][7:0] = 8'hFF;
					end else begin
						reg_file[rd][7:0] = 8'h00;
					end
				end

            end

            CV_CMPLEU : begin

                `uvm_info("CV_CMPLEU", "Instruction CV_CMPLEU detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				if (csr_reg_file[12'h0A0] == 2) begin
					`uvm_info("CV_CMPLEU_H", "Instruction CV_CMPLEU_H detected successfully", UVM_MEDIUM);
					if (reg_file[rs1][31:16] <= reg_file[rs2][31:16]) begin
						reg_file[rd][31:16] = 16'hFFFF;
					end else begin
						reg_file[rd][31:16] = 16'h0000;
					end
					if (reg_file[rs1][15:0] <= reg_file[rs2][15:0]) begin
						reg_file[rd][15:0] = 16'hFFFF;
					end else begin
						reg_file[rd][15:0] = 16'h0000;
					end
				end else if (csr_reg_file[12'h0A0] == 1) begin
					`uvm_info("CV_CMPLEU_B", "Instruction CV_CMPLEU_B detected successfully", UVM_MEDIUM);
					if (reg_file[rs1][31:24] <= reg_file[rs2][31:24]) begin
						reg_file[rd][31:24] = 8'hFF;
					end else begin
						reg_file[rd][31:24] = 8'h00;
					end
					if (reg_file[rs1][23:16] <= reg_file[rs2][23:16]) begin
						reg_file[rd][23:16] = 8'hFF;
					end else begin
						reg_file[rd][23:16] = 8'h00;
					end
					if (reg_file[rs1][15:8] <= reg_file[rs2][15:8]) begin
						reg_file[rd][15:8] = 8'hFF;
					end else begin
						reg_file[rd][15:8] = 8'h00;
					end
					if (reg_file[rs1][7:0] <= reg_file[rs2][7:0]) begin
						reg_file[rd][7:0] = 8'hFF;
					end else begin
						reg_file[rd][7:0] = 8'h00;
					end
				end

            end

            CV_CMPLEU_SC : begin

                `uvm_info("CV_CMPLEU_SC", "Instruction CV_CMPLEU_SC detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				if (csr_reg_file[12'h0A0] == 2) begin
					`uvm_info("CV_CMPLEU_SC_H", "Instruction CV_CMPLEU_SC_H detected successfully", UVM_MEDIUM);
					if (reg_file[rs1][31:16] <= reg_file[rs2][15:0]) begin
						reg_file[rd][31:16] = 16'hFFFF;
					end else begin
						reg_file[rd][31:16] = 16'h0000;
					end
					if (reg_file[rs1][15:0] <= reg_file[rs2][15:0]) begin
						reg_file[rd][15:0] = 16'hFFFF;
					end else begin
						reg_file[rd][15:0] = 16'h0000;
					end
				end else if (csr_reg_file[12'h0A0] == 1) begin
					`uvm_info("CV_CMPLEU_SC_B", "Instruction CV_CMPLEU_SC_B detected successfully", UVM_MEDIUM);
					if (reg_file[rs1][31:24] <= reg_file[rs2][7:0]) begin
						reg_file[rd][31:24] = 8'hFF;
					end else begin
						reg_file[rd][31:24] = 8'h00;
					end
					if (reg_file[rs1][23:16] <= reg_file[rs2][7:0]) begin
						reg_file[rd][23:16] = 8'hFF;
					end else begin
						reg_file[rd][23:16] = 8'h00;
					end
					if (reg_file[rs1][15:8] <= reg_file[rs2][7:0]) begin
						reg_file[rd][15:8] = 8'hFF;
					end else begin
						reg_file[rd][15:8] = 8'h00;
					end
					if (reg_file[rs1][7:0] <= reg_file[rs2][7:0]) begin
						reg_file[rd][7:0] = 8'hFF;
					end else begin
						reg_file[rd][7:0] = 8'h00;
					end
				end

            end

            CV_CMPLEU_SCI : begin

                `uvm_info("CV_CMPLEU_SCI", "Instruction CV_CMPLEU_SCI detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                imm6 = instr[25:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				imm6_ext = {{27{imm6[4]}}, imm6[3:0], imm6[5]};
				if (csr_reg_file[12'h0A0] == 2) begin
					`uvm_info("CV_CMPLEU_SCI_H", "Instruction CV_CMPLEU_SCI_H detected successfully", UVM_MEDIUM);
					if (reg_file[rs1][31:16] <= imm6_ext[15:0]) begin
						reg_file[rd][31:16] = 16'hFFFF;
					end else begin
						reg_file[rd][31:16] = 16'h0000;
					end
					if (reg_file[rs1][15:0] <= imm6_ext[15:0]) begin
						reg_file[rd][15:0] = 16'hFFFF;
					end else begin
						reg_file[rd][15:0] = 16'h0000;
					end
				end else if (csr_reg_file[12'h0A0] == 1) begin
					`uvm_info("CV_CMPLEU_SCI_B", "Instruction CV_CMPLEU_SCI_B detected successfully", UVM_MEDIUM);
					if (reg_file[rs1][31:24] <= imm6_ext[7:0]) begin
						reg_file[rd][31:24] = 8'hFF;
					end else begin
						reg_file[rd][31:24] = 8'h00;
					end
					if (reg_file[rs1][23:16] <= imm6_ext[7:0]) begin
						reg_file[rd][23:16] = 8'hFF;
					end else begin
						reg_file[rd][23:16] = 8'h00;
					end
					if (reg_file[rs1][15:8] <= imm6_ext[7:0]) begin
						reg_file[rd][15:8] = 8'hFF;
					end else begin
						reg_file[rd][15:8] = 8'h00;
					end
					if (reg_file[rs1][7:0] <= imm6_ext[7:0]) begin
						reg_file[rd][7:0] = 8'hFF;
					end else begin
						reg_file[rd][7:0] = 8'h00;
					end
				end

            end

            CV_CMPLT : begin

                `uvm_info("CV_CMPLT", "Instruction CV_CMPLT detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				if (csr_reg_file[12'h0A0] == 2) begin
					`uvm_info("CV_CMPLT_H", "Instruction CV_CMPLT_H detected successfully", UVM_MEDIUM);
					if ($signed(reg_file[rs1][31:16]) < $signed(reg_file[rs2][31:16])) begin
						reg_file[rd][31:16] = 16'hFFFF;
					end else begin
						reg_file[rd][31:16] = 16'h0000;
					end
					if ($signed(reg_file[rs1][15:0]) < $signed(reg_file[rs2][15:0])) begin
						reg_file[rd][15:0] = 16'hFFFF;
					end else begin
						reg_file[rd][15:0] = 16'h0000;
					end
				end else if (csr_reg_file[12'h0A0] == 1) begin
					`uvm_info("CV_CMPLT_B", "Instruction CV_CMPLT_B detected successfully", UVM_MEDIUM);
					if ($signed(reg_file[rs1][31:24]) < $signed(reg_file[rs2][31:24])) begin
						reg_file[rd][31:24] = 8'hFF;
					end else begin
						reg_file[rd][31:24] = 8'h00;
					end
					if ($signed(reg_file[rs1][23:16]) < $signed(reg_file[rs2][23:16])) begin
						reg_file[rd][23:16] = 8'hFF;
					end else begin
						reg_file[rd][23:16] = 8'h00;
					end
					if ($signed(reg_file[rs1][15:8]) < $signed(reg_file[rs2][15:8])) begin
						reg_file[rd][15:8] = 8'hFF;
					end else begin
						reg_file[rd][15:8] = 8'h00;
					end
					if ($signed(reg_file[rs1][7:0]) < $signed(reg_file[rs2][7:0])) begin
						reg_file[rd][7:0] = 8'hFF;
					end else begin
						reg_file[rd][7:0] = 8'h00;
					end
				end

            end

            CV_CMPLT_SC : begin

                `uvm_info("CV_CMPLT_SC", "Instruction CV_CMPLT_SC detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				if (csr_reg_file[12'h0A0] == 2) begin
					`uvm_info("CV_CMPLT_SC_H", "Instruction CV_CMPLT_SC_H detected successfully", UVM_MEDIUM);
					if ($signed(reg_file[rs1][31:16]) < $signed(reg_file[rs2][15:0])) begin
						reg_file[rd][31:16] = 16'hFFFF;
					end else begin
						reg_file[rd][31:16] = 16'h0000;
					end
					if ($signed(reg_file[rs1][15:0]) < $signed(reg_file[rs2][15:0])) begin
						reg_file[rd][15:0] = 16'hFFFF;
					end else begin
						reg_file[rd][15:0] = 16'h0000;
					end
				end else if (csr_reg_file[12'h0A0] == 1) begin
					`uvm_info("CV_CMPLT_SC_B", "Instruction CV_CMPLT_SC_B detected successfully", UVM_MEDIUM);
					if ($signed(reg_file[rs1][31:24]) < $signed(reg_file[rs2][7:0])) begin
						reg_file[rd][31:24] = 8'hFF;
					end else begin
						reg_file[rd][31:24] = 8'h00;
					end
					if ($signed(reg_file[rs1][23:16]) < $signed(reg_file[rs2][7:0])) begin
						reg_file[rd][23:16] = 8'hFF;
					end else begin
						reg_file[rd][23:16] = 8'h00;
					end
					if ($signed(reg_file[rs1][15:8]) < $signed(reg_file[rs2][7:0])) begin
						reg_file[rd][15:8] = 8'hFF;
					end else begin
						reg_file[rd][15:8] = 8'h00;
					end
					if ($signed(reg_file[rs1][7:0]) < $signed(reg_file[rs2][7:0])) begin
						reg_file[rd][7:0] = 8'hFF;
					end else begin
						reg_file[rd][7:0] = 8'h00;
					end
				end

            end

            CV_CMPLT_SCI : begin

                `uvm_info("CV_CMPLT_SCI", "Instruction CV_CMPLT_SCI detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                imm6 = instr[25:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				imm6_ext = {{27{imm6[4]}}, imm6[3:0], imm6[5]};
				if (csr_reg_file[12'h0A0] == 2) begin
					`uvm_info("CV_CMPLT_SCI_H", "Instruction CV_CMPLT_SCI_H detected successfully", UVM_MEDIUM);
					if ($signed(reg_file[rs1][31:16]) < $signed(imm6_ext[15:0])) begin
						reg_file[rd][31:16] = 16'hFFFF;
					end else begin
						reg_file[rd][31:16] = 16'h0000;
					end
					if ($signed(reg_file[rs1][15:0]) < $signed(imm6_ext[15:0])) begin
						reg_file[rd][15:0] = 16'hFFFF;
					end else begin
						reg_file[rd][15:0] = 16'h0000;
					end
				end else if (csr_reg_file[12'h0A0] == 1) begin
					`uvm_info("CV_CMPLT_SCI_B", "Instruction CV_CMPLT_SCI_B detected successfully", UVM_MEDIUM);
					if ($signed(reg_file[rs1][31:24]) < $signed(imm6_ext[7:0])) begin
						reg_file[rd][31:24] = 8'hFF;
					end else begin
						reg_file[rd][31:24] = 8'h00;
					end
					if ($signed(reg_file[rs1][23:16]) < $signed(imm6_ext[7:0])) begin
						reg_file[rd][23:16] = 8'hFF;
					end else begin
						reg_file[rd][23:16] = 8'h00;
					end
					if ($signed(reg_file[rs1][15:8]) < $signed(imm6_ext[7:0])) begin
						reg_file[rd][15:8] = 8'hFF;
					end else begin
						reg_file[rd][15:8] = 8'h00;
					end
					if ($signed(reg_file[rs1][7:0]) < $signed(imm6_ext[7:0])) begin
						reg_file[rd][7:0] = 8'hFF;
					end else begin
						reg_file[rd][7:0] = 8'h00;
					end
				end

            end

            CV_CMPLTU : begin

                `uvm_info("CV_CMPLTU", "Instruction CV_CMPLTU detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				if (csr_reg_file[12'h0A0] == 2) begin
					`uvm_info("CV_CMPLTU_H", "Instruction CV_CMPLTU_H detected successfully", UVM_MEDIUM);
					if (reg_file[rs1][31:16] < reg_file[rs2][31:16]) begin
						reg_file[rd][31:16] = 16'hFFFF;
					end else begin
						reg_file[rd][31:16] = 16'h0000;
					end
					if (reg_file[rs1][15:0] < reg_file[rs2][15:0]) begin
						reg_file[rd][15:0] = 16'hFFFF;
					end else begin
						reg_file[rd][15:0] = 16'h0000;
					end
				end else if (csr_reg_file[12'h0A0] == 1) begin
					`uvm_info("CV_CMPLTU_B", "Instruction CV_CMPLTU_B detected successfully", UVM_MEDIUM);
					if (reg_file[rs1][31:24] < reg_file[rs2][31:24]) begin
						reg_file[rd][31:24] = 8'hFF;
					end else begin
						reg_file[rd][31:24] = 8'h00;
					end
					if (reg_file[rs1][23:16] < reg_file[rs2][23:16]) begin
						reg_file[rd][23:16] = 8'hFF;
					end else begin
						reg_file[rd][23:16] = 8'h00;
					end
					if (reg_file[rs1][15:8] < reg_file[rs2][15:8]) begin
						reg_file[rd][15:8] = 8'hFF;
					end else begin
						reg_file[rd][15:8] = 8'h00;
					end
					if (reg_file[rs1][7:0] < reg_file[rs2][7:0]) begin
						reg_file[rd][7:0] = 8'hFF;
					end else begin
						reg_file[rd][7:0] = 8'h00;
					end
				end

            end

            CV_CMPLTU_SC : begin

                `uvm_info("CV_CMPLTU_SC", "Instruction CV_CMPLTU_SC detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				if (csr_reg_file[12'h0A0] == 2) begin
					`uvm_info("CV_CMPLTU_SC_H", "Instruction CV_CMPLTU_SC_H detected successfully", UVM_MEDIUM);
					if (reg_file[rs1][31:16] < reg_file[rs2][15:0]) begin
						reg_file[rd][31:16] = 16'hFFFF;
					end else begin
						reg_file[rd][31:16] = 16'h0000;
					end
					if (reg_file[rs1][15:0] < reg_file[rs2][15:0]) begin
						reg_file[rd][15:0] = 16'hFFFF;
					end else begin
						reg_file[rd][15:0] = 16'h0000;
					end
				end else if (csr_reg_file[12'h0A0] == 1) begin
					`uvm_info("CV_CMPLTU_SC_B", "Instruction CV_CMPLTU_SC_B detected successfully", UVM_MEDIUM);
					if (reg_file[rs1][31:24] < reg_file[rs2][7:0]) begin
						reg_file[rd][31:24] = 8'hFF;
					end else begin
						reg_file[rd][31:24] = 8'h00;
					end
					if (reg_file[rs1][23:16] < reg_file[rs2][7:0]) begin
						reg_file[rd][23:16] = 8'hFF;
					end else begin
						reg_file[rd][23:16] = 8'h00;
					end
					if (reg_file[rs1][15:8] < reg_file[rs2][7:0]) begin
						reg_file[rd][15:8] = 8'hFF;
					end else begin
						reg_file[rd][15:8] = 8'h00;
					end
					if (reg_file[rs1][7:0] < reg_file[rs2][7:0]) begin
						reg_file[rd][7:0] = 8'hFF;
					end else begin
						reg_file[rd][7:0] = 8'h00;
					end
				end

            end

            CV_CMPLTU_SCI : begin

                `uvm_info("CV_CMPLTU_SCI", "Instruction CV_CMPLTU_SCI detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                imm6 = instr[25:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				imm6_ext = {{27{imm6[4]}}, imm6[3:0], imm6[5]};
				if (csr_reg_file[12'h0A0] == 2) begin
					`uvm_info("CV_CMPLTU_SCI_H", "Instruction CV_CMPLTU_SCI_H detected successfully", UVM_MEDIUM);
					if (reg_file[rs1][31:16] < imm6_ext[15:0]) begin
						reg_file[rd][31:16] = 16'hFFFF;
					end else begin
						reg_file[rd][31:16] = 16'h0000;
					end
					if (reg_file[rs1][15:0] < imm6_ext[15:0]) begin
						reg_file[rd][15:0] = 16'hFFFF;
					end else begin
						reg_file[rd][15:0] = 16'h0000;
					end
				end else if (csr_reg_file[12'h0A0] == 1) begin
					`uvm_info("CV_CMPLTU_SCI_B", "Instruction CV_CMPLTU_SCI_B detected successfully", UVM_MEDIUM);
					if (reg_file[rs1][31:24] < imm6_ext[7:0]) begin
						reg_file[rd][31:24] = 8'hFF;
					end else begin
						reg_file[rd][31:24] = 8'h00;
					end
					if (reg_file[rs1][23:16] < imm6_ext[7:0]) begin
						reg_file[rd][23:16] = 8'hFF;
					end else begin
						reg_file[rd][23:16] = 8'h00;
					end
					if (reg_file[rs1][15:8] < imm6_ext[7:0]) begin
						reg_file[rd][15:8] = 8'hFF;
					end else begin
						reg_file[rd][15:8] = 8'h00;
					end
					if (reg_file[rs1][7:0] < imm6_ext[7:0]) begin
						reg_file[rd][7:0] = 8'hFF;
					end else begin
						reg_file[rd][7:0] = 8'h00;
					end
				end

            end

            CV_CMPNE : begin

                `uvm_info("CV_CMPNE", "Instruction CV_CMPNE detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				if (csr_reg_file[12'h0A0] == 2) begin
					`uvm_info("CV_CMPNE_H", "Instruction CV_CMPNE_H detected successfully", UVM_MEDIUM);
					if ($signed(reg_file[rs1][31:16]) != $signed(reg_file[rs2][31:16])) begin
						reg_file[rd][31:16] = 16'hFFFF;
					end else begin
						reg_file[rd][31:16] = 16'h0000;
					end
					if ($signed(reg_file[rs1][15:0]) != $signed(reg_file[rs2][15:0])) begin
						reg_file[rd][15:0] = 16'hFFFF;
					end else begin
						reg_file[rd][15:0] = 16'h0000;
					end
				end else if (csr_reg_file[12'h0A0] == 1) begin
					`uvm_info("CV_CMPNE_B", "Instruction CV_CMPNE_B detected successfully", UVM_MEDIUM);
					if ($signed(reg_file[rs1][31:24]) != $signed(reg_file[rs2][31:24])) begin
						reg_file[rd][31:24] = 8'hFF;
					end else begin
						reg_file[rd][31:24] = 8'h00;
					end
					if ($signed(reg_file[rs1][23:16]) != $signed(reg_file[rs2][23:16])) begin
						reg_file[rd][23:16] = 8'hFF;
					end else begin
						reg_file[rd][23:16] = 8'h00;
					end
					if ($signed(reg_file[rs1][15:8]) != $signed(reg_file[rs2][15:8])) begin
						reg_file[rd][15:8] = 8'hFF;
					end else begin
						reg_file[rd][15:8] = 8'h00;
					end
					if ($signed(reg_file[rs1][7:0]) != $signed(reg_file[rs2][7:0])) begin
						reg_file[rd][7:0] = 8'hFF;
					end else begin
						reg_file[rd][7:0] = 8'h00;
					end
				end

            end

            CV_CMPNE_SC : begin

                `uvm_info("CV_CMPNE_SC", "Instruction CV_CMPNE_SC detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				if (csr_reg_file[12'h0A0] == 2) begin
					`uvm_info("CV_CMPNE_SC_H", "Instruction CV_CMPNE_SC_H detected successfully", UVM_MEDIUM);
					if ($signed(reg_file[rs1][31:16]) != $signed(reg_file[rs2][15:0])) begin
						reg_file[rd][31:16] = 16'hFFFF;
					end else begin
						reg_file[rd][31:16] = 16'h0000;
					end
					if ($signed(reg_file[rs1][15:0]) != $signed(reg_file[rs2][15:0])) begin
						reg_file[rd][15:0] = 16'hFFFF;
					end else begin
						reg_file[rd][15:0] = 16'h0000;
					end
				end else if (csr_reg_file[12'h0A0] == 1) begin
					`uvm_info("CV_CMPNE_SC_B", "Instruction CV_CMPNE_SC_B detected successfully", UVM_MEDIUM);
					if ($signed(reg_file[rs1][31:24]) != $signed(reg_file[rs2][7:0])) begin
						reg_file[rd][31:24] = 8'hFF;
					end else begin
						reg_file[rd][31:24] = 8'h00;
					end
					if ($signed(reg_file[rs1][23:16]) != $signed(reg_file[rs2][7:0])) begin
						reg_file[rd][23:16] = 8'hFF;
					end else begin
						reg_file[rd][23:16] = 8'h00;
					end
					if ($signed(reg_file[rs1][15:8]) != $signed(reg_file[rs2][7:0])) begin
						reg_file[rd][15:8] = 8'hFF;
					end else begin
						reg_file[rd][15:8] = 8'h00;
					end
					if ($signed(reg_file[rs1][7:0]) != $signed(reg_file[rs2][7:0])) begin
						reg_file[rd][7:0] = 8'hFF;
					end else begin
						reg_file[rd][7:0] = 8'h00;
					end
				end

            end

            CV_CMPNE_SCI : begin

                `uvm_info("CV_CMPNE_SCI", "Instruction CV_CMPNE_SCI detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                imm6 = instr[25:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				imm6_ext = {{27{imm6[4]}}, imm6[3:0], imm6[5]};
				if (csr_reg_file[12'h0A0] == 2) begin
					`uvm_info("CV_CMPNE_SCI_H", "Instruction CV_CMPNE_SCI_H detected successfully", UVM_MEDIUM);
					if ($signed(reg_file[rs1][31:16]) != $signed(imm6_ext[15:0])) begin
						reg_file[rd][31:16] = 16'hFFFF;
					end else begin
						reg_file[rd][31:16] = 16'h0000;
					end
					if ($signed(reg_file[rs1][15:0]) != $signed(imm6_ext[15:0])) begin
						reg_file[rd][15:0] = 16'hFFFF;
					end else begin
						reg_file[rd][15:0] = 16'h0000;
					end
				end else if (csr_reg_file[12'h0A0] == 1) begin
					`uvm_info("CV_CMPNE_SCI_B", "Instruction CV_CMPNE_SCI_B detected successfully", UVM_MEDIUM);
					if ($signed(reg_file[rs1][31:24]) != $signed(imm6_ext[7:0])) begin
						reg_file[rd][31:24] = 8'hFF;
					end else begin
						reg_file[rd][31:24] = 8'h00;
					end
					if ($signed(reg_file[rs1][23:16]) != $signed(imm6_ext[7:0])) begin
						reg_file[rd][23:16] = 8'hFF;
					end else begin
						reg_file[rd][23:16] = 8'h00;
					end
					if ($signed(reg_file[rs1][15:8]) != $signed(imm6_ext[7:0])) begin
						reg_file[rd][15:8] = 8'hFF;
					end else begin
						reg_file[rd][15:8] = 8'h00;
					end
					if ($signed(reg_file[rs1][7:0]) != $signed(imm6_ext[7:0])) begin
						reg_file[rd][7:0] = 8'hFF;
					end else begin
						reg_file[rd][7:0] = 8'h00;
					end
				end

            end

            CV_DOTSP : begin

                `uvm_info("CV_DOTSP", "Instruction CV_DOTSP detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				reg_file[rd] = 0;
				if (csr_reg_file[12'h0A0] == 2) begin
					`uvm_info("CV_DOTSP_H", "Instruction CV_DOTSP_H detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 2; i++) begin
						reg_file[rd] += $signed({{16{reg_file[rs1][(i*16)+15]}}, reg_file[rs1][(i*16)+:16]}) * $signed({{16{reg_file[rs2][(i*16)+15]}}, reg_file[rs2][(i*16)+:16]});
					end
				end else if (csr_reg_file[12'h0A0] == 1) begin
					`uvm_info("CV_DOTSP_B", "Instruction CV_DOTSP_B detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 4; i++) begin
						reg_file[rd] += $signed({{24{reg_file[rs1][(i*8)+7]}}, reg_file[rs1][(i*8)+:8]}) * $signed({{24{reg_file[rs2][(i*8)+7]}}, reg_file[rs2][(i*8)+:8]});
					end
				end else if (csr_reg_file[12'h0A0] == 6) begin
					`uvm_info("CV_DOTSP_MX", "Instruction CV_DOTSP_MX detected successfully", UVM_MEDIUM);
					if (iteration_mx == 0) begin
						for (int i = 0; i < 2; i++) begin
							reg_file[rd] += $signed({{16{reg_file[rs1][(i*16)+15]}}, reg_file[rs1][(i*16)+:16]}) * $signed({{24{reg_file[rs2][(i*8)+7]}}, reg_file[rs2][(i*8)+:8]});
						end
					end else begin
						for (int i = 0; i < 2; i++) begin
							reg_file[rd] += $signed({{16{reg_file[rs1][(i*16)+15]}}, reg_file[rs1][(i*16)+:16]}) * $signed({{24{reg_file[rs2][(i*8)+7]}}, reg_file[rs2][((i+2)*8)+:8]});
						end
					end
					iteration_mx = ~iteration_mx;
				end

            end

            CV_DOTSP_SC : begin

                `uvm_info("CV_DOTSP_SC", "Instruction CV_DOTSP_SC detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				reg_file[rd] = 0;
				if (csr_reg_file[12'h0A0] == 2) begin
					`uvm_info("CV_DOTSP_SC_H", "Instruction CV_DOTSP_SC_H detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 2; i++) begin
						reg_file[rd] += $signed({{16{reg_file[rs1][(i*16)+15]}}, reg_file[rs1][(i*16)+:16]}) * $signed({{16{reg_file[rs2][15]}}, reg_file[rs2][15:0]});
					end
				end else if (csr_reg_file[12'h0A0] == 1) begin
					`uvm_info("CV_DOTSP_SC_B", "Instruction CV_DOTSP_SC_B detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 4; i++) begin
						reg_file[rd] += $signed({{24{reg_file[rs1][(i*8)+7]}}, reg_file[rs1][(i*8)+:8]}) * $signed({{24{reg_file[rs2][7]}}, reg_file[rs2][7:0]});
					end
				end else if (csr_reg_file[12'h0A0] == 6) begin
					`uvm_info("CV_DOTSP_SC_MX", "Instruction CV_DOTSP_SC_MX detected successfully", UVM_MEDIUM);
					if (iteration_mx == 0) begin
						for (int i = 0; i < 2; i++) begin
							reg_file[rd] += $signed({{16{reg_file[rs1][(i*16)+15]}}, reg_file[rs1][(i*16)+:16]}) * $signed({{24{reg_file[rs2][7]}}, reg_file[rs2][7:0]});
						end
					end else begin
						for (int i = 0; i < 2; i++) begin
							reg_file[rd] += $signed({{16{reg_file[rs1][(i*16)+15]}}, reg_file[rs1][(i*16)+:16]}) * $signed({{24{reg_file[rs2][7]}}, reg_file[rs2][7:0]});
						end
					end
					iteration_mx = ~iteration_mx;
				end

            end

            CV_DOTSP_SCI : begin

                `uvm_info("CV_DOTSP_SCI", "Instruction CV_DOTSP_SCI detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                imm6 = instr[25:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				imm6_ext = {{27{imm6[4]}}, imm6[3:0], imm6[5]};
				reg_file[rd] = 0;
				if (csr_reg_file[12'h0A0] == 2) begin
					`uvm_info("CV_DOTSP_SCI_H", "Instruction CV_DOTSP_SCI_H detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 2; i++) begin
						reg_file[rd] += $signed({{16{reg_file[rs1][(i*16)+15]}}, reg_file[rs1][(i*16)+:16]}) * $signed({{16{imm6_ext[15]}}, imm6_ext[15:0]});
					end
				end else if (csr_reg_file[12'h0A0] == 1) begin
					`uvm_info("CV_DOTSP_SCI_B", "Instruction CV_DOTSP_SCI_B detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 4; i++) begin
						reg_file[rd] += $signed({{24{reg_file[rs1][(i*8)+7]}}, reg_file[rs1][(i*8)+:8]}) * $signed({{24{imm6_ext[7]}}, imm6_ext[7:0]});
					end
				end else if (csr_reg_file[12'h0A0] == 6) begin
					`uvm_info("CV_DOTSP_SCI_MX", "Instruction CV_DOTSP_SCI_MX detected successfully", UVM_MEDIUM);
					if (iteration_mx == 0) begin
						for (int i = 0; i < 2; i++) begin
							reg_file[rd] += $signed({{16{reg_file[rs1][(i*16)+15]}}, reg_file[rs1][(i*16)+:16]}) * $signed({{24{imm6_ext[7]}}, imm6_ext[7:0]});
						end
					end else begin
						for (int i = 0; i < 2; i++) begin
							reg_file[rd] += $signed({{16{reg_file[rs1][(i*16)+15]}}, reg_file[rs1][(i*16)+:16]}) * $signed({{24{imm6_ext[7]}}, imm6_ext[7:0]});
						end
					end
					iteration_mx = ~iteration_mx;
				end

            end

            CV_DOTUP : begin

                `uvm_info("CV_DOTUP", "Instruction CV_DOTUP detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				reg_file[rd] = 0;
				if (csr_reg_file[12'h0A0] == 2) begin
					`uvm_info("CV_DOTUP_H", "Instruction CV_DOTUP_H detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 2; i++) begin
						reg_file[rd] += {{16{1'b0}}, reg_file[rs1][(i*16)+:16]} * {{16{1'b0}}, reg_file[rs2][(i*16)+:16]};
					end
				end else if (csr_reg_file[12'h0A0] == 1) begin
					`uvm_info("CV_DOTUP_B", "Instruction CV_DOTUP_B detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 4; i++) begin
						reg_file[rd] += {{24{1'b0}}, reg_file[rs1][(i*8)+:8]} * {{24{1'b0}}, reg_file[rs2][(i*8)+:8]};
					end
				end else if (csr_reg_file[12'h0A0] == 6) begin
					`uvm_info("CV_DOTUP_MX", "Instruction CV_DOTUP_MX detected successfully", UVM_MEDIUM);
					if (iteration_mx == 0) begin
						for (int i = 0; i < 2; i++) begin
							reg_file[rd] += {{16{1'b0}}, reg_file[rs1][(i*16)+:16]} * {{24{1'b0}}, reg_file[rs2][(i*8)+:8]};
						end
					end else begin
						for (int i = 0; i < 2; i++) begin
							reg_file[rd] += {{16{1'b0}}, reg_file[rs1][(i*16)+:16]} * {{24{1'b0}}, reg_file[rs2][((i+2)*8)+:8]};
						end
					end
					iteration_mx = ~iteration_mx;
				end

            end

            CV_DOTUP_SC : begin

                `uvm_info("CV_DOTUP_SC", "Instruction CV_DOTUP_SC detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				reg_file[rd] = 0;
				if (csr_reg_file[12'h0A0] == 2) begin
					`uvm_info("CV_DOTUP_SC_H", "Instruction CV_DOTUP_SC_H detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 2; i++) begin
						reg_file[rd] += {{16{1'b0}}, reg_file[rs1][(i*16)+:16]} * {{16{1'b0}}, reg_file[rs2][15:0]};
					end
				end else if (csr_reg_file[12'h0A0] == 1) begin
					`uvm_info("CV_DOTUP_SC_B", "Instruction CV_DOTUP_SC_B detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 4; i++) begin
						reg_file[rd] += {{24{1'b0}}, reg_file[rs1][(i*8)+:8]} * {{24{1'b0}}, reg_file[rs2][7:0]};
					end
				end else if (csr_reg_file[12'h0A0] == 6) begin
					`uvm_info("CV_DOTUP_SC_MX", "Instruction CV_DOTUP_SC_MX detected successfully", UVM_MEDIUM);
					if (iteration_mx == 0) begin
						for (int i = 0; i < 2; i++) begin
							reg_file[rd] += {{16{1'b0}}, reg_file[rs1][(i*16)+:16]} * {{24{1'b0}}, reg_file[rs2][7:0]};
						end
					end else begin
						for (int i = 0; i < 2; i++) begin
							reg_file[rd] += {{16{1'b0}}, reg_file[rs1][(i*16)+:16]} * {{24{1'b0}}, reg_file[rs2][7:0]};
						end
					end
					iteration_mx = ~iteration_mx;
				end

            end

            CV_DOTUP_SCI : begin

                `uvm_info("CV_DOTUP_SCI", "Instruction CV_DOTUP_SCI detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                imm6 = instr[25:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				imm6_ext = {{27{imm6[4]}}, imm6[3:0], imm6[5]};
				reg_file[rd] = 0;
				if (csr_reg_file[12'h0A0] == 2) begin
					`uvm_info("CV_DOTUP_SCI_H", "Instruction CV_DOTUP_SCI_H detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 2; i++) begin
						reg_file[rd] += {{16{1'b0}}, reg_file[rs1][(i*16)+:16]} * {{16{1'b0}}, imm6_ext[15:0]};
					end
				end else if (csr_reg_file[12'h0A0] == 1) begin
					`uvm_info("CV_DOTUP_SCI_B", "Instruction CV_DOTUP_SCI_B detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 4; i++) begin
						reg_file[rd] += {{24{1'b0}}, reg_file[rs1][(i*8)+:8]} * {{24{1'b0}}, imm6_ext[7:0]};
					end
				end else if (csr_reg_file[12'h0A0] == 6) begin
					`uvm_info("CV_DOTUP_SCI_MX", "Instruction CV_DOTUP_SCI_MX detected successfully", UVM_MEDIUM);
					if (iteration_mx == 0) begin
						for (int i = 0; i < 2; i++) begin
							reg_file[rd] += {{16{1'b0}}, reg_file[rs1][(i*16)+:16]} * {{24{1'b0}}, imm6_ext[7:0]};
						end
					end else begin
						for (int i = 0; i < 2; i++) begin
							reg_file[rd] += {{16{1'b0}}, reg_file[rs1][(i*16)+:16]} * {{24{1'b0}}, imm6_ext[7:0]};
						end
					end
					iteration_mx = ~iteration_mx;
				end

            end

            CV_DOTUSP : begin

                `uvm_info("CV_DOTUSP", "Instruction CV_DOTUSP detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				reg_file[rd] = 0;
				if (csr_reg_file[12'h0A0] == 2) begin
					`uvm_info("CV_DOTUSP_H", "Instruction CV_DOTUSP_H detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 2; i++) begin
						reg_file[rd] += {{16{1'b0}}, reg_file[rs1][(i*16)+:16]} * {{16{reg_file[rs2][(i*16)+15]}}, reg_file[rs2][(i*16)+:16]};
					end
				end else if (csr_reg_file[12'h0A0] == 1) begin
					`uvm_info("CV_DOTUSP_B", "Instruction CV_DOTUSP_B detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 4; i++) begin
						reg_file[rd] += {{24{1'b0}}, reg_file[rs1][(i*8)+:8]} * {{24{reg_file[rs2][(i*8)+7]}}, reg_file[rs2][(i*8)+:8]};
					end
				end else if (csr_reg_file[12'h0A0] == 6) begin
					`uvm_info("CV_DOTUSP_MX", "Instruction CV_DOTUSP_MX detected successfully", UVM_MEDIUM);
					if (iteration_mx == 0) begin
						for (int i = 0; i < 2; i++) begin
							reg_file[rd] += {{16{1'b0}}, reg_file[rs1][(i*16)+:16]} * {{24{reg_file[rs2][(i*8)+7]}}, reg_file[rs2][(i*8)+:8]};
						end
					end else begin
						for (int i = 0; i < 2; i++) begin
							reg_file[rd] += {{16{1'b0}}, reg_file[rs1][(i*16)+:16]} * {{24{reg_file[rs2][((i+2)*8)+7]}}, reg_file[rs2][((i+2)*8)+:8]};
						end
					end
					iteration_mx = ~iteration_mx;
				end

            end

            CV_DOTUSP_SC : begin

                `uvm_info("CV_DOTUSP_SC", "Instruction CV_DOTUSP_SC detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				reg_file[rd] = 0;
				if (csr_reg_file[12'h0A0] == 2) begin
					`uvm_info("CV_DOTUSP_SC_H", "Instruction CV_DOTUSP_SC_H detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 2; i++) begin
						reg_file[rd] += {{16{1'b0}}, reg_file[rs1][(i*16)+:16]} * {{16{reg_file[rs2][15]}}, reg_file[rs2][15:0]};
					end
				end else if (csr_reg_file[12'h0A0] == 1) begin
					`uvm_info("CV_DOTUSP_SC_B", "Instruction CV_DOTUSP_SC_B detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 4; i++) begin
						reg_file[rd] += {{24{1'b0}}, reg_file[rs1][(i*8)+:8]} * {{24{reg_file[rs2][7]}}, reg_file[rs2][7:0]};
					end
				end else if (csr_reg_file[12'h0A0] == 6) begin
					`uvm_info("CV_DOTUSP_SC_MX", "Instruction CV_DOTUSP_SC_MX detected successfully", UVM_MEDIUM);
					if (iteration_mx == 0) begin
						for (int i = 0; i < 2; i++) begin
							reg_file[rd] += {{16{1'b0}}, reg_file[rs1][(i*16)+:16]} * {{24{reg_file[rs2][7]}}, reg_file[rs2][7:0]};
						end
					end else begin
						for (int i = 0; i < 2; i++) begin
							reg_file[rd] += {{16{1'b0}}, reg_file[rs1][(i*16)+:16]} * {{24{reg_file[rs2][7]}}, reg_file[rs2][7:0]};
						end
					end
					iteration_mx = ~iteration_mx;
				end

            end

            CV_DOTUSP_SCI : begin

                `uvm_info("CV_DOTUSP_SCI", "Instruction CV_DOTUSP_SCI detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                imm6 = instr[25:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				imm6_ext = {{27{imm6[4]}}, imm6[3:0], imm6[5]};
				reg_file[rd] = 0;
				if (csr_reg_file[12'h0A0] == 2) begin
					`uvm_info("CV_DOTUSP_SCI_H", "Instruction CV_DOTUSP_SCI_H detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 2; i++) begin
						reg_file[rd] += {{16{1'b0}}, reg_file[rs1][(i*16)+:16]} * {{16{imm6_ext[15]}}, imm6_ext[15:0]};
					end
				end else if (csr_reg_file[12'h0A0] == 1) begin
					`uvm_info("CV_DOTUSP_SCI_B", "Instruction CV_DOTUSP_SCI_B detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 4; i++) begin
						reg_file[rd] += {{24{1'b0}}, reg_file[rs1][(i*8)+:8]} * {{24{imm6_ext[7]}}, imm6_ext[7:0]};
					end
				end else if (csr_reg_file[12'h0A0] == 6) begin
					`uvm_info("CV_DOTUSP_SCI_MX", "Instruction CV_DOTUSP_SCI_MX detected successfully", UVM_MEDIUM);
					if (iteration_mx == 0) begin
						for (int i = 0; i < 2; i++) begin
							reg_file[rd] += {{16{1'b0}}, reg_file[rs1][(i*16)+:16]} * {{24{imm6_ext[7]}}, imm6_ext[7:0]};
						end
					end else begin
						for (int i = 0; i < 2; i++) begin
							reg_file[rd] += {{16{1'b0}}, reg_file[rs1][(i*16)+:16]} * {{24{imm6_ext[7]}}, imm6_ext[7:0]};
						end
					end
					iteration_mx = ~iteration_mx;
				end

            end

            CV_EXTBS : begin

                `uvm_info("CV_EXTBS", "Instruction CV_EXTBS detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				reg_file[rd] = {{24{reg_file[rs1][7]}}, reg_file[rs1][7:0]};

            end

            CV_EXTBZ : begin

                `uvm_info("CV_EXTBZ", "Instruction CV_EXTBZ detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				reg_file[rd] = {{16{1'b0}}, reg_file[rs1][7:0]};

            end

            CV_EXTHS : begin

                `uvm_info("CV_EXTHS", "Instruction CV_EXTHS detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				reg_file[rd] = {{16{reg_file[rs1][15]}}, reg_file[rs1][15:0]};

            end

            CV_EXTHZ : begin

                `uvm_info("CV_EXTHZ", "Instruction CV_EXTHZ detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				reg_file[rd] = {{16{1'b0}}, reg_file[rs1][15:0]};

            end

            CV_LB_RIPI : begin

                `uvm_info("CV_LB_RIPI", "Instruction CV_LB_RIPI detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                imm12 = instr[31:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				imm12_ext = {{20{imm12[11]}}, imm12};
				reg_file[rd] = {{24{mem[reg_file[rs1]][7]}}, mem[reg_file[rs1]][7:0]};
				reg_file[rs1] += imm12_ext;

            end

            CV_LB_RR : begin

                `uvm_info("CV_LB_RR", "Instruction CV_LB_RR detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				reg_file[rd] = {{24{mem[reg_file[rs1] + reg_file[rs2]][7]}}, mem[reg_file[rs1] + reg_file[rs2]][7:0]};

            end

            CV_LB_RRPI : begin

                `uvm_info("CV_LB_RRPI", "Instruction CV_LB_RRPI detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				reg_file[rd] = {{24{mem[reg_file[rs1]][7]}}, mem[reg_file[rs1]][7:0]};
				reg_file[rs1] += reg_file[rs2];

            end

            CV_LBU_RIPI : begin

                `uvm_info("CV_LBU_RIPI", "Instruction CV_LBU_RIPI detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                imm12 = instr[31:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				imm12_ext = {{20{imm12[11]}}, imm12};
				reg_file[rd] = {24'b0, mem[reg_file[rs1]][7:0]};
				reg_file[rs1] += imm12_ext;

            end

            CV_LBU_RR : begin

                `uvm_info("CV_LBU_RR", "Instruction CV_LBU_RR detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				reg_file[rd] = {24'b0, mem[reg_file[rs1] + reg_file[rs2]][7:0]};

            end

            CV_LBU_RRPI : begin

                `uvm_info("CV_LBU_RRPI", "Instruction CV_LBU_RRPI detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				reg_file[rd] = {24'b0, mem[reg_file[rs1]][7:0]};
				reg_file[rs1] += reg_file[rs2];

            end

            CV_LH_RIPI : begin

                `uvm_info("CV_LH_RIPI", "Instruction CV_LH_RIPI detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                imm12 = instr[31:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				imm12_ext = {{20{imm12[11]}}, imm12};
				reg_file[rd] = {{16{mem[reg_file[rs1] + 1][7]}}, mem[reg_file[rs1] + 1][7:0], mem[reg_file[rs1]][7:0]};
				reg_file[rs1] += imm12_ext;

            end

            CV_LH_RR : begin

                `uvm_info("CV_LH_RR", "Instruction CV_LH_RR detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				reg_file[rd] = {{16{mem[reg_file[rs1] + reg_file[rs2] + 1][7]}}, mem[reg_file[rs1] + reg_file[rs2] + 1][7:0], mem[reg_file[rs1] + reg_file[rs2]][7:0]};

            end

            CV_LH_RRPI : begin

                `uvm_info("CV_LH_RRPI", "Instruction CV_LH_RRPI detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				reg_file[rd] = {{16{mem[reg_file[rs1] + 1][7]}}, mem[reg_file[rs1] + 1][7:0], mem[reg_file[rs1]][7:0]};
				reg_file[rs1] += reg_file[rs2];

            end

            CV_LHU_RIPI : begin

                `uvm_info("CV_LHU_RIPI", "Instruction CV_LHU_RIPI detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                imm12 = instr[31:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				imm12_ext = {{20{imm12[11]}}, imm12};
				reg_file[rd] = {16'b0, mem[reg_file[rs1] + 1][7:0], mem[reg_file[rs1]][7:0]};
				reg_file[rs1] += imm12_ext;

            end

            CV_LHU_RR : begin

                `uvm_info("CV_LHU_RR", "Instruction CV_LHU_RR detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				reg_file[rd] = {16'b0, mem[reg_file[rs1] + reg_file[rs2] + 1][7:0], mem[reg_file[rs1] + reg_file[rs2]][7:0]};

            end

            CV_LHU_RRPI : begin

                `uvm_info("CV_LHU_RRPI", "Instruction CV_LHU_RRPI detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				reg_file[rd] = {16'b0, mem[reg_file[rs1] + 1][7:0], mem[reg_file[rs1]][7:0]};
				reg_file[rs1] += reg_file[rs2];

            end

            CV_LW_RIPI : begin

                `uvm_info("CV_LW_RIPI", "Instruction CV_LW_RIPI detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                imm12 = instr[31:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				imm12_ext = {{20{imm12[11]}}, imm12};
				reg_file[rd] = {mem[reg_file[rs1] + 3][7:0], mem[reg_file[rs1] + 2][7:0], mem[reg_file[rs1] + 1][7:0], mem[reg_file[rs1]][7:0]};
				reg_file[rs1] += imm12_ext;

            end

            CV_LW_RR : begin

                `uvm_info("CV_LW_RR", "Instruction CV_LW_RR detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				reg_file[rd] = {mem[reg_file[rs1] + reg_file[rs2] + 3][7:0], mem[reg_file[rs1] + reg_file[rs2] + 2][7:0], mem[reg_file[rs1] + reg_file[rs2] + 1][7:0], mem[reg_file[rs1] + reg_file[rs2]][7:0]};

            end

            CV_LW_RRPI : begin

                `uvm_info("CV_LW_RRPI", "Instruction CV_LW_RRPI detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				reg_file[rd] = {mem[reg_file[rs1] + 3][7:0], mem[reg_file[rs1] + 2][7:0], mem[reg_file[rs1] + 1][7:0], mem[reg_file[rs1]][7:0]};
				reg_file[rs1] += reg_file[rs2];

            end

            CV_MAC : begin

                `uvm_info("CV_MAC", "Instruction CV_MAC detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				reg_file[rd] = reg_file[rd] + (reg_file[rs1] * reg_file[rs2]);

            end

            CV_MACHHSN : begin

                `uvm_info("CV_MACHHSN", "Instruction CV_MACHHSN detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                ls3 = instr[29:25];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				if (csr_reg_file[12'h0A0] == 2) begin
					`uvm_info("CV_MACHHSN_H", "Instruction CV_MACHHSN_H detected successfully", UVM_MEDIUM);
					reg_file[rd] = $signed(({{16{reg_file[rs1][31]}}, reg_file[rs1][31:16]} * {{16{reg_file[rs2][31]}}, reg_file[rs2][31:16]}) + reg_file[rd]) >>> ls3;
				end else if (csr_reg_file[12'h0A0] == 1) begin
					`uvm_info("CV_MACHHSN_B", "Instruction CV_MACHHSN_B detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 2; i++) begin
						reg_mac_mul_prov = $signed(({{24{reg_file[rs1][((i+2)*8)+7]}}, reg_file[rs1][((i+2)*8)+:8]} * {{24{reg_file[rs2][((i+2)*8)+7]}}, reg_file[rs2][((i+2)*8)+:8]}) + ({{16{reg_file[rd][(i*16)+15]}}, reg_file[rd][(i*16)+:16]}));
						reg_file[rd][(i*16)+:16] = $signed(reg_mac_mul_prov) >>> ls3;
					end
				end

            end

            CV_MACHHSRN : begin

                `uvm_info("CV_MACHHSRN", "Instruction CV_MACHHSRN detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                ls3 = instr[29:25];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				if (csr_reg_file[12'h0A0] == 2) begin
					`uvm_info("CV_MACHHSRN_H", "Instruction CV_MACHHSRN_H detected successfully", UVM_MEDIUM);
					if (ls3 != 0) begin
						reg_file[rd] = $signed(({{16{reg_file[rs1][31]}}, reg_file[rs1][31:16]} * {{16{reg_file[rs2][31]}}, reg_file[rs2][31:16]}) + reg_file[rd] + (1 << (ls3-1))) >>> ls3;
					end else begin
						reg_file[rd] = $signed(({{16{reg_file[rs1][31]}}, reg_file[rs1][31:16]} * {{16{reg_file[rs2][31]}}, reg_file[rs2][31:16]}) + reg_file[rd]) >>> ls3;
					end
				end else if (csr_reg_file[12'h0A0] == 1) begin
					`uvm_info("CV_MACHHSRN_B", "Instruction CV_MACHHSRN_B detected successfully", UVM_MEDIUM);
					if (ls3 != 0) begin
						for (int i = 0; i < 2; i++) begin
							reg_mac_mul_prov = $signed(({{24{reg_file[rs1][((i+2)*8)+7]}}, reg_file[rs1][((i+2)*8)+:8]} * {{24{reg_file[rs2][((i+2)*8)+7]}}, reg_file[rs2][((i+2)*8)+:8]}) + ({{16{reg_file[rd][(i*16)+15]}}, reg_file[rd][(i*16)+:16]}) + (1 << (ls3-1)));
							reg_file[rd][(i*16)+:16] = $signed(reg_mac_mul_prov) >>> ls3;
						end
					end else begin
						for (int i = 0; i < 2; i++) begin
							reg_mac_mul_prov = $signed(({{24{reg_file[rs1][((i+2)*8)+7]}}, reg_file[rs1][((i+2)*8)+:8]} * {{24{reg_file[rs2][((i+2)*8)+7]}}, reg_file[rs2][((i+2)*8)+:8]}) + ({{16{reg_file[rd][(i*16)+15]}}, reg_file[rd][(i*16)+:16]}));
							reg_file[rd][(i*16)+:16] = $signed(reg_mac_mul_prov) >>> ls3;
						end
					end
				end

            end

            CV_MACHHUN : begin

                `uvm_info("CV_MACHHUN", "Instruction CV_MACHHUN detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                ls3 = instr[29:25];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				if (csr_reg_file[12'h0A0] == 2) begin
					`uvm_info("CV_MACHHUN_H", "Instruction CV_MACHHUN_H detected successfully", UVM_MEDIUM);
					reg_file[rd] = (({{16{1'b0}}, reg_file[rs1][31:16]} * {{16{1'b0}}, reg_file[rs2][31:16]}) + reg_file[rd]) >> ls3;
				end else if (csr_reg_file[12'h0A0] == 1) begin
					`uvm_info("CV_MACHHUN_B", "Instruction CV_MACHHUN_B detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 2; i++) begin
						reg_mac_mul_prov = (({{24{1'b0}}, reg_file[rs1][((i+2)*8)+:8]} * {{24{1'b0}}, reg_file[rs2][((i+2)*8)+:8]}) + reg_file[rd][(i*16)+:16]);
						reg_file[rd][(i*16)+:16] = reg_mac_mul_prov >> ls3;
					end
				end

            end

            CV_MACHHURN : begin

                `uvm_info("CV_MACHHURN", "Instruction CV_MACHHURN detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                ls3 = instr[29:25];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				if (csr_reg_file[12'h0A0] == 2) begin
					`uvm_info("CV_MACHHURN_H", "Instruction CV_MACHHURN_H detected successfully", UVM_MEDIUM);
					if (ls3 != 0) begin
						reg_file[rd] = (({{16{1'b0}}, reg_file[rs1][31:16]} * {{16{1'b0}}, reg_file[rs2][31:16]}) + reg_file[rd] + (1 << (ls3-1))) >> ls3;
					end else begin
						reg_file[rd] = (({{16{1'b0}}, reg_file[rs1][31:16]} * {{16{1'b0}}, reg_file[rs2][31:16]}) + reg_file[rd]) >> ls3;
					end
				end else if (csr_reg_file[12'h0A0] == 1) begin
					`uvm_info("CV_MACHHURN_B", "Instruction CV_MACHHURN_B detected successfully", UVM_MEDIUM);
					if (ls3 != 0) begin
						for (int i = 0; i < 2; i++) begin
							reg_mac_mul_prov = (({{24{1'b0}}, reg_file[rs1][((i+2)*8)+:8]} * {{24{1'b0}}, reg_file[rs2][((i+2)*8)+:8]}) + reg_file[rd][(i*16)+:16] + (1 << (ls3-1)));
							reg_file[rd][(i*16)+:16] = reg_mac_mul_prov >> ls3;
						end
					end else begin
						for (int i = 0; i < 2; i++) begin
							reg_mac_mul_prov = (({{24{1'b0}}, reg_file[rs1][((i+2)*8)+:8]} * {{24{1'b0}}, reg_file[rs2][((i+2)*8)+:8]}) + reg_file[rd][(i*16)+:16]);
							reg_file[rd][(i*16)+:16] = reg_mac_mul_prov >> ls3;
						end
					end
				end

            end

            CV_MACSN : begin

                `uvm_info("CV_MACSN", "Instruction CV_MACSN detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                ls3 = instr[29:25];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				if (csr_reg_file[12'h0A0] == 2) begin
					`uvm_info("CV_MACSN_H", "Instruction CV_MACSN_H detected successfully", UVM_MEDIUM);
					reg_file[rd] = $signed(({{16{reg_file[rs1][15]}}, reg_file[rs1][15:0]} * {{16{reg_file[rs2][15]}}, reg_file[rs2][15:0]}) + reg_file[rd]) >>> ls3;
				end else if (csr_reg_file[12'h0A0] == 1) begin
					`uvm_info("CV_MACSN_B", "Instruction CV_MACSN_B detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 2; i++) begin
						reg_mac_mul_prov = $signed(({{24{reg_file[rs1][(i*8)+7]}}, reg_file[rs1][(i*8)+:8]} * {{24{reg_file[rs2][(i*8)+7]}}, reg_file[rs2][(i*8)+:8]}) + ({{16{reg_file[rd][(i*16)+15]}}, reg_file[rd][(i*16)+:16]}));
						reg_file[rd][(i*16)+:16] = $signed(reg_mac_mul_prov) >>> ls3;
					end
				end

            end

            CV_MACSRN : begin

                `uvm_info("CV_MACSRN", "Instruction CV_MACSRN detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                ls3 = instr[29:25];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				if (csr_reg_file[12'h0A0] == 2) begin
					`uvm_info("CV_MACSRN_H", "Instruction CV_MACSRN_H detected successfully", UVM_MEDIUM);
					if (ls3 != 0) begin
						reg_file[rd] = $signed(({{16{reg_file[rs1][15]}}, reg_file[rs1][15:0]} * {{16{reg_file[rs2][15]}}, reg_file[rs2][15:0]}) + reg_file[rd] + (1 << (ls3-1))) >>> ls3;
					end else begin
						reg_file[rd] = $signed(({{16{reg_file[rs1][15]}}, reg_file[rs1][15:0]} * {{16{reg_file[rs2][15]}}, reg_file[rs2][15:0]}) + reg_file[rd]) >>> ls3;
					end
				end else if (csr_reg_file[12'h0A0] == 1) begin
					`uvm_info("CV_MACSRN_B", "Instruction CV_MACSRN_B detected successfully", UVM_MEDIUM);
					if (ls3 != 0) begin
						for (int i = 0; i < 2; i++) begin
							reg_mac_mul_prov = $signed(({{24{reg_file[rs1][(i*8)+7]}}, reg_file[rs1][(i*8)+:8]} * {{24{reg_file[rs2][(i*8)+7]}}, reg_file[rs2][(i*8)+:8]}) + ({{16{reg_file[rd][(i*16)+15]}}, reg_file[rd][(i*16)+:16]}) + (1 << (ls3-1)));
							reg_file[rd][(i*16)+:16] = $signed(reg_mac_mul_prov) >>> ls3;
						end
					end else begin
						for (int i = 0; i < 2; i++) begin
							reg_mac_mul_prov = $signed(({{24{reg_file[rs1][(i*8)+7]}}, reg_file[rs1][(i*8)+:8]} * {{24{reg_file[rs2][(i*8)+7]}}, reg_file[rs2][(i*8)+:8]}) + ({{16{reg_file[rd][(i*16)+15]}}, reg_file[rd][(i*16)+:16]}));
							reg_file[rd][(i*16)+:16] = $signed(reg_mac_mul_prov) >>> ls3;
						end
					end
				end

            end

            CV_MACUN : begin

                `uvm_info("CV_MACUN", "Instruction CV_MACUN detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                ls3 = instr[29:25];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				if (csr_reg_file[12'h0A0] == 2) begin
					`uvm_info("CV_MACUN_H", "Instruction CV_MACUN_H detected successfully", UVM_MEDIUM);
					reg_file[rd] = (({{16{1'b0}}, reg_file[rs1][15:0]} * {{16{1'b0}}, reg_file[rs2][15:0]}) + reg_file[rd]) >> ls3;
				end else if (csr_reg_file[12'h0A0] == 1) begin
					`uvm_info("CV_MACUN_B", "Instruction CV_MACUN_B detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 2; i++) begin
						reg_mac_mul_prov = (({{24{1'b0}}, reg_file[rs1][(i*8)+:8]} * {{24{1'b0}}, reg_file[rs2][(i*8)+:8]}) + reg_file[rd][(i*16)+:16]);
						reg_file[rd][(i*16)+:16] = reg_mac_mul_prov >> ls3;
					end
				end

            end

            CV_MACURN : begin

                `uvm_info("CV_MACURN", "Instruction CV_MACURN detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                ls3 = instr[29:25];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				if (csr_reg_file[12'h0A0] == 2) begin
					`uvm_info("CV_MACURN_H", "Instruction CV_MACURN_H detected successfully", UVM_MEDIUM);
					if (ls3 != 0) begin
						reg_file[rd] = (({{16{1'b0}}, reg_file[rs1][15:0]} * {{16{1'b0}}, reg_file[rs2][15:0]}) + reg_file[rd] + (1 << (ls3-1))) >> ls3;
					end else begin
						reg_file[rd] = (({{16{1'b0}}, reg_file[rs1][15:0]} * {{16{1'b0}}, reg_file[rs2][15:0]}) + reg_file[rd]) >> ls3;
					end
				end else if (csr_reg_file[12'h0A0] == 1) begin
					`uvm_info("CV_MACURN_B", "Instruction CV_MACURN_B detected successfully", UVM_MEDIUM);
					if (ls3 != 0) begin
						for (int i = 0; i < 2; i++) begin
							reg_mac_mul_prov = (({{24{1'b0}}, reg_file[rs1][(i*8)+:8]} * {{24{1'b0}}, reg_file[rs2][(i*8)+:8]}) + reg_file[rd][(i*16)+:16] + (1 << (ls3-1)));
							reg_file[rd][(i*16)+:16] = reg_mac_mul_prov >> ls3;
						end
					end else begin
						for (int i = 0; i < 2; i++) begin
							reg_mac_mul_prov = (({{24{1'b0}}, reg_file[rs1][(i*8)+:8]} * {{24{1'b0}}, reg_file[rs2][(i*8)+:8]}) + reg_file[rd][(i*16)+:16]);
							reg_file[rd][(i*16)+:16] = reg_mac_mul_prov >> ls3;
						end
					end
				end

            end

            CV_MAX : begin

                `uvm_info("CV_MAX", "Instruction CV_MAX detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				if (csr_reg_file[12'h0A0] == 2) begin
					`uvm_info("CV_MAX_H", "Instruction CV_MAX_H detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 2; i++) begin
						if ($signed(reg_file[rs1][(i*16)+:16]) > $signed(reg_file[rs2][(i*16)+:16])) begin
							reg_file[rd][(i*16)+:16] = reg_file[rs1][(i*16)+:16];
						end else begin
							reg_file[rd][(i*16)+:16] = reg_file[rs2][(i*16)+:16];
						end
					end
				end else if (csr_reg_file[12'h0A0] == 1) begin
					`uvm_info("CV_MAX_B", "Instruction CV_MAX_B detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 4; i++) begin
						if ($signed(reg_file[rs1][(i*8)+:8]) > $signed(reg_file[rs2][(i*8)+:8])) begin
							reg_file[rd][(i*8)+:8] = reg_file[rs1][(i*8)+:8];
						end else begin
							reg_file[rd][(i*8)+:8] = reg_file[rs2][(i*8)+:8];
						end
					end
				end

            end

            CV_MAX_SC : begin

                `uvm_info("CV_MAX_SC", "Instruction CV_MAX_SC detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				if (csr_reg_file[12'h0A0] == 2) begin
					`uvm_info("CV_MAX_SC_H", "Instruction CV_MAX_SC_H detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 2; i++) begin
						if ($signed(reg_file[rs1][(i*16)+:16]) > $signed(reg_file[rs2][15:0])) begin
							reg_file[rd][(i*16)+:16] = reg_file[rs1][(i*16)+:16];
						end else begin
							reg_file[rd][(i*16)+:16] = reg_file[rs2][15:0];
						end
					end
				end else if (csr_reg_file[12'h0A0] == 1) begin
					`uvm_info("CV_MAX_SC_B", "Instruction CV_MAX_SC_B detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 4; i++) begin
						if ($signed(reg_file[rs1][(i*8)+:8]) > $signed(reg_file[rs2][7:0])) begin
							reg_file[rd][(i*8)+:8] = reg_file[rs1][(i*8)+:8];
						end else begin
							reg_file[rd][(i*8)+:8] = reg_file[rs2][7:0];
						end
					end
				end

            end

            CV_MAX_SCI : begin

                `uvm_info("CV_MAX_SCI", "Instruction CV_MAX_SCI detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                imm6 = instr[25:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				imm6_ext = {{27{imm6[4]}}, imm6[3:0], imm6[5]};
				if (csr_reg_file[12'h0A0] == 2) begin
					`uvm_info("CV_MAX_SCI_H", "Instruction CV_MAX_SCI_H detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 2; i++) begin
						if ($signed(reg_file[rs1][(i*16)+:16]) > $signed(imm6_ext[15:0])) begin
							reg_file[rd][(i*16)+:16] = reg_file[rs1][(i*16)+:16];
						end else begin
							reg_file[rd][(i*16)+:16] = imm6_ext[15:0];
						end
					end
				end else if (csr_reg_file[12'h0A0] == 1) begin
					`uvm_info("CV_MAX_SCI_B", "Instruction CV_MAX_SCI_B detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 4; i++) begin
						if ($signed(reg_file[rs1][(i*8)+:8]) > $signed(imm6_ext[7:0])) begin
							reg_file[rd][(i*8)+:8] = reg_file[rs1][(i*8)+:8];
						end else begin
							reg_file[rd][(i*8)+:8] = imm6_ext[7:0];
						end
					end
				end

            end

            CV_MAX_W : begin

                `uvm_info("CV_MAX_W", "Instruction CV_MAX_W detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				if ($signed(reg_file[rs1]) < $signed(reg_file[rs2])) begin
					reg_file[rd] = reg_file[rs2];
				end else begin
					reg_file[rd] = reg_file[rs1];
				end

            end

            CV_MAXU : begin

                `uvm_info("CV_MAXU", "Instruction CV_MAXU detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				if (csr_reg_file[12'h0A0] == 2) begin
					`uvm_info("CV_MAXU_H", "Instruction CV_MAXU_H detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 2; i++) begin
						if (reg_file[rs1][(i*16)+:16] > reg_file[rs2][(i*16)+:16]) begin
							reg_file[rd][(i*16)+:16] = reg_file[rs1][(i*16)+:16];
						end else begin
							reg_file[rd][(i*16)+:16] = reg_file[rs2][(i*16)+:16];
						end
					end
				end else if (csr_reg_file[12'h0A0] == 1) begin
					`uvm_info("CV_MAXU_B", "Instruction CV_MAXU_B detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 4; i++) begin
						if (reg_file[rs1][(i*8)+:8] > reg_file[rs2][(i*8)+:8]) begin
							reg_file[rd][(i*8)+:8] = reg_file[rs1][(i*8)+:8];
						end else begin
							reg_file[rd][(i*8)+:8] = reg_file[rs2][(i*8)+:8];
						end
					end
				end

            end

            CV_MAXU_SC : begin

                `uvm_info("CV_MAXU_SC", "Instruction CV_MAXU_SC detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				if (csr_reg_file[12'h0A0] == 2) begin
					`uvm_info("CV_MAXU_SC_H", "Instruction CV_MAXU_SC_H detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 2; i++) begin
						if (reg_file[rs1][(i*16)+:16] > reg_file[rs2][15:0]) begin
							reg_file[rd][(i*16)+:16] = reg_file[rs1][(i*16)+:16];
						end else begin
							reg_file[rd][(i*16)+:16] = reg_file[rs2][15:0];
						end
					end
				end else if (csr_reg_file[12'h0A0] == 1) begin
					`uvm_info("CV_MAXU_SC_B", "Instruction CV_MAXU_SC_B detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 4; i++) begin
						if (reg_file[rs1][(i*8)+:8] > reg_file[rs2][7:0]) begin
							reg_file[rd][(i*8)+:8] = reg_file[rs1][(i*8)+:8];
						end else begin
							reg_file[rd][(i*8)+:8] = reg_file[rs2][7:0];
						end
					end
				end

            end

            CV_MAXU_SCI : begin

                `uvm_info("CV_MAXU_SCI", "Instruction CV_MAXU_SCI detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                imm6 = instr[25:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				imm6_ext = {26'b0, imm6[4], imm6[3:0], imm6[5]};
				if (csr_reg_file[12'h0A0] == 2) begin
					`uvm_info("CV_MAXU_SCI_H", "Instruction CV_MAXU_SCI_H detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 2; i++) begin
						if (reg_file[rs1][(i*16)+:16] > imm6_ext[15:0]) begin
							reg_file[rd][(i*16)+:16] = reg_file[rs1][(i*16)+:16];
						end else begin
							reg_file[rd][(i*16)+:16] = imm6_ext[15:0];
						end
					end
				end else if (csr_reg_file[12'h0A0] == 1) begin
					`uvm_info("CV_MAXU_SCI_B", "Instruction CV_MAXU_SCI_B detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 4; i++) begin
						if (reg_file[rs1][(i*8)+:8] > imm6_ext[7:0]) begin
							reg_file[rd][(i*8)+:8] = reg_file[rs1][(i*8)+:8];
						end else begin
							reg_file[rd][(i*8)+:8] = imm6_ext[7:0];
						end
					end
				end

            end

            CV_MAXU_W : begin

                `uvm_info("CV_MAXU_W", "Instruction CV_MAXU_W detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				if (reg_file[rs1] < reg_file[rs2]) begin
					reg_file[rd] = reg_file[rs2];
				end else begin
					reg_file[rd] = reg_file[rs1];
				end

            end

            CV_MIN : begin

                `uvm_info("CV_MIN", "Instruction CV_MIN detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				if (csr_reg_file[12'h0A0] == 2) begin
					`uvm_info("CV_MIN_H", "Instruction CV_MIN_H detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 2; i++) begin
						if ($signed(reg_file[rs1][(i*16)+:16]) < $signed(reg_file[rs2][(i*16)+:16])) begin
							reg_file[rd][(i*16)+:16] = reg_file[rs1][(i*16)+:16];
						end else begin
							reg_file[rd][(i*16)+:16] = reg_file[rs2][(i*16)+:16];
						end
					end
				end else if (csr_reg_file[12'h0A0] == 1) begin
					`uvm_info("CV_MIN_B", "Instruction CV_MIN_B detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 4; i++) begin
						if ($signed(reg_file[rs1][(i*8)+:8]) < $signed(reg_file[rs2][(i*8)+:8])) begin
							reg_file[rd][(i*8)+:8] = reg_file[rs1][(i*8)+:8];
						end else begin
							reg_file[rd][(i*8)+:8] = reg_file[rs2][(i*8)+:8];
						end
					end
				end

            end

            CV_MIN_SC : begin

                `uvm_info("CV_MIN_SC", "Instruction CV_MIN_SC detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				if (csr_reg_file[12'h0A0] == 2) begin
					`uvm_info("CV_MIN_SC_H", "Instruction CV_MIN_SC_H detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 2; i++) begin
						if ($signed(reg_file[rs1][(i*16)+:16]) < $signed(reg_file[rs2][15:0])) begin
							reg_file[rd][(i*16)+:16] = reg_file[rs1][(i*16)+:16];
						end else begin
							reg_file[rd][(i*16)+:16] = reg_file[rs2][15:0];
						end
					end
				end else if (csr_reg_file[12'h0A0] == 1) begin
					`uvm_info("CV_MIN_SC_B", "Instruction CV_MIN_SC_B detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 4; i++) begin
						if ($signed(reg_file[rs1][(i*8)+:8]) < $signed(reg_file[rs2][7:0])) begin
							reg_file[rd][(i*8)+:8] = reg_file[rs1][(i*8)+:8];
						end else begin
							reg_file[rd][(i*8)+:8] = reg_file[rs2][7:0];
						end
					end
				end

            end

            CV_MIN_SCI : begin

                `uvm_info("CV_MIN_SCI", "Instruction CV_MIN_SCI detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                imm6 = instr[25:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				imm6_ext = {{27{imm6[4]}}, imm6[3:0], imm6[5]};
				if (csr_reg_file[12'h0A0] == 2) begin
					`uvm_info("CV_MIN_SCI_H", "Instruction CV_MIN_SCI_H detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 2; i++) begin
						if ($signed(reg_file[rs1][(i*16)+:16]) < $signed(imm6_ext[15:0])) begin
							reg_file[rd][(i*16)+:16] = reg_file[rs1][(i*16)+:16];
						end else begin
							reg_file[rd][(i*16)+:16] = imm6_ext[15:0];
						end
					end
				end else if (csr_reg_file[12'h0A0] == 1) begin
					`uvm_info("CV_MIN_SCI_B", "Instruction CV_MIN_SCI_B detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 4; i++) begin
						if ($signed(reg_file[rs1][(i*8)+:8]) < $signed(imm6_ext[7:0])) begin
							reg_file[rd][(i*8)+:8] = reg_file[rs1][(i*8)+:8];
						end else begin
							reg_file[rd][(i*8)+:8] = imm6_ext[7:0];
						end
					end
				end

            end

            CV_MIN_W : begin

                `uvm_info("CV_MIN_W", "Instruction CV_MIN_W detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				if ($signed(reg_file[rs1]) < $signed(reg_file[rs2])) begin
					reg_file[rd] = reg_file[rs1];
				end else begin
					reg_file[rd] = reg_file[rs2];
				end

            end

            CV_MINU : begin

                `uvm_info("CV_MINU", "Instruction CV_MINU detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				if (csr_reg_file[12'h0A0] == 2) begin
					`uvm_info("CV_MINU_H", "Instruction CV_MINU_H detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 2; i++) begin
						if (reg_file[rs1][(i*16)+:16] < reg_file[rs2][(i*16)+:16]) begin
							reg_file[rd][(i*16)+:16] = reg_file[rs1][(i*16)+:16];
						end else begin
							reg_file[rd][(i*16)+:16] = reg_file[rs2][(i*16)+:16];
						end
					end
				end else if (csr_reg_file[12'h0A0] == 1) begin
					`uvm_info("CV_MINU_B", "Instruction CV_MINU_B detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 4; i++) begin
						if (reg_file[rs1][(i*8)+:8] < reg_file[rs2][(i*8)+:8]) begin
							reg_file[rd][(i*8)+:8] = reg_file[rs1][(i*8)+:8];
						end else begin
							reg_file[rd][(i*8)+:8] = reg_file[rs2][(i*8)+:8];
						end
					end
				end

            end

            CV_MINU_SC : begin

                `uvm_info("CV_MINU_SC", "Instruction CV_MINU_SC detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				if (csr_reg_file[12'h0A0] == 2) begin
					`uvm_info("CV_MINU_SC_H", "Instruction CV_MINU_SC_H detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 2; i++) begin
						if (reg_file[rs1][(i*16)+:16] < reg_file[rs2][15:0]) begin
							reg_file[rd][(i*16)+:16] = reg_file[rs1][(i*16)+:16];
						end else begin
							reg_file[rd][(i*16)+:16] = reg_file[rs2][15:0];
						end
					end
				end else if (csr_reg_file[12'h0A0] == 1) begin
					`uvm_info("CV_MINU_SC_B", "Instruction CV_MINU_SC_B detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 4; i++) begin
						if (reg_file[rs1][(i*8)+:8] < reg_file[rs2][7:0]) begin
							reg_file[rd][(i*8)+:8] = reg_file[rs1][(i*8)+:8];
						end else begin
							reg_file[rd][(i*8)+:8] = reg_file[rs2][7:0];
						end
					end
				end

            end

            CV_MINU_SCI : begin

                `uvm_info("CV_MINU_SCI", "Instruction CV_MINU_SCI detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                imm6 = instr[25:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				imm6_ext = {26'b0, imm6[4], imm6[3:0], imm6[5]};
				if (csr_reg_file[12'h0A0] == 2) begin
					`uvm_info("CV_MINU_SCI_H", "Instruction CV_MINU_SCI_H detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 2; i++) begin
						if (reg_file[rs1][(i*16)+:16] < imm6_ext[15:0]) begin
							reg_file[rd][(i*16)+:16] = reg_file[rs1][(i*16)+:16];
						end else begin
							reg_file[rd][(i*16)+:16] = imm6_ext[15:0];
						end
					end
				end else if (csr_reg_file[12'h0A0] == 1) begin
					`uvm_info("CV_MINU_SCI_B", "Instruction CV_MINU_SCI_B detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 4; i++) begin
						if (reg_file[rs1][(i*8)+:8] < imm6_ext[7:0]) begin
							reg_file[rd][(i*8)+:8] = reg_file[rs1][(i*8)+:8];
						end else begin
							reg_file[rd][(i*8)+:8] = imm6_ext[7:0];
						end
					end
				end

            end

            CV_MINU_W : begin

                `uvm_info("CV_MINU_W", "Instruction CV_MINU_W detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				if (reg_file[rs1] < reg_file[rs2]) begin
					reg_file[rd] = reg_file[rs1];
				end else begin
					reg_file[rd] = reg_file[rs2];
				end

            end

            CV_MSU : begin

                `uvm_info("CV_MSU", "Instruction CV_MSU detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				reg_file[rd] = reg_file[rd] - (reg_file[rs1] * reg_file[rs2]);

            end

            CV_MULHHSN : begin

                `uvm_info("CV_MULHHSN", "Instruction CV_MULHHSN detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                ls3 = instr[29:25];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				if (csr_reg_file[12'h0A0] == 2) begin
					`uvm_info("CV_MULHHSN_H", "Instruction CV_MULHHSN_H detected successfully", UVM_MEDIUM);
					reg_file[rd] = $signed({{16{reg_file[rs1][31]}}, reg_file[rs1][31:16]} * {{16{reg_file[rs2][31]}}, reg_file[rs2][31:16]}) >>> ls3;
				end else if (csr_reg_file[12'h0A0] == 1) begin
					`uvm_info("CV_MULHHSN_B", "Instruction CV_MULHHSN_B detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 2; i++) begin
						reg_mac_mul_prov = $signed({{24{reg_file[rs1][((i+2)*8)+7]}}, reg_file[rs1][((i+2)*8)+:8]} * {{24{reg_file[rs2][((i+2)*8)+7]}}, reg_file[rs2][((i+2)*8)+:8]});
						reg_file[rd][(i*16)+:16] = $signed(reg_mac_mul_prov) >>> ls3;
					end
				end

            end

            CV_MULHHSRN : begin

                `uvm_info("CV_MULHHSRN", "Instruction CV_MULHHSRN detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                ls3 = instr[29:25];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				if (csr_reg_file[12'h0A0] == 2) begin
					`uvm_info("CV_MULHHSRN_H", "Instruction CV_MULHHSRN_H detected successfully", UVM_MEDIUM);
					if (ls3 != 0) begin
						reg_file[rd] = $signed(({{16{reg_file[rs1][31]}}, reg_file[rs1][31:16]} * {{16{reg_file[rs2][31]}}, reg_file[rs2][31:16]}) + (1 << (ls3-1))) >>> ls3;
					end else begin
						reg_file[rd] = $signed({{16{reg_file[rs1][31]}}, reg_file[rs1][31:16]} * {{16{reg_file[rs2][31]}}, reg_file[rs2][31:16]}) >>> ls3;
					end
				end else if (csr_reg_file[12'h0A0] == 1) begin
					`uvm_info("CV_MULHHSRN_B", "Instruction CV_MULHHSRN_B detected successfully", UVM_MEDIUM);
					if (ls3 != 0) begin
						for (int i = 0; i < 2; i++) begin
							reg_mac_mul_prov = $signed(({{24{reg_file[rs1][((i+2)*8)+7]}}, reg_file[rs1][((i+2)*8)+:8]} * {{24{reg_file[rs2][((i+2)*8)+7]}}, reg_file[rs2][((i+2)*8)+:8]}) + (1 << (ls3-1)));
							reg_file[rd][(i*16)+:16] = $signed(reg_mac_mul_prov) >>> ls3;
						end
					end else begin
						for (int i = 0; i < 2; i++) begin
							reg_mac_mul_prov = $signed({{24{reg_file[rs1][((i+2)*8)+7]}}, reg_file[rs1][((i+2)*8)+:8]} * {{24{reg_file[rs2][((i+2)*8)+7]}}, reg_file[rs2][((i+2)*8)+:8]});
							reg_file[rd][(i*16)+:16] = $signed(reg_mac_mul_prov) >>> ls3;
						end
					end
				end

            end

            CV_MULHHUN : begin

                `uvm_info("CV_MULHHUN", "Instruction CV_MULHHUN detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                ls3 = instr[29:25];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				if (csr_reg_file[12'h0A0] == 2) begin
					`uvm_info("CV_MULHHUN_H", "Instruction CV_MULHHUN_H detected successfully", UVM_MEDIUM);
					reg_file[rd] = ({{16{1'b0}}, reg_file[rs1][31:16]} * {{16{1'b0}}, reg_file[rs2][31:16]}) >> ls3;
				end else if (csr_reg_file[12'h0A0] == 1) begin
					`uvm_info("CV_MULHHUN_B", "Instruction CV_MULHHUN_B detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 2; i++) begin
						reg_mac_mul_prov = ({{24{1'b0}}, reg_file[rs1][((i+2)*8)+:8]} * {{24{1'b0}}, reg_file[rs2][((i+2)*8)+:8]});
						reg_file[rd][(i*16)+:16] = reg_mac_mul_prov >> ls3;
					end
				end

            end

            CV_MULHHURN : begin

                `uvm_info("CV_MULHHURN", "Instruction CV_MULHHURN detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                ls3 = instr[29:25];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				if (csr_reg_file[12'h0A0] == 2) begin
					`uvm_info("CV_MULHHURN_H", "Instruction CV_MULHHURN_H detected successfully", UVM_MEDIUM);
					if (ls3 != 0) begin
						reg_file[rd] = (({{16{1'b0}}, reg_file[rs1][31:16]} * {{16{1'b0}}, reg_file[rs2][31:16]}) + (1 << (ls3-1))) >> ls3;
					end else begin
						reg_file[rd] = ({{16{1'b0}}, reg_file[rs1][31:16]} * {{16{1'b0}}, reg_file[rs2][31:16]}) >> ls3;
					end
				end else if (csr_reg_file[12'h0A0] == 1) begin
					`uvm_info("CV_MULHHURN_B", "Instruction CV_MULHHURN_B detected successfully", UVM_MEDIUM);
					if (ls3 != 0) begin
						for (int i = 0; i < 2; i++) begin
							reg_mac_mul_prov = (({{24{1'b0}}, reg_file[rs1][((i+2)*8)+:8]} * {{24{1'b0}}, reg_file[rs2][((i+2)*8)+:8]}) + (1 << (ls3-1)));
							reg_file[rd][(i*16)+:16] = reg_mac_mul_prov >> ls3;
						end
					end else begin
						for (int i = 0; i < 2; i++) begin
							reg_mac_mul_prov = ({{24{1'b0}}, reg_file[rs1][((i+2)*8)+:8]} * {{24{1'b0}}, reg_file[rs2][((i+2)*8)+:8]});
							reg_file[rd][(i*16)+:16] = reg_mac_mul_prov >> ls3;
						end
					end
				end

            end

            CV_MULSN : begin

                `uvm_info("CV_MULSN", "Instruction CV_MULSN detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                ls3 = instr[29:25];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				if (csr_reg_file[12'h0A0] == 2) begin
					`uvm_info("CV_MULSN_H", "Instruction CV_MULSN_H detected successfully", UVM_MEDIUM);
					reg_file[rd] = $signed({{16{reg_file[rs1][15]}}, reg_file[rs1][15:0]} * {{16{reg_file[rs2][15]}}, reg_file[rs2][15:0]}) >>> ls3;
				end else if (csr_reg_file[12'h0A0] == 1) begin
					`uvm_info("CV_MULSN_B", "Instruction CV_MULSN_B detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 2; i++) begin
						reg_mac_mul_prov = $signed({{24{reg_file[rs1][(i*8)+7]}}, reg_file[rs1][(i*8)+:8]} * {{24{reg_file[rs2][(i*8)+7]}}, reg_file[rs2][(i*8)+:8]});
						reg_file[rd][(i*16)+:16] = $signed(reg_mac_mul_prov) >>> ls3;
					end
				end

            end

            CV_MULSRN : begin

                `uvm_info("CV_MULSRN", "Instruction CV_MULSRN detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                ls3 = instr[29:25];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				if (csr_reg_file[12'h0A0] == 2) begin
					`uvm_info("CV_MULSRN_H", "Instruction CV_MULSRN_H detected successfully", UVM_MEDIUM);
					if (ls3 != 0) begin
						reg_file[rd] = $signed(({{16{reg_file[rs1][15]}}, reg_file[rs1][15:0]} * {{16{reg_file[rs2][15]}}, reg_file[rs2][15:0]}) + (1 << (ls3-1))) >>> ls3;
					end else begin
						reg_file[rd] = $signed({{16{reg_file[rs1][15]}}, reg_file[rs1][15:0]} * {{16{reg_file[rs2][15]}}, reg_file[rs2][15:0]}) >>> ls3;
					end
				end else if (csr_reg_file[12'h0A0] == 1) begin
					`uvm_info("CV_MULSRN_B", "Instruction CV_MULSRN_B detected successfully", UVM_MEDIUM);
					if (ls3 != 0) begin
						for (int i = 0; i < 2; i++) begin
							reg_mac_mul_prov = $signed(({{24{reg_file[rs1][(i*8)+7]}}, reg_file[rs1][(i*8)+:8]} * {{24{reg_file[rs2][(i*8)+7]}}, reg_file[rs2][(i*8)+:8]}) + (1 << (ls3-1)));
							reg_file[rd][(i*16)+:16] = $signed(reg_mac_mul_prov) >>> ls3;
						end
					end else begin
						for (int i = 0; i < 2; i++) begin
							reg_mac_mul_prov = $signed({{24{reg_file[rs1][(i*8)+7]}}, reg_file[rs1][(i*8)+:8]} * {{24{reg_file[rs2][(i*8)+7]}}, reg_file[rs2][(i*8)+:8]});
							reg_file[rd][(i*16)+:16] = $signed(reg_mac_mul_prov) >>> ls3;
						end
					end
				end

            end

            CV_MULUN : begin

                `uvm_info("CV_MULUN", "Instruction CV_MULUN detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                ls3 = instr[29:25];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				if (csr_reg_file[12'h0A0] == 2) begin
					`uvm_info("CV_MULUN_H", "Instruction CV_MULUN_H detected successfully", UVM_MEDIUM);
					reg_file[rd] = ({{16{1'b0}}, reg_file[rs1][15:0]} * {{16{1'b0}}, reg_file[rs2][15:0]}) >> ls3;
				end else if (csr_reg_file[12'h0A0] == 1) begin
					`uvm_info("CV_MULUN_B", "Instruction CV_MULUN_B detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 2; i++) begin
						reg_mac_mul_prov = ({{24{1'b0}}, reg_file[rs1][(i*8)+:8]} * {{24{1'b0}}, reg_file[rs2][(i*8)+:8]});
						reg_file[rd][(i*16)+:16] = reg_mac_mul_prov >> ls3;
					end
				end

            end

            CV_MULURN : begin

                `uvm_info("CV_MULURN", "Instruction CV_MULURN detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                ls3 = instr[29:25];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				if (csr_reg_file[12'h0A0] == 2) begin
					`uvm_info("CV_MULURN_H", "Instruction CV_MULURN_H detected successfully", UVM_MEDIUM);
					if (ls3 != 0) begin
						reg_file[rd] = (({{16{1'b0}}, reg_file[rs1][15:0]} * {{16{1'b0}}, reg_file[rs2][15:0]}) + (1 << (ls3-1))) >> ls3;
					end else begin
						reg_file[rd] = ({{16{1'b0}}, reg_file[rs1][15:0]} * {{16{1'b0}}, reg_file[rs2][15:0]}) >> ls3;
					end
				end else if (csr_reg_file[12'h0A0] == 1) begin
					`uvm_info("CV_MULURN_B", "Instruction CV_MULURN_B detected successfully", UVM_MEDIUM);
					if (ls3 != 0) begin
						for (int i = 0; i < 2; i++) begin
							reg_mac_mul_prov = (({{24{1'b0}}, reg_file[rs1][(i*8)+:8]} * {{24{1'b0}}, reg_file[rs2][(i*8)+:8]}) + (1 << (ls3-1)));
							reg_file[rd][(i*16)+:16] = reg_mac_mul_prov >> ls3;
						end
					end else begin
						for (int i = 0; i < 2; i++) begin
							reg_mac_mul_prov = ({{24{1'b0}}, reg_file[rs1][(i*8)+:8]} * {{24{1'b0}}, reg_file[rs2][(i*8)+:8]});
							reg_file[rd][(i*16)+:16] = reg_mac_mul_prov >> ls3;
						end
					end
				end

            end

            CV_OR : begin

                `uvm_info("CV_OR", "Instruction CV_OR detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				if (csr_reg_file[12'h0A0] == 2) begin
					`uvm_info("CV_OR_H", "Instruction CV_OR_H detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 2; i++) begin
						reg_file[rd][(i*16)+:16] = reg_file[rs1][(i*16)+:16] | reg_file[rs2][(i*16)+:16];
					end
				end else if (csr_reg_file[12'h0A0] == 1) begin
					`uvm_info("CV_OR_B", "Instruction CV_OR_B detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 4; i++) begin
						reg_file[rd][(i*8)+:8] = reg_file[rs1][(i*8)+:8] | reg_file[rs2][(i*8)+:8];
					end
				end

            end

            CV_OR_SC : begin

                `uvm_info("CV_OR_SC", "Instruction CV_OR_SC detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				if (csr_reg_file[12'h0A0] == 2) begin
					`uvm_info("CV_OR_SC_H", "Instruction CV_OR_SC_H detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 2; i++) begin
						reg_file[rd][(i*16)+:16] = reg_file[rs1][(i*16)+:16] | reg_file[rs2][15:0];
					end
				end else if (csr_reg_file[12'h0A0] == 1) begin
					`uvm_info("CV_OR_SC_B", "Instruction CV_OR_SC_B detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 4; i++) begin
						reg_file[rd][(i*8)+:8] = reg_file[rs1][(i*8)+:8] | reg_file[rs2][7:0];
					end
				end

            end

            CV_OR_SCI : begin

                `uvm_info("CV_OR_SCI", "Instruction CV_OR_SCI detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                imm6 = instr[25:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				imm6_ext = {{27{imm6[4]}}, imm6[3:0], imm6[5]};
				if (csr_reg_file[12'h0A0] == 2) begin
					`uvm_info("CV_OR_SCI_H", "Instruction CV_OR_SCI_H detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 2; i++) begin
						reg_file[rd][(i*16)+:16] = reg_file[rs1][(i*16)+:16] | imm6_ext[15:0];
					end
				end else if (csr_reg_file[12'h0A0] == 1) begin
					`uvm_info("CV_OR_SCI_B", "Instruction CV_OR_SCI_B detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 4; i++) begin
						reg_file[rd][(i*8)+:8] = reg_file[rs1][(i*8)+:8] | imm6_ext[7:0];
					end
				end

            end

            CV_SB_RIPI : begin

                `uvm_info("CV_SB_RIPI", "Instruction CV_SB_RIPI detected successfully", UVM_MEDIUM)
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                imm12hi = instr[31:25];
                imm12lo = instr[11:7];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				imm12_ext = {{20{imm12hi[6]}}, imm12hi, imm12lo};
				mem[reg_file[rs1]] = reg_file[rs2][7:0];
				reg_file[rs1] += imm12_ext;

            end

            CV_SB_RR : begin

                `uvm_info("CV_SB_RR", "Instruction CV_SB_RR detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				mem[reg_file[rs1] + reg_file[rd]] = reg_file[rs2][7:0];
				rd = 0;

            end

            CV_SB_RRPI : begin

                `uvm_info("CV_SB_RRPI", "Instruction CV_SB_RRPI detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				mem[reg_file[rs1]] = reg_file[rs2][7:0];
				reg_file[rs1] += reg_file[rd];
				rd = 0;

            end

            CV_SDOTSP : begin

                `uvm_info("CV_SDOTSP", "Instruction CV_SDOTSP detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				reg_result = 0;
				if (csr_reg_file[12'h0A0] == 2) begin
					`uvm_info("CV_SDOTSP_H", "Instruction CV_SDOTSP_H detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 2; i++) begin
						reg_result += $signed({{16{reg_file[rs1][(i*16)+15]}}, reg_file[rs1][(i*16)+:16]}) * $signed({{16{reg_file[rs2][(i*16)+15]}}, reg_file[rs2][(i*16)+:16]});
					end
					reg_file[rd] = $signed(reg_file[rd]) + $signed(reg_result);
				end else if (csr_reg_file[12'h0A0] == 1) begin
					`uvm_info("CV_SDOTSP_B", "Instruction CV_SDOTSP_B detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 4; i++) begin
						reg_result += $signed({{24{reg_file[rs1][(i*8)+7]}}, reg_file[rs1][(i*8)+:8]}) * $signed({{24{reg_file[rs2][(i*8)+7]}}, reg_file[rs2][(i*8)+:8]});
					end
					reg_file[rd] = $signed(reg_file[rd]) + $signed(reg_result);
				end else if (csr_reg_file[12'h0A0] == 6) begin
					`uvm_info("CV_SDOTSP_MX", "Instruction CV_SDOTSP_MX detected successfully", UVM_MEDIUM);
					if (iteration_mx == 0) begin
						for (int i = 0; i < 2; i++) begin
							reg_result += $signed({{16{reg_file[rs1][(i*16)+15]}}, reg_file[rs1][(i*16)+:16]}) * $signed({{24{reg_file[rs2][(i*8)+7]}}, reg_file[rs2][(i*8)+:8]});
						end
						reg_file[rd] = reg_file[rd] + reg_result;
					end else begin
						for (int i = 0; i < 2; i++) begin
							reg_result += $signed({{16{reg_file[rs1][(i*16)+15]}}, reg_file[rs1][(i*16)+:16]}) * $signed({{24{reg_file[rs2][((i+2)*8)+7]}}, reg_file[rs2][((i+2)*8)+:8]});
						end
						reg_file[rd] = reg_file[rd] + reg_result;
					end
					iteration_mx = ~iteration_mx;
				end

            end

            CV_SDOTSP_SC : begin

                `uvm_info("CV_SDOTSP_SC", "Instruction CV_SDOTSP_SC detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				reg_result = 0;
				if (csr_reg_file[12'h0A0] == 2) begin
					`uvm_info("CV_SDOTSP_SC_H", "Instruction CV_SDOTSP_SC_H detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 2; i++) begin
						reg_result += $signed({{16{reg_file[rs1][(i*16)+15]}}, reg_file[rs1][(i*16)+:16]}) * $signed({{16{reg_file[rs2][15]}}, reg_file[rs2][15:0]});
					end
					reg_file[rd] = $signed(reg_file[rd]) + $signed(reg_result);
				end else if (csr_reg_file[12'h0A0] == 1) begin
					`uvm_info("CV_SDOTSP_SC_B", "Instruction CV_SDOTSP_SC_B detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 4; i++) begin
						reg_result += $signed({{24{reg_file[rs1][(i*8)+7]}}, reg_file[rs1][(i*8)+:8]}) * $signed({{24{reg_file[rs2][7]}}, reg_file[rs2][7:0]});
					end
					reg_file[rd] = $signed(reg_file[rd]) + $signed(reg_result);
				end else if (csr_reg_file[12'h0A0] == 6) begin
					`uvm_info("CV_SDOTSP_SC_MX", "Instruction CV_SDOTSP_SC_MX detected successfully", UVM_MEDIUM);
					if (iteration_mx == 0) begin
						for (int i = 0; i < 2; i++) begin
							reg_result += $signed({{16{reg_file[rs1][(i*16)+15]}}, reg_file[rs1][(i*16)+:16]}) * $signed({{24{reg_file[rs2][7]}}, reg_file[rs2][7:0]});
						end
						reg_file[rd] = reg_file[rd] + reg_result;
					end else begin
						for (int i = 0; i < 2; i++) begin
							reg_result += $signed({{16{reg_file[rs1][(i*16)+15]}}, reg_file[rs1][(i*16)+:16]}) * $signed({{24{reg_file[rs2][7]}}, reg_file[rs2][7:0]});
						end
						reg_file[rd] = reg_file[rd] + reg_result;
					end
					iteration_mx = ~iteration_mx;
				end

            end

            CV_SDOTSP_SCI : begin

                `uvm_info("CV_SDOTSP_SCI", "Instruction CV_SDOTSP_SCI detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                imm6 = instr[25:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				imm6_ext = {{27{imm6[4]}}, imm6[3:0], imm6[5]};
				reg_result = 0;
				if (csr_reg_file[12'h0A0] == 2) begin
					`uvm_info("CV_SDOTSP_SCI_H", "Instruction CV_SDOTSP_SCI_H detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 2; i++) begin
						reg_result += $signed({{16{reg_file[rs1][(i*16)+15]}}, reg_file[rs1][(i*16)+:16]}) * $signed({{16{imm6_ext[15]}}, imm6_ext[15:0]});
					end
					reg_file[rd] = $signed(reg_file[rd]) + $signed(reg_result);
				end else if (csr_reg_file[12'h0A0] == 1) begin
					`uvm_info("CV_SDOTSP_SCI_B", "Instruction CV_SDOTSP_SCI_B detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 4; i++) begin
						reg_result += $signed({{24{reg_file[rs1][(i*8)+7]}}, reg_file[rs1][(i*8)+:8]}) * $signed({{24{imm6_ext[7]}}, imm6_ext[7:0]});
					end
					reg_file[rd] = $signed(reg_file[rd]) + $signed(reg_result);
				end else if (csr_reg_file[12'h0A0] == 6) begin
					`uvm_info("CV_SDOTSP_SCI_MX", "Instruction CV_SDOTSP_SCI_MX detected successfully", UVM_MEDIUM);
					if (iteration_mx == 0) begin
						for (int i = 0; i < 2; i++) begin
							reg_result += $signed({{16{reg_file[rs1][(i*16)+15]}}, reg_file[rs1][(i*16)+:16]}) * $signed({{24{imm6_ext[7]}}, imm6_ext[7:0]});
						end
						reg_file[rd] = reg_file[rd] + reg_result;
					end else begin
						for (int i = 0; i < 2; i++) begin
							reg_result += $signed({{16{reg_file[rs1][(i*16)+15]}}, reg_file[rs1][(i*16)+:16]}) * $signed({{24{imm6_ext[7]}}, imm6_ext[7:0]});
						end
						reg_file[rd] = reg_file[rd] + reg_result;
					end
					iteration_mx = ~iteration_mx;
				end

            end

            CV_SDOTUP : begin

                `uvm_info("CV_SDOTUP", "Instruction CV_SDOTUP detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				reg_result = 0;
				if (csr_reg_file[12'h0A0] == 2) begin
					`uvm_info("CV_SDOTUP_H", "Instruction CV_SDOTUP_H detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 2; i++) begin
						reg_result += {{16{1'b0}}, reg_file[rs1][(i*16)+:16]} * {{16{1'b0}}, reg_file[rs2][(i*16)+:16]};
					end
					reg_file[rd] = reg_file[rd] + reg_result;
				end else if (csr_reg_file[12'h0A0] == 1) begin
					`uvm_info("CV_SDOTUP_B", "Instruction CV_SDOTUP_B detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 4; i++) begin
						reg_result += {{24{1'b0}}, reg_file[rs1][(i*8)+:8]} * {{24{1'b0}}, reg_file[rs2][(i*8)+:8]};
					end
					reg_file[rd] = reg_file[rd] + reg_result;
				end else if (csr_reg_file[12'h0A0] == 6) begin
					`uvm_info("CV_SDOTUP_MX", "Instruction CV_SDOTUP_MX detected successfully", UVM_MEDIUM);
					if (iteration_mx == 0) begin
						for (int i = 0; i < 2; i++) begin
							reg_result += {{16{1'b0}}, reg_file[rs1][(i*16)+:16]} * {{24{1'b0}}, reg_file[rs2][(i*8)+:8]};
						end
						reg_file[rd] = reg_file[rd] + reg_result;
					end else begin
						for (int i = 0; i < 2; i++) begin
							reg_result += {{16{1'b0}}, reg_file[rs1][(i*16)+:16]} * {{24{1'b0}}, reg_file[rs2][((i+2)*8)+:8]};
						end
						reg_file[rd] = reg_file[rd] + reg_result;
					end
					iteration_mx = ~iteration_mx;
				end

            end

            CV_SDOTUP_SC : begin

                `uvm_info("CV_SDOTUP_SC", "Instruction CV_SDOTUP_SC detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				reg_result = 0;
				if (csr_reg_file[12'h0A0] == 2) begin
					`uvm_info("CV_SDOTUP_SC_H", "Instruction CV_SDOTUP_SC_H detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 2; i++) begin
						reg_result += {{16{1'b0}}, reg_file[rs1][(i*16)+:16]} * {{16{1'b0}}, reg_file[rs2][15:0]};
					end
					reg_file[rd] = reg_file[rd] + reg_result;
				end else if (csr_reg_file[12'h0A0] == 1) begin
					`uvm_info("CV_SDOTUP_SC_B", "Instruction CV_SDOTUP_SC_B detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 4; i++) begin
						reg_result += {{24{1'b0}}, reg_file[rs1][(i*8)+:8]} * {{24{1'b0}}, reg_file[rs2][7:0]};
					end
					reg_file[rd] = reg_file[rd] + reg_result;
				end else if (csr_reg_file[12'h0A0] == 6) begin
					`uvm_info("CV_SDOTUP_SC_MX", "Instruction CV_SDOTUP_SC_MX detected successfully", UVM_MEDIUM);
					if (iteration_mx == 0) begin
						for (int i = 0; i < 2; i++) begin
							reg_result += {{16{1'b0}}, reg_file[rs1][(i*16)+:16]} * {{24{1'b0}}, reg_file[rs2][7:0]};
						end
						reg_file[rd] = reg_file[rd] + reg_result;
					end else begin
						for (int i = 0; i < 2; i++) begin
							reg_result += {{16{1'b0}}, reg_file[rs1][(i*16)+:16]} * {{24{1'b0}}, reg_file[rs2][7:0]};
						end
						reg_file[rd] = reg_file[rd] + reg_result;
					end
					iteration_mx = ~iteration_mx;
				end

            end

            CV_SDOTUP_SCI : begin

                `uvm_info("CV_SDOTUP_SCI", "Instruction CV_SDOTUP_SCI detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                imm6 = instr[25:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				imm6_ext = {{27{imm6[4]}}, imm6[3:0], imm6[5]};
				reg_result = 0;
				if (csr_reg_file[12'h0A0] == 2) begin
					`uvm_info("CV_SDOTUP_SCI_H", "Instruction CV_SDOTUP_SCI_H detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 2; i++) begin
						reg_result += {{16{1'b0}}, reg_file[rs1][(i*16)+:16]} * {{16{1'b0}}, imm6_ext[15:0]};
					end
					reg_file[rd] = reg_file[rd] + reg_result;
				end else if (csr_reg_file[12'h0A0] == 1) begin
					`uvm_info("CV_SDOTUP_SCI_B", "Instruction CV_SDOTUP_SCI_B detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 4; i++) begin
						reg_result += {{24{1'b0}}, reg_file[rs1][(i*8)+:8]} * {{24{1'b0}}, imm6_ext[7:0]};
					end
					reg_file[rd] = reg_file[rd] + reg_result;
				end else if (csr_reg_file[12'h0A0] == 6) begin
					`uvm_info("CV_SDOTUP_SCI_MX", "Instruction CV_SDOTUP_SCI_MX detected successfully", UVM_MEDIUM);
					if (iteration_mx == 0) begin
						for (int i = 0; i < 2; i++) begin
							reg_result += {{16{1'b0}}, reg_file[rs1][(i*16)+:16]} * {{24{1'b0}}, imm6_ext[7:0]};
						end
						reg_file[rd] = reg_file[rd] + reg_result;
					end else begin
						for (int i = 0; i < 2; i++) begin
							reg_result += {{16{1'b0}}, reg_file[rs1][(i*16)+:16]} * {{24{1'b0}}, imm6_ext[7:0]};
						end
						reg_file[rd] = reg_file[rd] + reg_result;
					end
					iteration_mx = ~iteration_mx;
				end

            end

            CV_SDOTUSP : begin

                `uvm_info("CV_SDOTUSP", "Instruction CV_SDOTUSP detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				reg_result = 0;
				if (csr_reg_file[12'h0A0] == 2) begin
					`uvm_info("CV_SDOTUSP_H", "Instruction CV_SDOTUSP_H detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 2; i++) begin
						reg_result += {{16{1'b0}}, reg_file[rs1][(i*16)+:16]} * $signed({{16{reg_file[rs2][(i*16)+15]}}, reg_file[rs2][(i*16)+:16]});
					end
					reg_file[rd] = reg_file[rd] + $signed(reg_result);
				end else if (csr_reg_file[12'h0A0] == 1) begin
					`uvm_info("CV_SDOTUSP_B", "Instruction CV_SDOTUSP_B detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 4; i++) begin
						reg_result += {{24{1'b0}}, reg_file[rs1][(i*8)+:8]} * $signed({{24{reg_file[rs2][(i*8)+7]}}, reg_file[rs2][(i*8)+:8]});
					end
					reg_file[rd] = reg_file[rd] + $signed(reg_result);
				end else if (csr_reg_file[12'h0A0] == 6) begin
					`uvm_info("CV_SDOTUSP_MX", "Instruction CV_SDOTUSP_MX detected successfully", UVM_MEDIUM);
					if (iteration_mx == 0) begin
						for (int i = 0; i < 2; i++) begin
							reg_result += {{16{1'b0}}, reg_file[rs1][(i*16)+:16]} * {{24{reg_file[rs2][(i*8)+7]}}, reg_file[rs2][(i*8)+:8]};
						end
						reg_file[rd] = reg_file[rd] + reg_result;
					end else begin
						for (int i = 0; i < 2; i++) begin
							reg_result += {{16{1'b0}}, reg_file[rs1][(i*16)+:16]} * {{24{reg_file[rs2][((i+2)*8)+7]}}, reg_file[rs2][((i+2)*8)+:8]};
						end
						reg_file[rd] = reg_file[rd] + reg_result;
					end
					iteration_mx = ~iteration_mx;
				end

            end

            CV_SDOTUSP_SC : begin

                `uvm_info("CV_SDOTUSP_SC", "Instruction CV_SDOTUSP_SC detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				reg_result = 0;
				if (csr_reg_file[12'h0A0] == 2) begin
					`uvm_info("CV_SDOTUSP_SC_H", "Instruction CV_SDOTUSP_SC_H detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 2; i++) begin
						reg_result += {{16{1'b0}}, reg_file[rs1][(i*16)+:16]} * $signed({{16{reg_file[rs2][15]}}, reg_file[rs2][15:0]});
					end
					reg_file[rd] = reg_file[rd] + $signed(reg_result);
				end else if (csr_reg_file[12'h0A0] == 1) begin
					`uvm_info("CV_SDOTUSP_SC_B", "Instruction CV_SDOTUSP_SC_B detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 4; i++) begin
						reg_result += {{24{1'b0}}, reg_file[rs1][(i*8)+:8]} * $signed({{24{reg_file[rs2][7]}}, reg_file[rs2][7:0]});
					end
					reg_file[rd] = reg_file[rd] + $signed(reg_result);
				end else if (csr_reg_file[12'h0A0] == 6) begin
					`uvm_info("CV_SDOTUSP_SC_MX", "Instruction CV_SDOTUSP_SC_MX detected successfully", UVM_MEDIUM);
					if (iteration_mx == 0) begin
						for (int i = 0; i < 2; i++) begin
							reg_result += {{16{1'b0}}, reg_file[rs1][(i*16)+:16]} * {{24{reg_file[rs2][7]}}, reg_file[rs2][7:0]};
						end
						reg_file[rd] = reg_file[rd] + reg_result;
					end else begin
						for (int i = 0; i < 2; i++) begin
							reg_result += {{16{1'b0}}, reg_file[rs1][(i*16)+:16]} * {{24{reg_file[rs2][7]}}, reg_file[rs2][7:0]};
						end
						reg_file[rd] = reg_file[rd] + reg_result;
					end
					iteration_mx = ~iteration_mx;
				end

            end

            CV_SDOTUSP_SCI : begin

                `uvm_info("CV_SDOTUSP_SCI", "Instruction CV_SDOTUSP_SCI detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                imm6 = instr[25:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				imm6_ext = {{27{imm6[4]}}, imm6[3:0], imm6[5]};
				reg_result = 0;
				if (csr_reg_file[12'h0A0] == 2) begin
					`uvm_info("CV_SDOTUSP_SCI_H", "Instruction CV_SDOTUSP_SCI_H detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 2; i++) begin
						reg_result += {{16{1'b0}}, reg_file[rs1][(i*8)+:16]} * $signed({{16{imm6_ext[15]}}, imm6_ext[15:0]});
					end
					reg_file[rd] = reg_file[rd] + $signed(reg_result);
				end else if (csr_reg_file[12'h0A0] == 1) begin
					`uvm_info("CV_SDOTUSP_SCI_B", "Instruction CV_SDOTUSP_SCI_B detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 4; i++) begin
						reg_result += {{24{1'b0}}, reg_file[rs1][(i*8)+:8]} * $signed({{24{imm6_ext[7]}}, imm6_ext[7:0]});
					end
					reg_file[rd] = reg_file[rd] + $signed(reg_result);
				end else if (csr_reg_file[12'h0A0] == 6) begin
					`uvm_info("CV_SDOTUSP_SCI_MX", "Instruction CV_SDOTUSP_SCI_MX detected successfully", UVM_MEDIUM);
					if (iteration_mx == 0) begin
						for (int i = 0; i < 2; i++) begin
							reg_result += {{16{1'b0}}, reg_file[rs1][(i*16)+:16]} * {{24{imm6_ext[7]}}, imm6_ext[7:0]};
						end
						reg_file[rd] = reg_file[rd] + reg_result;
					end else begin
						for (int i = 0; i < 2; i++) begin
							reg_result += {{16{1'b0}}, reg_file[rs1][(i*16)+:16]} * {{24{imm6_ext[7]}}, imm6_ext[7:0]};
						end
						reg_file[rd] = reg_file[rd] + reg_result;
					end
					iteration_mx = ~iteration_mx;
				end

            end

            CV_SH_RIPI : begin

                `uvm_info("CV_SH_RIPI", "Instruction CV_SH_RIPI detected successfully", UVM_MEDIUM)
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                imm12hi = instr[31:25];
                imm12lo = instr[11:7];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				imm12_ext = {{20{imm12hi[6]}}, imm12hi, imm12lo};
				mem[reg_file[rs1]] = reg_file[rs2][7:0];
				mem[reg_file[rs1] + 1] = reg_file[rs2][15:8];
				reg_file[rs1] += imm12_ext;

            end

            CV_SH_RR : begin

                `uvm_info("CV_SH_RR", "Instruction CV_SH_RR detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				mem[reg_file[rs1] + reg_file[rd]] = reg_file[rs2][7:0];
				mem[reg_file[rs1] + reg_file[rd] + 1] = reg_file[rs2][15:8];
				rd = 0;

            end

            CV_SH_RRPI : begin

                `uvm_info("CV_SH_RRPI", "Instruction CV_SH_RRPI detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				mem[reg_file[rs1]] = reg_file[rs2][7:0];
				mem[reg_file[rs1] + 1] = reg_file[rs2][15:8];
				reg_file[rs1] += reg_file[rd];
				rd = 0;

            end

            CV_SLE : begin

                `uvm_info("CV_SLE", "Instruction CV_SLE detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				if ($signed(reg_file[rs1]) <= $signed(reg_file[rs2])) begin
					reg_file[rd] = 1;
				end else begin
					reg_file[rd] = 0;
				end

            end

            CV_SLEU : begin

                `uvm_info("CV_SLEU", "Instruction CV_SLEU detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				if (reg_file[rs1] <= reg_file[rs2]) begin
					reg_file[rd] = 1;
				end else begin
					reg_file[rd] = 0;
				end

            end

            CV_SLL : begin

                `uvm_info("CV_SLL", "Instruction CV_SLL detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				if (csr_reg_file[12'h0A0] == 2) begin
					`uvm_info("CV_SLL_H", "Instruction CV_SLL_H detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 2; i++) begin
						reg_file[rd][(i*16)+:16] = reg_file[rs1][(i*16)+:16] << (reg_file[rs2][(i*16)+:16] & 16'h000F);
					end
				end else if (csr_reg_file[12'h0A0] == 1) begin
					`uvm_info("CV_SLL_B", "Instruction CV_SLL_B detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 4; i++) begin
						reg_file[rd][(i*8)+:8] = reg_file[rs1][(i*8)+:8] << (reg_file[rs2][(i*8)+:8] & 8'h07);
					end
				end

            end

            CV_SLL_SC : begin

                `uvm_info("CV_SLL_SC", "Instruction CV_SLL_SC detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				if (csr_reg_file[12'h0A0] == 2) begin
					`uvm_info("CV_SLL_SC_H", "Instruction CV_SLL_SC_H detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 2; i++) begin
						reg_file[rd][(i*16)+:16] = reg_file[rs1][(i*16)+:16] << (reg_file[rs2][15:0] & 16'h000F);
					end
				end else if (csr_reg_file[12'h0A0] == 1) begin
					`uvm_info("CV_SLL_SC_B", "Instruction CV_SLL_SC_B detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 4; i++) begin
						reg_file[rd][(i*8)+:8] = reg_file[rs1][(i*8)+:8] << (reg_file[rs2][7:0] & 8'h07);
					end
				end

            end

            CV_SLL_SCI : begin

                `uvm_info("CV_SLL_SCI", "Instruction CV_SLL_SCI detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                imm6 = instr[25:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				imm6_ext = {26'b0, imm6[4], imm6[3:0], imm6[5]};
				if (csr_reg_file[12'h0A0] == 2) begin
					`uvm_info("CV_SLL_SCI_H", "Instruction CV_SLL_SCI_H detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 2; i++) begin
						reg_file[rd][(i*16)+:16] = reg_file[rs1][(i*16)+:16] << (imm6_ext[15:0] & 16'h000F);
					end
				end else if (csr_reg_file[12'h0A0] == 1) begin
					`uvm_info("CV_SLL_SCI_B", "Instruction CV_SLL_SCI_B detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 4; i++) begin
						reg_file[rd][(i*8)+:8] = reg_file[rs1][(i*8)+:8] << (imm6_ext[7:0] & 8'h07);
					end
				end

            end

            CV_SRA : begin

                `uvm_info("CV_SRA", "Instruction CV_SRA detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				if (csr_reg_file[12'h0A0] == 2) begin
					`uvm_info("CV_SRA_H", "Instruction CV_SRA_H detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 2; i++) begin
						reg_file[rd][(i*16)+:16] = $signed(reg_file[rs1][(i*16)+:16]) >>> (reg_file[rs2][(i*16)+:16] & 16'h000F);
					end
				end else if (csr_reg_file[12'h0A0] == 1) begin
					`uvm_info("CV_SRA_B", "Instruction CV_SRA_B detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 4; i++) begin
						reg_file[rd][(i*8)+:8] = $signed(reg_file[rs1][(i*8)+:8]) >>> (reg_file[rs2][(i*8)+:8] & 8'h07);
					end
				end

            end

            CV_SRA_SC : begin

                `uvm_info("CV_SRA_SC", "Instruction CV_SRA_SC detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				if (csr_reg_file[12'h0A0] == 2) begin
					`uvm_info("CV_SRA_SC_H", "Instruction CV_SRA_SC_H detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 2; i++) begin
						reg_file[rd][(i*16)+:16] = $signed(reg_file[rs1][(i*16)+:16]) >>> (reg_file[rs2][15:0] & 16'h000F);
					end
				end else if (csr_reg_file[12'h0A0] == 1) begin
					`uvm_info("CV_SRA_SC_B", "Instruction CV_SRA_SC_B detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 4; i++) begin
						reg_file[rd][(i*8)+:8] = $signed(reg_file[rs1][(i*8)+:8]) >>> (reg_file[rs2][7:0] & 8'h07);
					end
				end

            end

            CV_SRA_SCI : begin

                `uvm_info("CV_SRA_SCI", "Instruction CV_SRA_SCI detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                imm6 = instr[25:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				imm6_ext = {26'b0, imm6[4], imm6[3:0], imm6[5]};
				if (csr_reg_file[12'h0A0] == 2) begin
					`uvm_info("CV_SRA_SCI_H", "Instruction CV_SRA_SCI_H detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 2; i++) begin
						reg_file[rd][(i*16)+:16] = $signed(reg_file[rs1][(i*16)+:16]) >>> (imm6_ext[15:0] & 16'h000F);
					end
				end else if (csr_reg_file[12'h0A0] == 1) begin
					`uvm_info("CV_SRA_SCI_B", "Instruction CV_SRA_SCI_B detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 4; i++) begin
						reg_file[rd][(i*8)+:8] = $signed(reg_file[rs1][(i*8)+:8]) >>> (imm6_ext[7:0] & 8'h07);
					end
				end

            end

            CV_SRL : begin

                `uvm_info("CV_SRL", "Instruction CV_SRL detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				if (csr_reg_file[12'h0A0] == 2) begin
					`uvm_info("CV_SRL_H", "Instruction CV_SRL_H detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 2; i++) begin
						reg_file[rd][(i*16)+:16] = reg_file[rs1][(i*16)+:16] >> (reg_file[rs2][(i*16)+:16] & 16'h000F);
					end
				end else if (csr_reg_file[12'h0A0] == 1) begin
					`uvm_info("CV_SRL_B", "Instruction CV_SRL_B detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 4; i++) begin
						reg_file[rd][(i*8)+:8] = reg_file[rs1][(i*8)+:8] >> (reg_file[rs2][(i*8)+:8] & 8'h07);
					end
				end

            end

            CV_SRL_SC : begin

                `uvm_info("CV_SRL_SC", "Instruction CV_SRL_SC detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				if (csr_reg_file[12'h0A0] == 2) begin
					`uvm_info("CV_SRL_SC_H", "Instruction CV_SRL_SC_H detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 2; i++) begin
						reg_file[rd][(i*16)+:16] = reg_file[rs1][(i*16)+:16] >> (reg_file[rs2][15:0] & 16'h000F);
					end
				end else if (csr_reg_file[12'h0A0] == 1) begin
					`uvm_info("CV_SRL_SC_B", "Instruction CV_SRL_SC_B detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 4; i++) begin
						reg_file[rd][(i*8)+:8] = reg_file[rs1][(i*8)+:8] >> (reg_file[rs2][7:0] & 8'h07);
					end
				end

            end

            CV_SRL_SCI : begin

                `uvm_info("CV_SRL_SCI", "Instruction CV_SRL_SCI detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                imm6 = instr[25:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				imm6_ext = {26'b0, imm6[4], imm6[3:0], imm6[5]};
				if (csr_reg_file[12'h0A0] == 2) begin
					`uvm_info("CV_SRL_SCI_H", "Instruction CV_SRL_SCI_H detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 2; i++) begin
						reg_file[rd][(i*16)+:16] = reg_file[rs1][(i*16)+:16] >> (imm6_ext[15:0] & 16'h000F);
					end
				end else if (csr_reg_file[12'h0A0] == 1) begin
					`uvm_info("CV_SRL_SCI_B", "Instruction CV_SRL_SCI_B detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 4; i++) begin
						reg_file[rd][(i*8)+:8] = reg_file[rs1][(i*8)+:8] >> (imm6_ext[7:0] & 8'h07);
					end
				end

            end

            CV_SUB : begin

                `uvm_info("CV_SUB", "Instruction CV_SUB detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				if (csr_reg_file[12'h0A0] == 2) begin
					`uvm_info("CV_SUB_H", "Instruction CV_SUB_H detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 2; i++) begin
						reg_file[rd][(i*16)+:16] = (reg_file[rs1][(i*16)+:16] - reg_file[rs2][(i*16)+:16]) & 16'hFFFF;
					end
				end else if (csr_reg_file[12'h0A0] == 1) begin
					`uvm_info("CV_SUB_B", "Instruction CV_SUB_B detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 4; i++) begin
						reg_file[rd][(i*8)+:8] = (reg_file[rs1][(i*8)+:8] - reg_file[rs2][(i*8)+:8]) & 8'hFF;
					end
				end

            end

            CV_SUBN : begin

                `uvm_info("CV_SUBN", "Instruction CV_SUBN detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                ls3 = instr[29:25];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				reg_file[rd] = ($signed(reg_file[rs1]) - $signed(reg_file[rs2])) >>> ls3;

            end

            CV_SUBNR : begin

                `uvm_info("CV_SUBNR", "Instruction CV_SUBNR detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				reg_file[rd] = ($signed(reg_file[rd]) - $signed(reg_file[rs1])) >>> reg_file[rs2][4:0];

            end

            CV_SUBRN : begin

                `uvm_info("CV_SUBRN", "Instruction CV_SUBRN detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                ls3 = instr[29:25];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				if (ls3 != 0) begin
					reg_file[rd] = ($signed(reg_file[rs1]) - $signed(reg_file[rs2]) + $signed(1 << (ls3-1))) >>> ls3;
				end else begin
					reg_file[rd] = ($signed(reg_file[rs1]) - $signed(reg_file[rs2])) >>> ls3;
				end

            end

            CV_SUBRNR : begin

                `uvm_info("CV_SUBRNR", "Instruction CV_SUBRNR detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				if (reg_file[rs2] != 0) begin
					reg_file[rd] = ($signed(reg_file[rd]) - $signed(reg_file[rs1]) + $signed(1 << (reg_file[rs2][4:0]-1))) >>> reg_file[rs2][4:0];
				end else begin
					reg_file[rd] = ($signed(reg_file[rd]) - $signed(reg_file[rs1])) >>> reg_file[rs2][4:0];
				end

            end

            CV_SUB_SC : begin

                `uvm_info("CV_SUB_SC", "Instruction CV_SUB_SC detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				if (csr_reg_file[12'h0A0] == 2) begin
					`uvm_info("CV_SUB_SC_H", "Instruction CV_SUB_SC_H detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 2; i++) begin
						reg_file[rd][(i*16)+:16] = (reg_file[rs1][(i*16)+:16] - reg_file[rs2][15:0]) & 16'hFFFF;
					end
				end else if (csr_reg_file[12'h0A0] == 1) begin
					`uvm_info("CV_SUB_SC_B", "Instruction CV_SUB_SC_B detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 4; i++) begin
						reg_file[rd][(i*8)+:8] = (reg_file[rs1][(i*8)+:8] - reg_file[rs2][7:0]) & 8'hFF;
					end
				end

            end

            CV_SUB_SCI : begin

                `uvm_info("CV_SUB_SCI", "Instruction CV_SUB_SCI detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                imm6 = instr[25:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				imm6_ext = {{27{imm6[4]}}, imm6[3:0], imm6[5]};
				if (csr_reg_file[12'h0A0] == 2) begin
					`uvm_info("CV_SUB_SCI_H", "Instruction CV_SUB_SCI_H detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 2; i++) begin
						reg_file[rd][(i*16)+:16] = (reg_file[rs1][(i*16)+:16] - imm6_ext[15:0]) & 16'hFFFF;
					end
				end else if (csr_reg_file[12'h0A0] == 1) begin
					`uvm_info("CV_SUB_SCI__B", "Instruction CV_SUB_SCI_B detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 4; i++) begin
						reg_file[rd][(i*8)+:8] = (reg_file[rs1][(i*8)+:8] - imm6_ext[7:0]) & 8'hFF;
					end
				end

            end

            CV_SUBUN : begin

                `uvm_info("CV_SUBUN", "Instruction CV_SUBUN detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                ls3 = instr[29:25];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				reg_file[rd] = ($unsigned(reg_file[rs1]) - $unsigned(reg_file[rs2])) >> ls3;

            end

            CV_SUBUNR : begin

                `uvm_info("CV_SUBUNR", "Instruction CV_SUBUNR detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				reg_file[rd] = ($unsigned(reg_file[rd]) - $unsigned(reg_file[rs1])) >> reg_file[rs2][4:0];

            end

            CV_SUBURN : begin

                `uvm_info("CV_SUBURN", "Instruction CV_SUBURN detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                ls3 = instr[29:25];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				if (ls3 != 0) begin
					reg_file[rd] = ($unsigned(reg_file[rs1]) - $unsigned(reg_file[rs2]) + $unsigned(1 << (ls3-1))) >> ls3;
				end else begin
					reg_file[rd] = ($unsigned(reg_file[rs1]) - $unsigned(reg_file[rs2])) >> ls3;
				end

            end

            CV_SUBURNR : begin

                `uvm_info("CV_SUBURNR", "Instruction CV_SUBURNR detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				if (reg_file[rs2] != 0) begin
					reg_file[rd] = ($unsigned(reg_file[rd]) - $unsigned(reg_file[rs1]) + $unsigned(1 << (reg_file[rs2][4:0]-1))) >> reg_file[rs2][4:0];
				end else begin
					reg_file[rd] = ($unsigned(reg_file[rd]) - $unsigned(reg_file[rs1])) >> reg_file[rs2][4:0];
				end

            end

            CV_SW_RIPI : begin

                `uvm_info("CV_SW_RIPI", "Instruction CV_SW_RIPI detected successfully", UVM_MEDIUM)
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                imm12hi = instr[31:25];
                imm12lo = instr[11:7];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				imm12_ext = {{20{imm12hi[6]}}, imm12hi, imm12lo};
				mem[reg_file[rs1]] = reg_file[rs2][7:0];
				mem[reg_file[rs1] + 1] = reg_file[rs2][15:8];
				mem[reg_file[rs1] + 2] = reg_file[rs2][23:16];
				mem[reg_file[rs1] + 3] = reg_file[rs2][31:24];
				reg_file[rs1] += imm12_ext;

            end

            CV_SW_RR : begin

                `uvm_info("CV_SW_RR", "Instruction CV_SW_RR detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				mem[reg_file[rs1] + reg_file[rd]] = reg_file[rs2][7:0];
				mem[reg_file[rs1] + reg_file[rd] + 1] = reg_file[rs2][15:8];
				mem[reg_file[rs1] + reg_file[rd] + 2] = reg_file[rs2][23:16];
				mem[reg_file[rs1] + reg_file[rd] + 3] = reg_file[rs2][31:24];
				rd = 0;

            end

            CV_SW_RRPI : begin

                `uvm_info("CV_SW_RRPI", "Instruction CV_SW_RRPI detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				mem[reg_file[rs1]] = reg_file[rs2][7:0];
				mem[reg_file[rs1] + 1] = reg_file[rs2][15:8];
				mem[reg_file[rs1] + 2] = reg_file[rs2][23:16];
				mem[reg_file[rs1] + 3] = reg_file[rs2][31:24];
				reg_file[rs1] += reg_file[rd];
				rd = 0;

            end

            CV_XOR : begin

                `uvm_info("CV_XOR", "Instruction CV_XOR detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				if (csr_reg_file[12'h0A0] == 2) begin
					`uvm_info("CV_XOR_H", "Instruction CV_XOR_H detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 2; i++) begin
						reg_file[rd][(i*16)+:16] = reg_file[rs1][(i*16)+:16] ^ reg_file[rs2][(i*16)+:16];
					end
				end else if (csr_reg_file[12'h0A0] == 1) begin
					`uvm_info("CV_XOR_B", "Instruction CV_XOR_B detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 4; i++) begin
						reg_file[rd][(i*8)+:8] = reg_file[rs1][(i*8)+:8] ^ reg_file[rs2][(i*8)+:8];
					end
				end

            end

            CV_XOR_SC : begin

                `uvm_info("CV_XOR_SC", "Instruction CV_XOR_SC detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				if (csr_reg_file[12'h0A0] == 2) begin
					`uvm_info("CV_XOR_SC_H", "Instruction CV_XOR_SC_H detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 2; i++) begin
						reg_file[rd][(i*16)+:16] = reg_file[rs1][(i*16)+:16] ^ reg_file[rs2][15:0];
					end
				end else if (csr_reg_file[12'h0A0] == 1) begin
					`uvm_info("CV_XOR_SC_B", "Instruction CV_XOR_SC_B detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 4; i++) begin
						reg_file[rd][(i*8)+:8] = reg_file[rs1][(i*8)+:8] ^ reg_file[rs2][7:0];
					end
				end

            end

            CV_XOR_SCI : begin

                `uvm_info("CV_XOR_SCI", "Instruction CV_XOR_SCI detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                imm6 = instr[25:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				imm6_ext = {{27{imm6[4]}}, imm6[3:0], imm6[5]};
				if (csr_reg_file[12'h0A0] == 2) begin
					`uvm_info("CV_XOR_SCI_H", "Instruction CV_XOR_SCI_H detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 2; i++) begin
						reg_file[rd][(i*16)+:16] = reg_file[rs1][(i*16)+:16] ^ imm6_ext[15:0];
					end
				end else if (csr_reg_file[12'h0A0] == 1) begin
					`uvm_info("CV_XOR_SCI_B", "Instruction CV_XOR_SCI_B detected successfully", UVM_MEDIUM);
					for (int i = 0; i < 4; i++) begin
						reg_file[rd][(i*8)+:8] = reg_file[rs1][(i*8)+:8] ^ imm6_ext[7:0];
					end
				end

            end

            DIV : begin

                `uvm_info("DIV", "Instruction DIV detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				if (reg_file[rs2] == 0) begin
					reg_file[rd] = 32'hFFFFFFFF;
				end else if ((reg_file[rs1] == 32'h80000000) && (reg_file[rs2] == -1)) begin
					reg_file[rd] = 32'h80000000;
				end else begin
					reg_file[rd] = $signed(reg_file[rs1]) / $signed(reg_file[rs2]);
				end

            end

            DIVU : begin

                `uvm_info("DIVU", "Instruction DIVU detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				if (reg_file[rs2] == 0) begin
					reg_file[rd] = 32'hFFFFFFFF;
				end else begin
					reg_file[rd] = reg_file[rs1] / reg_file[rs2];
				end

            end

            EBREAK : begin

                `uvm_info("EBREAK", "Instruction EBREAK detected successfully", UVM_MEDIUM)
                // ebreak

            end

            ECALL : begin

                `uvm_info("ECALL", "Instruction ECALL detected successfully", UVM_MEDIUM)
                // ecall

            end

            FENCE : begin

                `uvm_info("FENCE", "Instruction FENCE detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                fm = instr[31:28];
                pred = instr[27:24];
                succ = instr[23:20];
                // fence

            end

            JAL : begin

                `uvm_info("JAL", "Instruction JAL detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                jimm20 = instr[31:12];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				immuj = {{11{jimm20[19]}},jimm20[19], jimm20[7:0], jimm20[8], jimm20[18:9], 1'b0};
				reg_file[rd] = pc + 4;
				pc = pc + immuj;
				incr = 0;

            end

            JALR : begin

                `uvm_info("JALR", "Instruction JALR detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                imm12 = instr[31:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				reg_file[rd] = pc + 4;
				pc = (reg_file[rs1] + imm12) & ~1;
				incr = 0;

            end

            LB : begin

                `uvm_info("LB", "Instruction LB detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                imm12 = instr[31:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				imm12_ext = {{20{imm12[11]}}, imm12};
				reg_file[rd] = {{24{mem[reg_file[rs1] + imm12_ext][7]}}, mem[reg_file[rs1] + imm12_ext][7:0]};

            end

            LBU : begin

                `uvm_info("LBU", "Instruction LBU detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                imm12 = instr[31:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				imm12_ext = {{20{imm12[11]}}, imm12};
				reg_file[rd] = {24'b0, mem[reg_file[rs1] + imm12_ext][7:0]};

            end

            LH : begin

                `uvm_info("LH", "Instruction LH detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                imm12 = instr[31:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				imm12_ext = {{20{imm12[11]}}, imm12};
				reg_file[rd] = {{16{mem[reg_file[rs1] + imm12_ext + 1][7]}}, mem[reg_file[rs1] + imm12_ext + 1][7:0], mem[reg_file[rs1] + imm12_ext][7:0]};

            end

            LHU : begin

                `uvm_info("LHU", "Instruction LHU detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                imm12 = instr[31:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				imm12_ext = {{20{imm12[11]}}, imm12};
				reg_file[rd] = {16'b0, mem[reg_file[rs1] + imm12_ext + 1][7:0], mem[reg_file[rs1] + imm12_ext][7:0]};

            end

            LUI : begin

                `uvm_info("LUI", "Instruction LUI detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                imm20 = instr[31:12];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				reg_file[rd] = imm20 << 12;

            end

            LW : begin

                `uvm_info("LW", "Instruction LW detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                imm12 = instr[31:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				imm12_ext = {{20{imm12[11]}}, imm12};
				reg_file[rd] = {mem[reg_file[rs1] + imm12_ext + 3][7:0], mem[reg_file[rs1] + imm12_ext + 2][7:0], mem[reg_file[rs1] + imm12_ext + 1][7:0], mem[reg_file[rs1] + imm12_ext][7:0]};

            end

            MRET : begin

                `uvm_info("MRET", "Instruction MRET detected successfully", UVM_MEDIUM)
                // mret: return from machine mode exception
				pc = csr_reg_file[12'h341]; // mepc CSR
				incr = 0;

            end

            MUL : begin

                `uvm_info("MUL", "Instruction MUL detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				reg_mul = $signed(reg_file[rs1]) * $signed(reg_file[rs2]);
				reg_file[rd] = reg_mul[31:0];

            end

            MULH : begin

                `uvm_info("MULH", "Instruction MULH detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				reg_mul = $signed(reg_file[rs1]) * $signed(reg_file[rs2]);
				reg_file[rd] = reg_mul[63:32];

            end

            MULHSU : begin

                `uvm_info("MULHSU", "Instruction MULHSU detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				reg_mul = $signed({{32{reg_file[rs1][31]}}, reg_file[rs1]}) * {32'b0, reg_file[rs2]};
				reg_file[rd] = reg_mul[63:32];

            end

            MULHU : begin

                `uvm_info("MULHU", "Instruction MULHU detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				reg_mul = reg_file[rs1] * reg_file[rs2];
				reg_file[rd] = reg_mul[63:32];

            end

            OR : begin

                `uvm_info("OR", "Instruction OR detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				reg_file[rd] = reg_file[rs1] | reg_file[rs2];

            end

            ORI : begin

                `uvm_info("ORI", "Instruction ORI detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                imm12 = instr[31:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				imm12_ext = {{20{imm12[11]}}, imm12};
				reg_file[rd] = reg_file[rs1] | imm12_ext;

            end

            REM : begin

                `uvm_info("REM", "Instruction REM detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				if (reg_file[rs2] == 0) begin
					reg_file[rd] = reg_file[rs1];
				end else if ((reg_file[rs1] == 32'h80000000) && (reg_file[rs2] == -1)) begin
					reg_file[rd] = 0;
				end else begin
					reg_file[rd] = $signed(reg_file[rs1]) % $signed(reg_file[rs2]);
				end

            end

            REMU : begin

                `uvm_info("REMU", "Instruction REMU detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				if (reg_file[rs2] == 0) begin
					reg_file[rd] = reg_file[rs1];
				end else begin
					reg_file[rd] = reg_file[rs1] % reg_file[rs2];
				end

            end

            SB : begin

                `uvm_info("SB", "Instruction SB detected successfully", UVM_MEDIUM)
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                imm12hi = instr[31:25];
                imm12lo = instr[11:7];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				imms = {imm12hi, imm12lo};
				imms_ext = {{20{imms[11]}}, imms};
				mem[reg_file[rs1] + imms_ext][7:0] = reg_file[rs2][7:0];

            end

            SH : begin

                `uvm_info("SH", "Instruction SH detected successfully", UVM_MEDIUM)
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                imm12hi = instr[31:25];
                imm12lo = instr[11:7];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				imms = {imm12hi, imm12lo};
				imms_ext = {{20{imms[11]}}, imms};
				mem[reg_file[rs1] + imms_ext][15:0] = reg_file[rs2][7:0];
				mem[reg_file[rs1] + imms_ext + 1] = reg_file[rs2][15:8];

            end

            SLL : begin

                `uvm_info("SLL", "Instruction SLL detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				reg_file[rd] = reg_file[rs1] << reg_file[rs2][4:0];

            end

            SLLI : begin

                `uvm_info("SLLI", "Instruction SLLI detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                shamtw = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				reg_file[rd] = reg_file[rs1] << shamtw;

            end

            SLT : begin

                `uvm_info("SLT", "Instruction SLT detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				if ($signed(reg_file[rs1]) < $signed(reg_file[rs2]))
					reg_file[rd] = 1;
				else
					reg_file[rd] = 0;

            end

            SLTI : begin

                `uvm_info("SLTI", "Instruction SLTI detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                imm12 = instr[31:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				if ($signed(reg_file[rs1]) < $signed(imm12))
					reg_file[rd] = 1;
				else
					reg_file[rd] = 0;

            end

            SLTIU : begin

                `uvm_info("SLTIU", "Instruction SLTIU detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                imm12 = instr[31:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				if (reg_file[rs1] < imm12)
					reg_file[rd] = 1;
				else
					reg_file[rd] = 0;

            end

            SLTU : begin

                `uvm_info("SLTU", "Instruction SLTU detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				if (reg_file[rs1] < reg_file[rs2])
					reg_file[rd] = 1;
				else
					reg_file[rd] = 0;

            end

            SRA : begin

                `uvm_info("SRA", "Instruction SRA detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				reg_file[rd] = $signed(reg_file[rs1]) >>> reg_file[rs2][4:0];

            end

            SRAI : begin

                `uvm_info("SRAI", "Instruction SRAI detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                shamtw = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				reg_file[rd] = $signed(reg_file[rs1]) >>> shamtw;

            end

            SRL : begin

                `uvm_info("SRL", "Instruction SRL detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				reg_file[rd] = reg_file[rs1] >> reg_file[rs2][4:0];

            end

            SRLI : begin

                `uvm_info("SRLI", "Instruction SRLI detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                shamtw = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				reg_file[rd] = reg_file[rs1] >> shamtw;

            end

            SUB : begin

                `uvm_info("SUB", "Instruction SUB detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				reg_file[rd] = reg_file[rs1] - reg_file[rs2];

            end

            SW : begin

                `uvm_info("SW", "Instruction SW detected successfully", UVM_MEDIUM)
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                imm12hi = instr[31:25];
                imm12lo = instr[11:7];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				imms = {imm12hi, imm12lo};
				imms_ext = {{20{imms[11]}}, imms};
				mem[reg_file[rs1] + imms_ext] = reg_file[rs2][7:0];
				mem[reg_file[rs1] + imms_ext + 1] = reg_file[rs2][15:8];
				mem[reg_file[rs1] + imms_ext + 2] = reg_file[rs2][23:16];
				mem[reg_file[rs1] + imms_ext + 3] = reg_file[rs2][31:24];

            end

            WFI : begin

                `uvm_info("WFI", "Instruction WFI detected successfully", UVM_MEDIUM)
                // wfi: wait for interrupt (treated as no-op in this model, it also sets the end of the simulation)
				incr = 0;
				rvfi_instr_seq_item.halt = 1;

            end

            XOR : begin

                `uvm_info("XOR", "Instruction XOR detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				reg_file[rd] = reg_file[rs1] ^ reg_file[rs2];

            end

            XORI : begin

                `uvm_info("XORI", "Instruction XORI detected successfully", UVM_MEDIUM)
                rd = instr[11:7];
                rs1 = instr[19:15];
                imm12 = instr[31:20];
                reg_rs1_prev = reg_file[rs1];
				reg_rs2_prev = reg_file[rs2];
				imm12_ext = {{20{imm12[11]}}, imm12};
				reg_file[rd] = reg_file[rs1] ^ imm12_ext;

            end

            default: begin

                `uvm_error("UNKNOWN", "Unknown instruction detected")
                incr = 4;

            end


        endcase


        reg_file[0] = 32'b0;

        pc += incr;

        
        rvfi_instr_seq_item.order     = order++;
        rvfi_instr_seq_item.insn      = instr;
        rvfi_instr_seq_item.rs1_addr  = rs1;
        rvfi_instr_seq_item.rs1_rdata = reg_rs1_prev;
        rvfi_instr_seq_item.rs2_addr  = rs2;
        rvfi_instr_seq_item.rs2_rdata = reg_rs2_prev;
        rvfi_instr_seq_item.rd1_addr  = rd;
        rvfi_instr_seq_item.rd1_wdata = reg_file[rd];
        rvfi_instr_seq_item.pc_rdata  = pc_before;
        rvfi_instr_seq_item.pc_wdata  = pc;


        return rvfi_instr_seq_item;

    endfunction : decode_opcode


endclass : uvmc_rvfi_decoder_model

`endif // __uvmc_rvfi_decoder_model_SV__
