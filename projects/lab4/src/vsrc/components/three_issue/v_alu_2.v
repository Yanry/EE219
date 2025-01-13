// =======================================
// You need to finish this module
// =======================================

module v_alu_2 #(
    parameter SEW       = 32,
    parameter VLMAX     = 8,
    parameter VALUOP_DW = 5,
    parameter VREG_DW   = 256,
    parameter VREG_AW   = 5
)(
    input                   clk,
    input                   rst,
    input [VALUOP_DW-1:0]   valu_opcode_i,
    input [VREG_DW-1:0]     operand_v1_i,
    input [VREG_DW-1:0]     operand_v2_i,
    output[VREG_DW-1:0]     valu_result_o
);

localparam VALU_OP_NOP  = 5'd0 ;
localparam VALU_OP_VADD = 5'd1 ;
localparam VALU_OP_VMUL = 5'd2 ;

genvar i;
for (i = 1; i <= VLMAX; i = i + 1) begin
    always @(*) begin : proc_result
        if(rst == 1'b1) begin
            valu_result_o[SEW*i-1:SEW*(i-1)] = 0;
        end else begin
            case (valu_opcode_i)
                VALU_OP_NOP:    valu_result_o[SEW*i-1:SEW*(i-1)] = 0;
                VALU_OP_VADD:   begin
                    valu_result_o[SEW*i-1:SEW*(i-1)] = operand_v1_i[SEW*i-1:SEW*(i-1)] + operand_v2_i[SEW*i-1:SEW*(i-1)];
                end
                VALU_OP_VMUL:   begin
                    valu_result_o[SEW*i-1:SEW*(i-1)] = operand_v1_i[SEW*i-1:SEW*(i-1)] * operand_v2_i[SEW*i-1:SEW*(i-1)];
                end
            
                default : valu_result_o[SEW*i-1:SEW*(i-1)] = 0;
            endcase
        end
    end
end

endmodule