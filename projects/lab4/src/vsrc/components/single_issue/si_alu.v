// =======================================
// You need to finish this module
// =======================================

module si_alu #(
    parameter PC_START  = 32'h8000_0000, 
    parameter INST_DW   = 32,
    parameter INST_AW   = 32,
    parameter REG_DW    = 32,
    parameter ALUOP_DW  = 5
)(
    input                   clk,
    input                   rst,
    
    // arithmetic
    input   [ALUOP_DW-1:0]  alu_opcode_i,
    input   [REG_DW-1:0]    operand_1_i,
    input   [REG_DW-1:0]    operand_2_i,
    output  reg [REG_DW-1:0]    alu_result_o,
    // branch
    input   [INST_AW-1:0]   current_pc_i,
    input                   branch_en_i,
    input   [INST_AW-1:0]   branch_offset_i,
    input                   jump_en_i,
    input   [INST_AW-1:0]   jump_offset_i,
    output  reg                 control_en_o,
    output  reg [INST_AW-1:0]   control_pc_o
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

reg [REG_DW-1:0] alu_result ;
always @(*) begin
    if( rst == 1'b1 ) begin
        alu_result = 0 ;
    end else begin
        case ( alu_opcode_i )
            ALU_OP_ADD:    alu_result = ( operand_1_i + operand_2_i ) ;
            ALU_OP_SLTI:   alu_result = ( $signed(operand_1_i) < $signed(operand_2_i) ) ? 1 : 0;
            ALU_OP_MUL:    alu_result = ( operand_1_i * operand_2_i ) ;
            ALU_OP_AND:    alu_result = ( operand_1_i & operand_2_i ) ;
            ALU_OP_SLL:    alu_result = ( operand_1_i << operand_2_i ) ;
            ALU_OP_NOP:    alu_result = 0 ;
            default:       alu_result = 0 ;
        endcase
    end
end

// The execute_stage result
assign alu_result_o = (jump_en_i) ? (current_pc_i + 4) : (alu_result);

// Control Branching
assign control_en_o = jump_en_i | branch_en_i;
assign control_pc_o = (jump_en_i)   ? (current_pc_i + jump_offset_i) :
                       (branch_en_i) ? (current_pc_i + branch_offset_i) : PC_START;

endmodule 
