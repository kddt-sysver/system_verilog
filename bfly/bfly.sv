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

    // twiddle_valid는 여전히 동기적으로 한 클럭 유지
    localparam NUM_CYCLES = NUM_PAIR / 16;
    logic [$clog2(NUM_CYCLES):0] count;

    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            count <= 0;
            twiddle_valid <= 0;
        end else if (bfly_valid) begin
            count <= count + 1;
            if (count == NUM_CYCLES - 1)
                twiddle_valid <= 1;
            else
                twiddle_valid <= 0;
        end else begin
            count <= 0;
            twiddle_valid <= 0;
        end
    end

    // 조합 논리: bfly 결과는 bfly_valid와 동시에 반영
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



/*
`timescale 1ns/1ps

module bfly #(
    parameter WIDTH = 12,
    parameter NUM_PAIR = 256  // 16쌍 × 16클럭
)(
    input  logic clk,
    input  logic rstn,

    input  logic bfly_valid,  // 연산 진행 동안 1

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
    logic twiddle_valid_d;

    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            count <= 0;
            twiddle_valid <= 0;
            twiddle_valid_d <= 0;
            for (int i = 0; i < 16; i++) begin
                bfly_sum_re[i]  <= 0;
                bfly_sum_im[i]  <= 0;
                bfly_diff_re[i] <= 0;
                bfly_diff_im[i] <= 0;
            end
        end else begin
            if (bfly_valid) begin
                for (int i = 0; i < 16; i++) begin
                    bfly_sum_re[i]  <= $signed(shift_data_re[i]) + $signed(din_re[i]);
                    bfly_sum_im[i]  <= $signed(shift_data_im[i]) + $signed(din_im[i]);
                    bfly_diff_re[i] <= $signed(shift_data_re[i]) - $signed(din_re[i]);
                    bfly_diff_im[i] <= $signed(shift_data_im[i]) - $signed(din_im[i]);
                end

                count <= count + 1;
                twiddle_valid_d <= (count == NUM_CYCLES - 1);
                twiddle_valid   <= twiddle_valid_d;
            end else begin
                count <= 0;
                twiddle_valid <= 0;
                twiddle_valid_d <= 0;
            end
        end
    end

endmodule
*/
