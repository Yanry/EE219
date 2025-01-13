// =======================================
// You need to finish this module
// =======================================

`include "v_defines.v"

module v_inst_decode (
    input                      clk,
    input                      rst,

    input   [`VINST_BUS]       inst_i,

    output                     rs1_en_o,
    output  [`SREG_ADDR_BUS]   rs1_addr_o,
    input   [`SREG_BUS]        rs1_dout_i,

    output                     vs1_en_o,
    output  [`VREG_ADDR_BUS]   vs1_addr_o,
    input   [`VREG_BUS]        vs1_dout_i,

    output                     vs2_en_o,
    output  [`VREG_ADDR_BUS]   vs2_addr_o,
    input   [`VREG_BUS]        vs2_dout_i,

    output  [`ALU_OP_BUS]      valu_opcode_o,
    output  [`VREG_BUS]        operand_v1_o,
    output  [`VREG_BUS]        operand_v2_o,

    output                     vmem_ren_o,
    output                     vmem_wen_o,
    output  [`VMEM_ADDR_BUS]   vmem_raddr_o,
    output  [`VMEM_ADDR_BUS]   vmem_waddr_o,
    output  [`VMEM_DATA_BUS]   vmem_din_o,

    output                     vid_wb_en_o,
    output                     vid_wb_sel_o,
    output  [`VREG_ADDR_BUS]   vid_wb_addr_o
);

// Divide inst
wire [6:0] inst_op;
wire [4:0] inst_vd;
wire [2:0] inst_funct3;
wire [4:0] inst_vs1, inst_vs2;
wire [5:0] inst_funct6;
wire inst_vm;
wire [`SREG_BUS] inst_imm;

assign inst_op = inst_i[6:0];
assign inst_vd = inst_i[11:7];
assign inst_funct3 = inst_i[14:12];
assign inst_vs1 = inst_i[19:15];
assign inst_vs2 = inst_i[24:20];
assign inst_vm = inst_i[25];
assign inst_funct6 = inst_i[31:26];
assign inst_imm = {{(64-5){inst_vs1[4]}}, inst_vs1};

// Custom opcode
wire op_conv, op_conv1, op_conv2;
assign op_conv1 = (inst_op == `OPCODE_VEC) && (inst_funct3 == `FUNCT3_IVV) && (inst_funct6 == `FUNCT6_CONV1);
assign op_conv2 = (inst_op == `OPCODE_VEC) && (inst_funct3 == `FUNCT3_IVV) && (inst_funct6 == `FUNCT6_CONV2);
assign op_conv = op_conv1 || op_conv2;
wire op_quan32, op_cat, op_cat14, op_bias16;
assign op_quan32 = (inst_op == `OPCODE_VEC) && (inst_funct3 == `FUNCT3_IVV) && (inst_funct6 == `FUNCT6_QUAN32);
assign op_cat14 = (inst_op == `OPCODE_VEC) && (inst_funct3 == `FUNCT3_IVV) && (inst_funct6 == `FUNCT6_CAT14);
assign op_bias16 = (inst_op == `OPCODE_VEC) && (inst_funct3 == `FUNCT3_IVV) && (inst_funct6 == `FUNCT6_BIAS16);
assign op_cat = op_cat14;
wire op_pool, op_pool1, op_pool2;
assign op_pool1 = (inst_op == `OPCODE_VEC) && (inst_funct3 == `FUNCT3_IVV) && (inst_funct6 == `FUNCT6_POOL1);
assign op_pool2 = (inst_op == `OPCODE_VEC) && (inst_funct3 == `FUNCT3_IVV) && (inst_funct6 == `FUNCT6_POOL2);
assign op_pool = op_pool1 || op_pool2;
wire op_rsi, op_relu;
assign op_rsi = (inst_op == `OPCODE_VEC) && (inst_funct3 == `FUNCT3_IVI) && (inst_funct6 == `FUNCT6_RSI);
assign op_relu = (inst_op == `OPCODE_VEC) && (inst_funct3 == `FUNCT3_IVI) && (inst_funct6 == `FUNCT6_RELU);
wire op_fc, op_fc1;
assign op_fc1 = (inst_op == `OPCODE_VEC) && (inst_funct3 == `FUNCT3_IVV) && (inst_funct6 == `FUNCT6_FC1);
assign op_fc = op_fc1;

wire op_add, op_addi, op_addv, op_addx;
wire op_mul, op_muli, op_mulv, op_mulx;
wire op_le, op_se;
wire op_vi, op_vv, op_vx;
assign op_addi = (inst_op == `OPCODE_VEC) && (inst_funct3 == `FUNCT3_IVI) && (inst_funct6 == `FUNCT6_VADD);
assign op_addv = (inst_op == `OPCODE_VEC) && (inst_funct3 == `FUNCT3_IVV) && (inst_funct6 == `FUNCT6_VADD);
assign op_addx = (inst_op == `OPCODE_VEC) && (inst_funct3 == `FUNCT3_IVX) && (inst_funct6 == `FUNCT6_VADD);
assign op_add  = op_addi || op_addv || op_addx;
assign op_muli = (inst_op == `OPCODE_VEC) && (inst_funct3 == `FUNCT3_IVI) && (inst_funct6 == `FUNCT6_VMUL);
assign op_mulv = (inst_op == `OPCODE_VEC) && (inst_funct3 == `FUNCT3_IVV) && (inst_funct6 == `FUNCT6_VMUL);
assign op_mulx = (inst_op == `OPCODE_VEC) && (inst_funct3 == `FUNCT3_IVX) && (inst_funct6 == `FUNCT6_VMUL);
assign op_mul  = op_muli || op_mulv || op_mulx;
assign op_se   = (inst_op == `OPCODE_VS);
assign op_le   = (inst_op == `OPCODE_VL);
assign op_vi   = op_addi || op_muli || op_rsi || op_relu;
assign op_vv   = op_addv || op_mulv || op_conv || op_quan32 || op_cat || op_pool || op_fc || op_bias16;
assign op_vx   = op_addx || op_mulx;


// Control ALU Operation
assign valu_opcode_o =  ( rst == 1'b1   ) ?   `VALU_OP_NOP     :
                        ( op_mul      )   ?   `VALU_OP_MUL     :
                        ( op_add      )   ?   `VALU_OP_ADD     :
                        ( op_le       )   ?   `VALU_OP_NOP     :
                        ( op_se       )   ?   `VALU_OP_NOP     :
                        ( op_conv1    )   ?   `VALU_OP_CONV1   :
                        ( op_conv2    )   ?   `VALU_OP_CONV2   :
                        ( op_rsi      )   ?   `VALU_OP_RSI     :
                        ( op_quan32   )   ?   `VALU_OP_QUAN32  :
                        ( op_cat14    )   ?   `VALU_OP_CAT14   :
                        ( op_relu     )   ?   `VALU_OP_RELU    :
                        ( op_pool1    )   ?   `VALU_OP_POOL1   :
                        ( op_pool2    )   ?   `VALU_OP_POOL2   :
                        ( op_fc1      )   ?   `VALU_OP_FC1     :
                        ( op_bias16   )   ?   `VALU_OP_BIAS16  :
                                              `VALU_OP_NOP     ;

// regfile
assign rs1_en_o = (!rst) && (op_le || op_se || op_addx || op_mulx);
assign rs1_addr_o = (rs1_en_o)? inst_vs1: 'b0;
assign vs1_en_o = (!rst) && op_vv;
assign vs1_addr_o = (vs1_en_o)? inst_vs1: 'b0;
assign vs2_en_o = (!rst) && (op_vv || op_vx || op_vi || op_se);
assign vs2_addr_o = (!vs2_en_o)? 0: (op_se)? inst_vd: inst_vs2;

// ALU
assign operand_v1_o = (vs1_en_o)? vs1_dout_i: (op_vi)? {8{inst_imm}}: (op_vx)? {8{rs1_dout_i}}: 0;
assign operand_v2_o = (vs2_en_o)? vs2_dout_i: 0;

// Mem Access
assign vmem_ren_o = op_le;
assign vmem_wen_o = op_se;
assign vmem_raddr_o = (op_le)? rs1_dout_i: 0;
assign vmem_waddr_o = rs1_dout_i;
assign vmem_din_o = vs2_dout_i;

// Write Back
assign vid_wb_en_o = op_le || op_vv || op_vi || op_vx;
assign vid_wb_sel_o = op_le;
assign vid_wb_addr_o = (vid_wb_en_o)? inst_vd: 0;
endmodule

