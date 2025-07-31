`timescale 1ns / 1ps

module twd_mul10 #(
    parameter int WIDTH = 12,
    parameter int CLK_CNT = 4 // CLK_CNT는 4로 유지, twd_10_cnt는 [3:0] (0~15)
) (
    input logic clk,
    input logic rstn,
    input logic twd10_valid,
    input logic signed [WIDTH-1:0] i_10bfly_sum_re[0:15],
    input logic signed [WIDTH-1:0] i_10bfly_sum_im[0:15],
    input logic signed [WIDTH-1:0] i_10bfly_diff_re[0:15],
    input logic signed [WIDTH-1:0] i_10bfly_diff_im[0:15],
    output logic signed [WIDTH-1:0] twd_10_sum_re[0:15],
    output logic signed [WIDTH-1:0] twd_10_sum_im[0:15],
    output logic signed [WIDTH-1:0] twd_10_diff_re[0:15],
    output logic signed [WIDTH-1:0] twd_10_diff_im[0:15]
);
    int j_local;
    logic [CLK_CNT-1:0] twd_10_cnt; // 0부터 (2^CLK_CNT)-1까지 카운트 (CLK_CNT=4이므로 0~15)
    logic twd_10_idx; // 이제 0 또는 1만 가집니다.

    counter #(
        .COUNT_MAX_VAL((1<<CLK_CNT)-1) // CLK_CNT가 4이므로 0~15까지 카운트
    ) U_TWD_10_CNT (
        .clk        (clk),
        .rstn       (rstn),
        .en         (twd10_valid),          
        .count_out  (twd_10_cnt)
    );

    // twd_10_idx를 twd_10_cnt의 최하위 비트로 설정합니다.
    // 이렇게 하면 twd_10_cnt가 0,1,2,3...일 때 twd_10_idx가 0,1,0,1...로 번갈아 나타납니다.
    assign twd_10_idx = twd_10_cnt[0]; 

    always @(*) begin
        // 기본적으로 Twiddle Factor가 1인 경우 (그대로 통과)로 설정
        for (j_local = 0; j_local < 16; j_local++) begin
            twd_10_sum_re[j_local]  = i_10bfly_sum_re[j_local];
            twd_10_sum_im[j_local]  = i_10bfly_sum_im[j_local];
            twd_10_diff_re[j_local] = i_10bfly_diff_re[j_local];
            twd_10_diff_im[j_local] = i_10bfly_diff_im[j_local];
        end

        // twd_10_idx는 이제 0 (짝수 카운트) 또는 1 (홀수 카운트) 값을 가집니다.
        case (twd_10_idx)
            0: begin // twd_10_cnt가 짝수일 때 (0, 2, 4, ...)
                // Twiddle Factor = 1. 기본값으로 이미 설정됨.
            end
            1: begin // twd_10_cnt가 홀수일 때 (1, 3, 5, ...)
                // Twiddle Factor = -j (이전 대화에서 twd_10_idx=1일 때 -j를 곱했음)
                for (j_local = 0; j_local < 16; j_local++) begin
                    twd_10_diff_re[j_local] = i_10bfly_diff_im[j_local]; // Re = Im
                    twd_10_diff_im[j_local] = -i_10bfly_diff_re[j_local]; // Im = -Re
                end
            end
            default: begin // twd_10_idx는 0 또는 1만 가질 것이므로 default는 사실상 실행되지 않습니다.
            end
        endcase
    end
endmodule