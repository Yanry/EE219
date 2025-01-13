// =======================================
// You need to finish this module
// =======================================


`include "define_rv32im.v"

module si_inst_decode #(
    parameter INST_DW   = 32,
    parameter INST_AW   = 32,
    parameter MEM_AW    = 32,
    parameter REG_DW    = 32,
    parameter REG_AW    = 5,
    parameter ALUOP_DW  = 5

) (
    input                   clk,
    input                   rst,
    // instruction
    input   [INST_DW-1:0]   inst_i,
    // regfile
    output                  rs1_en_o,
    output  [REG_AW-1:0]    rs1_addr_o,
    input   [REG_DW-1:0]    rs1_dout_i,
    output                  rs2_en_o,
    output  [REG_AW-1:0]    rs2_addr_o,
    input   [REG_DW-1:0]    rs2_dout_i,
    // alu
    output  [ALUOP_DW-1:0]  alu_opcode_o,
    output  [REG_DW-1:0]    operand_1_o,
    output  [REG_DW-1:0]    operand_2_o,
    output                  branch_en_o,
    output  [INST_AW-1:0]   branch_offset_o,
    output                  jump_en_o,
    output  [INST_AW-1:0]   jump_offset_o,
    // mem-access
    output                  mem_ren_o,
    output                  mem_wen_o,
    output  [INST_DW-1:0]   mem_din_o,
    // write-back
    output                  id_wb_en_o,
    output                  id_wb_sel_o,
    output  [REG_AW-1:0]    id_wb_addr_o 
);

localparam ALU_OP_NOP   = 5'd0 ;
localparam ALU_OP_ADD   = 5'd1 ;
localparam ALU_OP_MUL   = 5'd2 ;
localparam ALU_OP_BNE   = 5'd3 ;
localparam ALU_OP_JAL   = 5'd4 ;
localparam ALU_OP_LUI   = 5'd5 ;
localparam ALU_OP_AUIPC = 5'd6 ;
localparam ALU_OP_AND   = 5'd7 ;
localparam ALU_OP_SLL   = 5'd8 ;
localparam ALU_OP_SLTI  = 5'd9 ;
localparam ALU_OP_BLT   = 5'd10 ;


// Divide inst
wire [6:0] inst_op;
wire [4:0] inst_rd;
wire [2:0] inst_funct3;
wire [4:0] inst_rs1, inst_rs2;
wire [6:0] inst_funct7;
wire [REG_DW-1:0] operand_rs_imm ;

assign inst_op = inst_i[6:0];
assign inst_rd = inst_i[11:7];
assign inst_funct3 = inst_i[14:12];
assign inst_rs1 = inst_i[19:15];
assign inst_rs2 = inst_i[24:20];
assign inst_funct7 = inst_i[31:25];

wire [11 : 0]   imm_i ;
wire [31 : 0]   imm_u ;
wire [12 : 0]   imm_b ;
wire [20 : 0]   imm_j ;
wire [11 : 0]   imm_s ;

assign imm_i    = inst_i[31:20];
assign imm_u    = {inst_i[31:12], 12'b0};
assign imm_b    = {inst_i[31], inst_i[7], inst_i[30:25], inst_i[11:8], 1'b0};
assign imm_j    = {inst_i[31], inst_i[19:12], inst_i[20], inst_i[30:21], 1'b0};
assign imm_s    = {inst_i[31:25], inst_i[11:7]};

// operation
wire op_nop, op_add, op_addi, op_mul, op_bne, op_jal, op_jalr, op_lui;
wire op_auipc, op_and, op_sll, op_slti, op_blt, op_sw, op_lw;
assign op_add = (inst_op == `OPCODE_ADD) && (inst_funct3 == `FUNCT3_ADD) && (inst_funct7 == `FUNCT7_ADD);
assign op_addi= (inst_op == `OPCODE_ADDI) && (inst_funct3 == `FUNCT3_ADDI);
assign op_mul = (inst_op == `OPCODE_MUL) && (inst_funct3 == `FUNCT3_MUL) && (inst_funct7 == `FUNCT7_MUL);
assign op_bne = (inst_op == `OPCODE_BNE) && (inst_funct3 == `FUNCT3_BNE);
assign op_jal = (inst_op == `OPCODE_JAL);
assign op_jalr= (inst_op == `OPCODE_JALR) && (inst_funct3 == `FUNCT3_JALR);
assign op_lui = (inst_op == `OPCODE_LUI);
assign op_auipc = (inst_op == `OPCODE_AUIPC);
assign op_and = (inst_op == `OPCODE_AND) && (inst_funct3 == `FUNCT3_AND) && (inst_funct7 == `FUNCT7_AND);
assign op_sll = (inst_op == `OPCODE_SLL) && (inst_funct3 == `FUNCT3_SLL) && (inst_funct7 == `FUNCT7_SLL);
assign op_slti= (inst_op == `OPCODE_SLTI) && (inst_funct3 == `FUNCT3_SLTI);
assign op_blt = (inst_op == `OPCODE_BLT) && (inst_funct3 == `FUNCT3_BLT);
assign op_sw  = (inst_op == `OPCODE_SW ) && (inst_funct3 == `FUNCT3_SW );
assign op_lw  = (inst_op == `OPCODE_LW ) && (inst_funct3 == `FUNCT3_LW );


// Control ALU Operation
assign alu_opcode_o =   ( rst == 1'b1   ) ?   ALU_OP_NOP     :
                        ( op_mul      )   ?   ALU_OP_MUL     :
                        ( op_add      )   ?   ALU_OP_ADD     :
                        ( op_and      )   ?   ALU_OP_AND     :
                        ( op_sll      )   ?   ALU_OP_SLL     :
                        ( op_addi     )   ?   ALU_OP_ADD     :
                        ( op_slti     )   ?   ALU_OP_SLTI    :
                        ( op_lw       )   ?   ALU_OP_ADD     :
                        ( op_sw       )   ?   ALU_OP_ADD     :
                        ( op_blt      )   ?   ALU_OP_NOP     :
                        ( op_lui      )   ?   ALU_OP_ADD     :
                        ( op_jal      )   ?   ALU_OP_NOP     :
                                              ALU_OP_NOP     ;

wire op_u, op_j, op_b, op_i, op_s, op_r, op_imm;
assign op_u = op_lui || op_auipc;
assign op_j = op_jal;
assign op_i = op_jalr || op_lw || op_slti || op_addi;
assign op_b = op_blt || op_bne;
assign op_s = op_sw;
assign op_r = op_mul || op_add || op_and || op_sll;
assign op_imm = op_i || op_u || op_j;

// regfile
assign rs1_en_o = (!rst) && (op_r || op_b || op_s || op_i);
assign rs1_addr_o = (rs1_en_o)? inst_rs1: 'b0;
assign rs2_en_o = (!rst) && (op_r || op_b || op_s);
assign rs2_addr_o = (rs2_en_o)? inst_rs2: 'b0;

// Control ALU operands
assign operand_rs_imm = (op_i) ? {{(32-12){imm_i[11]}}, imm_i} :
                        (op_s) ? {{(32-12){imm_s[11]}}, imm_s} :
                        (op_b) ? {{(32-13){imm_b[12]}}, imm_b} :
                        (op_u) ? imm_u : 
                        (op_j) ? {{(32-21){imm_j[20]}}, imm_j} : 0;
assign operand_1_o = (rs1_en_o) ? rs1_dout_i : 0;
assign operand_2_o = (op_imm) ? operand_rs_imm : 
                     ( rs2_en_o & !op_sw & !op_blt) ? rs2_dout_i : 0;

// Conditional Branching blt
assign branch_en_o     = (rst != 1'b1) & (op_blt & (rs1_dout_i < rs2_dout_i));
assign branch_offset_o = operand_rs_imm;

// Unconditional Branching jal
assign jump_en_o     = (rst != 1'b1) & op_jal;
assign jump_offset_o = operand_rs_imm;

// Control Memory Access 
assign mem_ren_o  = op_lw;
assign mem_wen_o  = op_sw;
assign mem_din_o = rs2_dout_i;

// Control Write-Back
assign id_wb_en_o = op_u || op_i || op_r || op_j;
assign id_wb_sel_o = op_lw;
assign id_wb_addr_o = (id_wb_en_o)? inst_rd: 'b0;
endmodule 
