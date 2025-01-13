`timescale 1ns / 1ps

`timescale 1ns / 1ps

module systolic_array#(
    parameter M           = 5,
    parameter N           = 3,
    parameter K           = 4,
    parameter DATA_WIDTH  = 32
) (
    input clk,
    input rst_n,
    input [DATA_WIDTH*M-1:0] X,
    input [DATA_WIDTH*K-1:0] W,
    output reg [DATA_WIDTH*M*K-1:0] Y,
    output reg done
);
    genvar i, j;

    reg [DATA_WIDTH-1:0] X_buffer [0:M-1][0:M-1];
    reg [DATA_WIDTH-1:0] W_buffer [0:K-1][0:K-1];
    reg [DATA_WIDTH-1:0] X_in [0:M-1];
    reg [DATA_WIDTH-1:0] W_in [0:K-1];

    for (i = 0; i < M; i = i + 1) begin
        for (j = 0; j < M; j = j + 1) begin
            always @(posedge clk) begin : proc_X_buffer
                if(~rst_n) begin
                    X_in[i] <= 'b0;
                    X_buffer[i][i] <= 'b0;
                    X_buffer[i][j] <= 'b0;
                end else begin
                    X_in[i] <= X_buffer[i][0];
                    X_buffer[i][i] <= X[DATA_WIDTH*(i+1)-1:DATA_WIDTH*i];
                    if (j < i) begin
                        X_buffer[i][j] <= X_buffer[i][j+1];
                    end
                end
            end
        end
    end

    for (j = 0; j < K; j = j + 1) begin
        for (i = 0; i < K; i = i + 1) begin
            always @(posedge clk) begin : proc_W_buffer
                if(~rst_n) begin
                    W_in[j] <= 'b0;
                    W_buffer[j][j] <= 'b0;
                    W_buffer[i][j] <= 'b0;
                end else begin
                    W_in[j] <= W_buffer[0][j];
                    W_buffer[j][j] <= W[DATA_WIDTH*(j+1)-1:DATA_WIDTH*j];
                    if (i < j) begin
                        W_buffer[i][j] <= W_buffer[i+1][j];
                    end
                end
            end
        end
    end

    wire [DATA_WIDTH-1:0] X_out [0:M-1][0:K-1];
    wire [DATA_WIDTH-1:0] W_out [0:M-1][0:K-1];
    wire [DATA_WIDTH-1:0] Y_out [0:M-1][0:K-1];
    generate
        for (i = 0; i < M; i = i + 1) begin
            for (j = 0; j < K; j = j + 1) begin
                if (i == 0 && j == 0) begin
                    pe pe_00(
                        .clk(clk),
                        .rst(rst_n),
                        .x_in(X_in[0]),
                        .w_in(W_in[0]),
                        .x_out(X_out[0][0]),
                        .w_out(W_out[0][0]),
                        .y_out(Y_out[0][0])
                        );
                end else if (i == 0 && j != 0) begin
                    pe pe_i0(
                        .clk(clk),
                        .rst(rst_n),
                        .x_in(X_out[i][j-1]),
                        .w_in(W_in[j]),
                        .x_out(X_out[i][j]),
                        .w_out(W_out[i][j]),
                        .y_out(Y_out[i][j])
                        );
                end else if (i != 0 && j == 0) begin
                    pe pe_j0(
                        .clk(clk),
                        .rst(rst_n),
                        .x_in(X_in[i]),
                        .w_in(W_out[i-1][j]),
                        .x_out(X_out[i][j]),
                        .w_out(W_out[i][j]),
                        .y_out(Y_out[i][j])
                        );
                end else begin
                    pe pe_ij(
                        .clk(clk),
                        .rst(rst_n),
                        .x_in(X_out[i][j-1]),
                        .w_in(W_out[i-1][j]),
                        .x_out(X_out[i][j]),
                        .w_out(W_out[i][j]),
                        .y_out(Y_out[i][j])
                        );
                end
            end
        end
    endgenerate

    for (i = 0; i < M; i = i + 1) begin
        for (j = 0; j < K; j = j + 1) begin
            always @(posedge clk) begin : proc_Y
                if(~rst_n) begin
                    Y[(i*K+j+1)*DATA_WIDTH-1:(i*K+j)*DATA_WIDTH] <= 'b0;
                end else begin
                    Y[(i*K+j+1)*DATA_WIDTH-1:(i*K+j)*DATA_WIDTH] <= Y_out[i][j];
                end
            end
        end
    end

    reg [31:0] cnt;
    always @(posedge clk or negedge rst_n) begin : proc_done
        if(~rst_n) begin
            cnt <= 0;
            done <= 1'b0;
        end else begin
            cnt <= cnt + 1;
            if (cnt > N + M + K + 2) begin
                done <= 1'b1;
            end
        end
    end
endmodule