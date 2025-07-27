`timescale 1ns/1ps

module bfly #(
    parameter WIDTH = 9,
    parameter NUM_PAIR = 256  // 16쌍 × N 클럭
)(
    input  logic clk,
    input  logic rstn,

    input  logic bfly_valid,  // 연산 시 HIGH

    input  logic signed [WIDTH-1:0] din_re        [0:15],
    input  logic signed [WIDTH-1:0] din_im        [0:15],
    input  logic signed [WIDTH-1:0] shift_data_re [0:15],
    input  logic signed [WIDTH-1:0] shift_data_im [0:15],

    output logic signed [WIDTH:0] bfly_sum_re   [0:15],
    output logic signed [WIDTH:0] bfly_sum_im   [0:15],
    output logic signed [WIDTH:0] bfly_diff_re  [0:15],
    output logic signed [WIDTH:0] bfly_diff_im  [0:15],

    output logic twiddle_valid
);

    localparam NUM_CYCLES = NUM_PAIR / 16;

    logic [$clog2(NUM_CYCLES):0] count;
    logic bfly_valid_d;  // 지연된 valid 신호

    // 동기 로직: 연산 횟수 세고 falling edge에서 twiddle_valid 발생
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            count <= 0;
            bfly_valid_d <= 0;
            twiddle_valid <= 0;
        end else begin
            bfly_valid_d <= bfly_valid;

            if (bfly_valid)
                count <= count + 1;
            else
                count <= 0;

            if (bfly_valid_d && !bfly_valid && count == NUM_CYCLES)
                twiddle_valid <= 1;
            else
                twiddle_valid <= 0;
        end
    end

    // 조합 논리: 버터플라이 연산
    always_comb begin
        for (int i = 0; i < 16; i++) begin
            if (bfly_valid) begin
                bfly_sum_re[i]  = $signed(shift_data_re[i]) + $signed(din_re[i]);
                bfly_sum_im[i]  = $signed(shift_data_im[i]) + $signed(din_im[i]);
                bfly_diff_re[i] = $signed(shift_data_re[i]) - $signed(din_re[i]);
                bfly_diff_im[i] = $signed(shift_data_im[i]) - $signed(din_im[i]);
            end else begin
                bfly_sum_re[i]  = '0;
                bfly_sum_im[i]  = '0;
                bfly_diff_re[i] = '0;
                bfly_diff_im[i] = '0;
            end
        end
    end

endmodule
