// =======================================
// You need to finish this module
// =======================================

`include "define_rv32v.v"

module v_id_2 #(
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

    output                  vmem_ren_o,
    output                  vmem_wen_o,
    output  [VMEM_AW-1:0]   vmem_addr_o,
    output  [VMEM_DW-1:0]   vmem_din_o,

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

wire op_le, op_se;
assign op_se   = (inst_op == `OPCODE_VS);
assign op_le   = (inst_op == `OPCODE_VL);

// Control ALU Operation
assign valu_opcode_o =  ( rst == 1'b1   ) ?   VALU_OP_NOP     :
                        ( op_le       )   ?   VALU_OP_NOP     :
                        ( op_se       )   ?   VALU_OP_NOP     :
                                              VALU_OP_NOP     ;

// regfile
assign rs1_en_o = (!rst) && (op_le || op_se);
assign rs1_addr_o = (rs1_en_o)? inst_vs1: 'b0;
assign vs1_en_o = 1'b0;
assign vs1_addr_o = 'b0;
assign vs2_en_o = (!rst) && (op_se);
assign vs2_addr_o = (!vs2_en_o)? 0: inst_vd;

// ALU
assign operand_v1_o = 0;
assign operand_v2_o = (vs2_en_o)? vs2_dout_i: 0;

// Mem Access
assign vmem_ren_o = op_le;
assign vmem_wen_o = op_se;
assign vmem_addr_o = rs1_dout_i;
assign vmem_din_o = vs2_dout_i;

// Write Back
assign vid_wb_en_o = op_le;
assign vid_wb_addr_o = (vid_wb_en_o)? inst_vd: 0;
endmodule

