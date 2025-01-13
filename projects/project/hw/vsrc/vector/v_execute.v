// =======================================
// You need to finish this module
// =======================================
`include "v_defines.v"

module v_execute (
    input                      clk,
    input                      rst,
    input [`ALU_OP_BUS]        valu_opcode_i,
    input [`VREG_BUS]          operand_v1_i,
    input [`VREG_BUS]          operand_v2_i,
    output reg [`VREG_BUS]     valu_result_o
);

integer i;
always @(*) begin : proc_result
    if(rst == 1'b1) begin
        valu_result_o = 0;
    end else begin
        case (valu_opcode_i)
            `VALU_OP_NOP:    valu_result_o = 0;
            `VALU_OP_ADD:   begin
                for (i=0; i<16; i=i+1) begin
                    valu_result_o[32*i+:32] = operand_v1_i[32*i+:32] + operand_v2_i[32*i+:32];
                end
            end
            `VALU_OP_BIAS16:   begin
                for (i=0; i<10; i=i+1) begin
                    valu_result_o[32*i+:32] = operand_v1_i[32*i+:32] + {16'b0, operand_v2_i[16*i+:16]};
                end
            end
            `VALU_OP_MUL:   begin
                for (i=0; i<16; i=i+1) begin
                    valu_result_o[32*i+:32] = operand_v1_i[32*i+:32] * operand_v2_i[32*i+:32];
                end
            end
            `VALU_OP_CONV1:   begin
                for (i=0; i<28/2; i=i+1) begin
                    valu_result_o[32*i+:32]  = $signed(operand_v1_i[8*i+:8])     * $signed(operand_v2_i[7  :  0])
                                             + $signed(operand_v1_i[8*(i+1)+:8]) * $signed(operand_v2_i[15 :  8])
                                             + $signed(operand_v1_i[8*(i+2)+:8]) * $signed(operand_v2_i[23 : 16])
                                             + $signed(operand_v1_i[8*(i+3)+:8]) * $signed(operand_v2_i[31 : 24])
                                             + $signed(operand_v1_i[8*(i+4)+:8]) * $signed(operand_v2_i[39 : 32]);
                end
                valu_result_o[`VLEN-1:32*28/2] = 0;
            end
            `VALU_OP_CONV2:   begin
                for (i=0; i<12; i=i+1) begin
                    valu_result_o[32*i+:32]  = $signed(operand_v1_i[8*i+:8])     * $signed(operand_v2_i[7  :  0])
                                             + $signed(operand_v1_i[8*(i+1)+:8]) * $signed(operand_v2_i[15 :  8])
                                             + $signed(operand_v1_i[8*(i+2)+:8]) * $signed(operand_v2_i[23 : 16]);
                end
                valu_result_o[`VLEN-1:32*12] = 0;
            end
            `VALU_OP_RSI:    valu_result_o = operand_v2_i >> (operand_v1_i[7:0] * 8) ;
            `VALU_OP_QUAN32:   begin
                for (i=0; i<16; i=i+1) begin
                    valu_result_o[8*i+:8] = {{operand_v2_i[32*i+:32] >> (operand_v1_i[7:0])} + {31'b0, operand_v2_i[{{24'b0, operand_v1_i[7:0]}-1+32*i}[8:0]]}}[7:0];
                end
                valu_result_o[`VLEN-1:8*16] = 0;
            end
            `VALU_OP_CAT14:    begin
                valu_result_o[14*8-1:0] = operand_v1_i[14*8-1:0];
                valu_result_o[28*8-1:14*8] = operand_v2_i[14*8-1:0];
                valu_result_o[`VLEN-1:28*8] = 0;
            end
            `VALU_OP_RELU:     begin
                for (i=0; i<32; i=i+1) begin
                    valu_result_o[8*i+:8] = ($signed(operand_v2_i[8*i+:8]) > 0)? operand_v2_i[8*i+:8]: 8'b0;
                end
            end
            `VALU_OP_POOL1:     begin
                for (i=0; i<16; i=i+1) begin
                    if (operand_v1_i[16*i+:8] >= operand_v1_i[16*i+8+:8] && operand_v1_i[16*i+:8] >= operand_v2_i[16*i+:8] && operand_v1_i[16*i+:8] >= operand_v2_i[16*i+8+:8]) begin
                        valu_result_o[8*i+:8] = operand_v1_i[16*i+:8];
                    end else if (operand_v1_i[16*i+8+:8] >= operand_v1_i[16*i+:8] && operand_v1_i[16*i+8+:8] >= operand_v2_i[16*i+:8] && operand_v1_i[16*i+8+:8] >= operand_v2_i[16*i+8+:8]) begin
                        valu_result_o[8*i+:8] = operand_v1_i[16*i+8+:8];
                    end else if (operand_v2_i[16*i+:8] >= operand_v1_i[16*i+:8] && operand_v2_i[16*i+:8] >= operand_v1_i[16*i+8+:8] && operand_v2_i[16*i+:8] >= operand_v2_i[16*i+8+:8]) begin
                        valu_result_o[8*i+:8] = operand_v2_i[16*i+:8];
                    end else if (operand_v2_i[16*i+8+:8] >= operand_v1_i[16*i+:8] && operand_v2_i[16*i+8+:8] >= operand_v1_i[16*i+8+:8] && operand_v2_i[16*i+8+:8] >= operand_v2_i[16*i+:8]) begin
                        valu_result_o[8*i+:8] = operand_v2_i[16*i+8+:8];
                    end
                end
                valu_result_o[`VLEN-1:16*8] = 0;
            end
            `VALU_OP_POOL2:     begin
                for (i=0; i<8; i=i+1) begin
                    if (operand_v1_i[16*i+:8] >= operand_v1_i[16*i+8+:8] && operand_v1_i[16*i+:8] >= operand_v1_i[16*i+128+:8] && operand_v1_i[16*i+:8] >= operand_v1_i[16*i+136+:8]) begin
                        valu_result_o[8*i+:8] = operand_v1_i[16*i+:8];
                    end else if (operand_v1_i[16*i+8+:8] >= operand_v1_i[16*i+:8] && operand_v1_i[16*i+8+:8] >= operand_v1_i[16*i+128+:8] && operand_v1_i[16*i+8+:8] >= operand_v1_i[16*i+136+:8]) begin
                        valu_result_o[8*i+:8] = operand_v1_i[16*i+8+:8];
                    end else if (operand_v1_i[16*i+128+:8] >= operand_v1_i[16*i+:8] && operand_v1_i[16*i+128+:8] >= operand_v1_i[16*i+8+:8] && operand_v1_i[16*i+128+:8] >= operand_v1_i[16*i+136+:8]) begin
                        valu_result_o[8*i+:8] = operand_v1_i[16*i+128+:8];
                    end else if (operand_v1_i[16*i+136+:8] >= operand_v1_i[16*i+:8] && operand_v1_i[16*i+136+:8] >= operand_v1_i[16*i+8+:8] && operand_v1_i[16*i+136+:8] >= operand_v1_i[16*i+128+:8]) begin
                        valu_result_o[8*i+:8] = operand_v1_i[16*i+136+:8];
                    end
                end
                for (i=0; i<8; i=i+1) begin
                    if (operand_v1_i[16*i+256+:8] >= operand_v1_i[16*i+8+256+:8] && operand_v1_i[16*i+256+:8] >= operand_v1_i[16*i+128+256+:8] && operand_v1_i[16*i+256+:8] >= operand_v1_i[16*i+136+256+:8]) begin
                        valu_result_o[8*i+64+:8] = operand_v1_i[16*i+256+:8];
                    end else if (operand_v1_i[16*i+8+256+:8] >= operand_v1_i[16*i+256+:8] && operand_v1_i[16*i+8+256+:8] >= operand_v1_i[16*i+128+256+:8] && operand_v1_i[16*i+8+256+:8] >= operand_v1_i[16*i+136+256+:8]) begin
                        valu_result_o[8*i+64+:8] = operand_v1_i[16*i+8+256+:8];
                    end else if (operand_v1_i[16*i+128+256+:8] >= operand_v1_i[16*i+256+:8] && operand_v1_i[16*i+128+256+:8] >= operand_v1_i[16*i+8+256+:8] && operand_v1_i[16*i+128+256+:8] >= operand_v1_i[16*i+136+256+:8]) begin
                        valu_result_o[8*i+64+:8] = operand_v1_i[16*i+128+256+:8];
                    end else if (operand_v1_i[16*i+136+256+:8] >= operand_v1_i[16*i+256+:8] && operand_v1_i[16*i+136+256+:8] >= operand_v1_i[16*i+8+256+:8] && operand_v1_i[16*i+136+256+:8] >= operand_v1_i[16*i+128+256+:8]) begin
                        valu_result_o[8*i+64+:8] = operand_v1_i[16*i+136+256+:8];
                    end
                end
                valu_result_o[`VLEN-1:16*8] = 0;
            end
            `VALU_OP_FC1:     begin
                for (i=0; i<16; i=i+1) begin
                    valu_result_o[32*i+:32]  = $signed(operand_v1_i[8*i+:8])     * $signed(operand_v2_i[7  :  0]);
                end
                // valu_result_o[`VLEN-1:32*16] = 0;
            end
        
            default : valu_result_o = 0;
        endcase
    end
end


endmodule
