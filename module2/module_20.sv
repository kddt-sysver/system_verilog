`timescale 1ns / 1ps

module module_20 #(
    parameter WIDTH = 12
) (
    input logic clk,
    input logic rstn,

    input signed [WIDTH-1:0] module_1_out_re[0:15],  // <6.6>
    input signed [WIDTH-1:0] module_1_out_im[0:15],
    input logic              module2_valid,

    output logic signed [WIDTH:0] twd_20_re     [0:15],  // <7.6>
    output logic signed [WIDTH:0] twd_20_im     [0:15],
    output logic                  shift_21_valid
);

    logic signed [WIDTH:0] w_20bfly_re[0:15];  // <7.6>
    logic signed [WIDTH:0] w_20bfly_im[0:15];

    logic w_bfly20_valid;
    logic w_twd20_valid;

    assign shift_21_valid = w_twd20_valid;

    counter_v3 #(
        .PULSE_CYCLES(32)
    ) U_SHIFT_VALID_CNT (
        .clk(clk),
        .rstn(rstn),
        .en(module2_valid),
        .out_pulse(w_bfly20_valid)
    );

    bfly_v2 #(
        .WIDTH(12),
        .NUM_POINT(8)  // 블록 크기 (8→4, 4→2, 2→1)
    ) U_BFLY_20 (
        .clk(clk),
        .rstn(rstn),
        .bfly_valid(w_bfly20_valid),
        .din_re(module_1_out_re),
        .din_im(module_1_out_im),
        .bfly_re(w_20bfly_re),
        .bfly_im(w_20bfly_im),
        .twiddle_valid(w_twd20_valid)
    );

    //-------------------------------------twiddle_20 start-------------------------------------
    twd_mul20 #(
        .WIDTH(13)
    ) U_TWD_MUL20 (
        .clk(clk),
        .rstn(rstn),
        .twd20_valid(w_twd20_valid),
        .i_20bfly_re(w_20bfly_re),
        .i_20bfly_im(w_20bfly_im),
        .twd_20_re(twd_20_re),
        .twd_20_im(twd_20_im)
    );
    //-------------------------------------twiddle_20 end---------------------------------------
endmodule
