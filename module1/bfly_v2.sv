`timescale 1ns / 1ps
module bfly_v2 #(
    parameter WIDTH     = 16,
    parameter NUM_POINT = 8    // 블록 크기 (8→4, 4→2, 2→1)
) (
    input  logic clk,
    input  logic rstn,
    input  logic bfly_valid,

    // 한 클럭에 16개 데이터 입력
    input  logic signed [WIDTH-1:0] din_re [0:15],
    input  logic signed [WIDTH-1:0] din_im [0:15],

    // 출력: sum/diff 구분 없이 하나의 배열로
    output logic signed [WIDTH:0] bfly_re [0:15],
    output logic signed [WIDTH:0] bfly_im [0:15],

    output logic twiddle_valid
);

    localparam BLOCK_COUNT = 16 / NUM_POINT;
    localparam PAIR_DIST   = NUM_POINT / 2;

    int base;
    int idx_a;
    int idx_b;

    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            for (int i = 0; i < 16; i++) begin
                bfly_re[i] <= '0;
                bfly_im[i] <= '0;
            end
            twiddle_valid <= 1'b0;

        end else if (bfly_valid) begin
            for (int b = 0; b < BLOCK_COUNT; b++) begin
                base = b * NUM_POINT;
                for (int i = 0; i < PAIR_DIST; i++) begin
                    idx_a = base + i;
                    idx_b = base + i + PAIR_DIST;

                    // 버터플라이 합과 차 계산
                    bfly_re[idx_a] <= din_re[idx_a] + din_re[idx_b];
                    bfly_im[idx_a] <= din_im[idx_a] + din_im[idx_b];

                    bfly_re[idx_b] <= din_re[idx_a] - din_re[idx_b];
                    bfly_im[idx_b] <= din_im[idx_a] - din_im[idx_b];
                end
            end
            twiddle_valid <= 1'b1;

        end else begin
            twiddle_valid <= 1'b0;
        end
    end
endmodule
