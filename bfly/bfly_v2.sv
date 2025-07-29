`timescale 1ns / 1ps

module bfly_v2 #(
    parameter WIDTH = 15,
    parameter NUM_PAIR = 16
) (
    input logic clk,
    input logic rstn,
    input logic bfly_valid,

    input logic signed [WIDTH-1:0] din_re[0:NUM_PAIR - 1],
    input logic signed [WIDTH-1:0] din_im[0:NUM_PAIR - 1],

    output logic signed [WIDTH:0] bfly_sum_re [0:NUM_PAIR / 2 - 1],
    output logic signed [WIDTH:0] bfly_sum_im [0:NUM_PAIR / 2 - 1],
    output logic signed [WIDTH:0] bfly_diff_re[0:NUM_PAIR / 2 - 1],
    output logic signed [WIDTH:0] bfly_diff_im[0:NUM_PAIR / 2 - 1],

    output logic twiddle_valid
);

    localparam int NUM_CALC = NUM_PAIR / 2;
    logic [$clog2(NUM_CALC):0] count;

    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            count <= 0;
            twiddle_valid <= 0;

            for (int i = 0; i < NUM_CALC; i++) begin
                bfly_sum_re[i]  <= '0;
                bfly_sum_im[i]  <= '0;
                bfly_diff_re[i] <= '0;
                bfly_diff_im[i] <= '0;
            end

        end else if (bfly_valid) begin
            for (int i = 0; i < NUM_CALC; i++) begin
                bfly_sum_re[i]  <= din_re[i] + din_re[i + NUM_CALC];
                bfly_sum_im[i]  <= din_im[i] + din_im[i + NUM_CALC];
                bfly_diff_re[i] <= din_re[i] - din_re[i + NUM_CALC];
                bfly_diff_im[i] <= din_im[i] - din_im[i + NUM_CALC];
            end

            count <= count + 1;
            if (count == NUM_CALC - 1) begin
                twiddle_valid <= 1;
            end else begin
                twiddle_valid <= 0;
            end

        end else begin
            count <= 0;
            twiddle_valid <= 0;

            for (int i = 0; i < NUM_CALC; i++) begin
                bfly_sum_re[i]  <= '0;
                bfly_sum_im[i]  <= '0;
                bfly_diff_re[i] <= '0;
                bfly_diff_im[i] <= '0;
            end
        end
    end

endmodule
