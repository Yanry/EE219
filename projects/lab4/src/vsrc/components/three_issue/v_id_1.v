// =======================================
// You need to finish this module
// =======================================

`include "define_rv32v.v"

module v_id_1 #(
    parameter VLMAX     = 8,
    parameter VALUOP_DW = 5,
    parameter VMEM_DW   = 256,
    parameter VMEM_AW   = 32,
    parameter VREG_DW   = 256,
    parameter VREG_AW   = 5,
    parameter INST_DW   = 32,
    parameter REG_DW    = 32,
    parameter REG_AW    = 5
) (
    input                   clk,
    input                   rst,

    input   [INST_DW-1:0]   inst_i,

    output                  rs1_en_o,
    output  [REG_AW-1:0]    rs1_addr_o,
    input   [REG_DW-1:0]    rs1_dout_i,

    output                  vs1_en_o,
    output  [VREG_AW-1:0]   vs1_addr_o,
    input   [VREG_DW-1:0]   vs1_dout_i,

    output                  vs2_en_o,
    output  [VREG_AW-1:0]   vs2_addr_o,
    input   [VREG_DW-1:0]   vs2_dout_i,

    output  [VALUOP_DW-1:0] valu_opcode_o,
    output  [VREG_DW-1:0]   operand_v1_o,
    output  [VREG_DW-1:0]   operand_v2_o,

    output                  vid_wb_en_o,
    output  [VREG_AW-1:0]   vid_wb_addr_o
);

localparam VALU_OP_NOP  = 5'd0 ;
localparam VALU_OP_VADD = 5'd1 ;
localparam VALU_OP_VMUL = 5'd2 ;

// Divide inst
wire [6:0] inst_op;
wire [4:0] inst_vd;
wire [2:0] inst_funct3;
wire [4:0] inst_vs1, inst_vs2;
wire [5:0] inst_funct6;
wire inst_vm;
wire [REG_DW-1:0] inst_imm;

assign inst_op = inst_i[6:0];
assign inst_vd = inst_i[11:7];
assign inst_funct3 = inst_i[14:12];
assign inst_vs1 = inst_i[19:15];
assign inst_vs2 = inst_i[24:20];
assign inst_vm = inst_i[25];
assign inst_funct6 = inst_i[31:26];
assign inst_imm = {{(REG_DW-5){inst_vs1[4]}}, inst_vs1};

wire op_add, op_addi, op_addv, op_addx;
wire op_mul, op_muli, op_mulv, op_mulx;
wire op_vi, op_vv, op_vx;
assign op_addi = (inst_op == `OPCODE_VEC) && (inst_funct3 == `FUNCT3_IVI) && (inst_funct6 == `FUNCT6_VADD);
assign op_addv = (inst_op == `OPCODE_VEC) && (inst_funct3 == `FUNCT3_IVV) && (inst_funct6 == `FUNCT6_VADD);
assign op_addx = (inst_op == `OPCODE_VEC) && (inst_funct3 == `FUNCT3_IVX) && (inst_funct6 == `FUNCT6_VADD);
assign op_add  = op_addi || op_addv || op_addx;
assign op_muli = (inst_op == `OPCODE_VEC) && (inst_funct3 == `FUNCT3_IVI) && (inst_funct6 == `FUNCT6_VMUL);
assign op_mulv = (inst_op == `OPCODE_VEC) && (inst_funct3 == `FUNCT3_IVV) && (inst_funct6 == `FUNCT6_VMUL);
assign op_mulx = (inst_op == `OPCODE_VEC) && (inst_funct3 == `FUNCT3_IVX) && (inst_funct6 == `FUNCT6_VMUL);
assign op_mul  = op_muli || op_mulv || op_mulx;
assign op_vi   = op_addi || op_muli;
assign op_vv   = op_addv || op_mulv;
assign op_vx   = op_addx || op_mulx;

// Control ALU Operation
assign valu_opcode_o =  ( rst == 1'b1   ) ?   VALU_OP_NOP     :
                        ( op_mul      )   ?   VALU_OP_VMUL    :
                        ( op_add      )   ?   VALU_OP_VADD    :
                                              VALU_OP_NOP     ;

// regfile
assign rs1_en_o = (!rst) && (op_addx || op_mulx);
assign rs1_addr_o = (rs1_en_o)? inst_vs1: 'b0;
assign vs1_en_o = (!rst) && op_vv;
assign vs1_addr_o = (vs1_en_o)? inst_vs1: 'b0;
assign vs2_en_o = (!rst) && (op_add || op_mul);
assign vs2_addr_o = (!vs2_en_o)? 0: inst_vs2;

// ALU
assign operand_v1_o = (vs1_en_o)? vs1_dout_i: (op_vi)? {8{inst_imm}}: (op_vx)? {8{rs1_dout_i}}: 0;
assign operand_v2_o = (vs2_en_o)? vs2_dout_i: 0;

// Write Back
assign vid_wb_en_o = op_vv || op_vi || op_vx;
assign vid_wb_addr_o = (vid_wb_en_o)? inst_vd: 0;
endmodule

