`timescale 1ns / 1ps

module twd_mul10 #(
    parameter int WIDTH = 12,
    parameter int CLK_CNT = 4
) (
    input logic clk,
    input logic rstn,
    input logic twd10_valid,
    input logic signed [WIDTH-1:0] i_10bfly_sum_re[0:15],  //<6.6>
    input logic signed [WIDTH-1:0] i_10bfly_sum_im[0:15],
    input logic signed [WIDTH-1:0] i_10bfly_diff_re[0:15],
    input logic signed [WIDTH-1:0] i_10bfly_diff_im[0:15],
    output logic signed [WIDTH-1:0] twd_10_sum_re[0:15],
    output logic signed [WIDTH-1:0] twd_10_sum_im[0:15],
    output logic signed [WIDTH-1:0] twd_10_diff_re[0:15],
    output logic signed [WIDTH-1:0] twd_10_diff_im[0:15]
);
    int i, j;
    logic [3:0] twd_10_cnt;
    logic [3:0] twd_10_idx;

    counter #(
        .COUNT_MAX_VAL(CLK_CNT)
    ) U_TWD_10_CNT (
        .clk      (clk),
        .rstn     (rstn),
        .en       (twd10_valid),           
        .count_out(twd_10_cnt)
    );
    assign twd_10_idx = twd_10_cnt

    always @(*) begin
        case (twd_10_idx)
            0, 1, 2: begin
                for (j = 0; j < 16; j++) begin
                    twd_10_sum_re[j]  = i_10bfly_sum_re[j];
                    twd_10_sum_im[j]  = i_10bfly_sum_im[j];
                    twd_10_diff_re[j] = i_10bfly_diff_re[j];
                    twd_10_diff_im[j] = i_10bfly_diff_im[j];
                end
            end
            3: begin
                for (j = 0; j < 16; j++) begin
                    twd_10_sum_re[j]  = i_10bfly_sum_re[j];
                    twd_10_sum_im[j]  = i_10bfly_sum_im[j];
                    twd_10_diff_re[j] = i_10bfly_diff_im[j];
                    twd_10_diff_im[j] = -i_10bfly_diff_re[j];
                end
            end
            default: begin
                twd_10_sum_re[j]  = i_10bfly_sum_re[j];
                twd_10_sum_im[j]  = i_10bfly_sum_im[j];
                twd_10_diff_re[j] = i_10bfly_diff_re[j];
                twd_10_diff_im[j] = i_10bfly_diff_im[j];
            end
        endcase
    end
endmodule
