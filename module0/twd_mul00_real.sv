`timescale 1ns / 1ps

module twd_mul00 #(
    parameter int WIDTH = 9,
    CLK_CNT = 4
) (
    input logic clk,
    input logic rstn,
    input logic twd00_valid,
    input logic signed [WIDTH:0] i_00bfly_sum_re[0:15],  //<4.6>
    input logic signed [WIDTH:0] i_00bfly_sum_im[0:15],
    input logic signed [WIDTH:0] i_00bfly_diff_re[0:15],
    input logic signed [WIDTH:0] i_00bfly_diff_im[0:15],
    output logic signed [WIDTH:0] twd_00_sum_re[0:15],
    output logic signed [WIDTH:0] twd_00_sum_im[0:15],
    output logic signed [WIDTH:0] twd_00_diff_re[0:15],
    output logic signed [WIDTH:0] twd_00_diff_im[0:15]
);
    int i, j;
    logic [3:0] twd_00_cnt;
    logic [3:0] twd_00_idx;

    counter #(
        .COUNT_MAX_VAL(CLK_CNT)
    ) U_TWD_01_CNT (
        .clk      (clk),
        .rstn     (rstn),
        .en       (twd00_valid),  //twd00_valid            
        .count_out(twd_00_cnt)
    );
    assign twd_00_idx = twd_00_cnt / 8;

    always @(*) begin
        case (twd_00_idx)
            0: begin
                for (j = 0; j < 16; j++) begin
                    twd_00_sum_re[j]  = i_00bfly_sum_re[j];
                    twd_00_sum_im[j]  = i_00bfly_sum_im[j];
                    twd_00_diff_re[j] = i_00bfly_diff_re[j];
                    twd_00_diff_im[j] = i_00bfly_diff_im[j];
                end
            end
            1: begin
                for (j = 0; j < 16; j++) begin
                    twd_00_sum_re[j]  = i_00bfly_sum_re[j];
                    twd_00_sum_im[j]  = i_00bfly_sum_im[j];
                    twd_00_diff_re[j] = i_00bfly_diff_im[j];
                    twd_00_diff_im[j] = -i_00bfly_diff_re[j];
                end
            end
            default: begin
                twd_00_sum_re[j]  = i_00bfly_sum_re[j];
                twd_00_sum_im[j]  = i_00bfly_sum_im[j];
                twd_00_diff_re[j] = i_00bfly_diff_re[j];
                twd_00_diff_im[j] = i_00bfly_diff_im[j];
            end
        endcase
    end
endmodule
