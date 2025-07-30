`timescale 1ns / 1ps
module bfly_v2 #(
    parameter WIDTH     = 16,
    parameter NUM_POINT = 8  // 블록 크기 (16→8, 8→4, 4→2, 2→1)
)(
    input  logic clk,
    input  logic rstn,
    input  logic bfly_valid,

    // 한 클럭에 16개 데이터 입력 (실수/허수)
    input  logic signed [WIDTH-1:0] din_re [0:15],
    input  logic signed [WIDTH-1:0] din_im [0:15],

    // (합/차 결과)
    output logic signed [WIDTH:0] bfly_sum_re  [0:15],
    output logic signed [WIDTH:0] bfly_sum_im  [0:15],
    output logic signed [WIDTH:0] bfly_diff_re [0:15],
    output logic signed [WIDTH:0] bfly_diff_im [0:15],

    output logic twiddle_valid
);

    localparam BLOCK_COUNT = 16 / NUM_POINT; // 블록 개수
    int base;

    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            for (int i = 0; i < 16; i++) begin
                bfly_sum_re[i]  <= '0;
                bfly_sum_im[i]  <= '0;
                bfly_diff_re[i] <= '0;
                bfly_diff_im[i] <= '0;
            end
            twiddle_valid <= 1'b0;

        end else if (bfly_valid) begin
            for (int b = 0; b < BLOCK_COUNT; b++) begin
                base = b * NUM_POINT;
                for (int i = 0; i < NUM_POINT/2; i++) begin
                    // 합
                    bfly_sum_re[base + i] <= din_re[base + i] + din_re[base + i + NUM_POINT/2];
                    bfly_sum_im[base + i] <= din_im[base + i] + din_im[base + i + NUM_POINT/2];

                    // 차
                    bfly_diff_re[base + i + NUM_POINT/2] <= din_re[base + i] - din_re[base + i + NUM_POINT/2];
                    bfly_diff_im[base + i + NUM_POINT/2] <= din_im[base + i] - din_im[base + i + NUM_POINT/2];
                end
            end
            twiddle_valid <= 1'b1;

        end else begin
            twiddle_valid <= 1'b0;
        end
    end

endmodule
