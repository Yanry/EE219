`timescale 1ns / 1ps

module pe #(
    parameter DATA_WIDTH = 32
) (
    input clk,
    input rst,
    input [DATA_WIDTH-1:0] x_in,
    input [DATA_WIDTH-1:0] w_in,
    output reg [DATA_WIDTH-1:0] x_out,
    output reg [DATA_WIDTH-1:0] w_out,
    output reg [DATA_WIDTH-1:0] y_out
);

    always @(posedge clk) begin : proc_w_out
        if(~rst) begin
            w_out <= 0;
        end else begin
            w_out <= w_in;
        end
    end
    always @(posedge clk) begin : proc_x_out
        if(~rst) begin
            x_out <= 0;
        end else begin
            x_out <= x_in;
        end
    end
    always @(posedge clk) begin : proc_y_out
        if(~rst) begin
            y_out <= 0;
        end else begin
            y_out <= y_out + x_in * w_in;
        end
    end
endmodule