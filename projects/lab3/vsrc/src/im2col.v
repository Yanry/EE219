`timescale 1ns / 1ps

module im2col #(
    parameter IMG_C         = 1,
    parameter IMG_W         = 8,
    parameter IMG_H         = 8,
    parameter DATA_WIDTH    = 8,
    parameter ADDR_WIDTH    = 32,
    parameter FILTER_SIZE   = 3,
    parameter IMG_BASE      = 16'h0000,
    parameter IM2COL_BASE   = 16'h2000
) (
    input clk,
    input rst_n,
    input [DATA_WIDTH-1:0] data_rd,
    output [DATA_WIDTH-1:0] data_wr,
    output [ADDR_WIDTH-1:0] addr_wr,
    output [ADDR_WIDTH-1:0] addr_rd,
    output reg done,
    output reg mem_wr_en
);
    parameter PADDING = (FILTER_SIZE-1) / 2;
    parameter M = IMG_H * IMG_W;
    parameter N = FILTER_SIZE * FILTER_SIZE * IMG_C;
    reg [DATA_WIDTH-1:0] data_rd_reg;
    reg [DATA_WIDTH-1:0] data_wr_reg;
    reg [ADDR_WIDTH-1:0] addr_wr_h, addr_wr_w, addr_wr_h_n, addr_wr_w_n;
    reg [ADDR_WIDTH-1:0] addr_rd_c, addr_rd_h, addr_rd_w;
    reg write_zero;
    reg [ADDR_WIDTH-1:0] addr_wr_d;

    assign data_wr = data_wr_reg;
    // assign addr_wr_d = addr_wr_h + addr_wr_w * M;
    assign addr_wr = addr_wr_h + addr_wr_w * M + IM2COL_BASE;
    assign addr_rd = addr_rd_c + addr_rd_w * IMG_C + addr_rd_h * IMG_C * IMG_W + IMG_BASE;

    always @(posedge clk) begin : proc_write
        if(~rst_n) begin
            addr_wr_h <= 'b0;
            addr_wr_w <= 'b0;
            addr_wr_h_n <= 'b0;
            addr_wr_w_n <= 'b0;
            addr_wr_d <= 'b0;
        end else begin
            if (addr_wr_w_n == N-1) begin
                addr_wr_w_n <= 'b0;
                addr_wr_h_n <= addr_wr_h_n + 1;
            end else begin
                addr_wr_w_n <= addr_wr_w_n + 1;
                addr_wr_h_n <= addr_wr_h_n;
            end
            if (mem_wr_en == 1'b1) begin
                if (addr_wr_w == N-1) begin
                    addr_wr_w <= 'b0;
                    addr_wr_h <= addr_wr_h + 1;
                end else begin
                    addr_wr_w <= addr_wr_w + 1;
                    addr_wr_h <= addr_wr_h;
                end
                addr_wr_d <= addr_wr_h + addr_wr_w * M;
            end            
        end
    end

    reg done_n;
    always @(posedge clk) begin : proc_mem_wr_en
        if (~rst_n) begin
            mem_wr_en <= 0;
        end else begin
            if (done_n == 1'b1) begin
                mem_wr_en <= 1'b0;
            end else begin
                mem_wr_en <= 1'b1;
            end
        end
    end

    reg write_zero_d;
    always @(posedge clk) begin
        if(~rst_n) begin
            write_zero_d <= 1'b1;
        end else begin
            write_zero_d <= write_zero;
        end
    end
    always @(*) begin : proc_write_data
        if (~write_zero_d) begin
            data_wr_reg = data_rd;
        end else begin
            data_wr_reg = 'b0;
        end
    end

    always @(posedge clk) begin : proc_done_n
        if (~rst_n) begin
            done_n <= 1'b0;
        end else if (addr_wr_w_n == N-1 && addr_wr_h_n == M-1) begin
            done_n <= 1'b1;
        end
    end
    always @(posedge clk) begin : proc_done
        if(~rst_n) begin
            done <= 1'b0;
        end else begin
            done <= done_n;
        end
    end

    wire [ADDR_WIDTH-1:0] addr_wr_w_d; // unify different channel
    wire signed [ADDR_WIDTH-1:0] Fx, Fy; // filter position in one channel
    wire signed [ADDR_WIDTH-1:0] x, y; // data position in one filter
    assign addr_wr_w_d = addr_wr_w_n - addr_wr_w_n/(FILTER_SIZE*FILTER_SIZE)*(FILTER_SIZE*FILTER_SIZE);
    assign Fx = addr_wr_h_n / IMG_W; 
    assign Fy = addr_wr_h_n - addr_wr_h_n/IMG_W*IMG_W;
    assign x = addr_wr_w_d / FILTER_SIZE;
    assign y = addr_wr_w_d - addr_wr_w_d / FILTER_SIZE * FILTER_SIZE;

    always @(*) begin : proc_write_zero
        addr_rd_c = addr_wr_w_n / (FILTER_SIZE*FILTER_SIZE);
        addr_rd_h = 'b0;
        addr_rd_w = 'b0;
        if (Fx < PADDING) begin
            if (x < PADDING - Fx) begin
                write_zero = 1'b1;
            end else if (Fy < PADDING) begin
                if (y < PADDING - Fy) begin
                    write_zero = 1'b1;
                end else begin
                    write_zero = 1'b0;
                    addr_rd_h = x - (PADDING - Fx);
                    addr_rd_w = y - (PADDING - Fy); 
                end
            end else if (Fy > IMG_W+PADDING-FILTER_SIZE) begin
                if (y > Fy-(IMG_W+PADDING-FILTER_SIZE)) begin
                    write_zero = 1'b1;
                end else begin
                    write_zero = 1'b0;
                    addr_rd_h = x - (PADDING - Fx);
                    addr_rd_w = y + (Fy - PADDING);
                end
            end else begin
                write_zero = 1'b0;
                addr_rd_h = x - (PADDING - Fx);
                addr_rd_w = y + (Fy - PADDING);
            end          
        end else if (Fx > IMG_H+PADDING-FILTER_SIZE) begin
            if (x > Fx - (IMG_H+PADDING-FILTER_SIZE)) begin
                write_zero = 1'b1;
            end else if (Fy < PADDING) begin
                if (y < PADDING - Fy) begin
                    write_zero = 1'b1;
                end else begin
                    write_zero = 1'b0;
                    addr_rd_h = x + (Fx - PADDING);
                    addr_rd_w = y - (PADDING - Fy); 
                end
            end else if (Fy > IMG_W+PADDING-FILTER_SIZE) begin
                if (y > Fy-(IMG_W+PADDING-FILTER_SIZE)) begin
                    write_zero = 1'b1;
                end else begin
                    write_zero = 1'b0;
                    addr_rd_h = x + (Fx - PADDING);
                    addr_rd_w = y + (Fy - PADDING);
                end
            end else begin
                write_zero = 1'b0;
                addr_rd_h = x + (Fx - PADDING);
                addr_rd_w = y + (Fy - PADDING);
            end
        end else begin
            if (Fy < PADDING) begin
                if (y < PADDING - Fy) begin
                    write_zero = 1'b1;
                end else begin
                    write_zero = 1'b0;
                    addr_rd_h = x + (Fx - PADDING);
                    addr_rd_w = y - (PADDING - Fy); 
                end
            end else if (Fy > IMG_W+PADDING-FILTER_SIZE) begin
                if (y > Fy-(IMG_W+PADDING-FILTER_SIZE)) begin
                    write_zero = 1'b1;
                end else begin
                    write_zero = 1'b0;
                    addr_rd_h = x + (Fx - PADDING);
                    addr_rd_w = y + (Fy - PADDING);
                end
            end else begin
                write_zero = 1'b0;
                addr_rd_h = x + (Fx - PADDING);
                addr_rd_w = y + (Fy - PADDING);
            end
        end
    end
    // assign done = 1; // you should overwrite this

endmodule