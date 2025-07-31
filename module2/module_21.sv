`timescale 1ns / 1ps

module module_21 #(
    parameter int WIDTH = 13
) (
    input logic clk,
    input logic rstn,

    input logic signed [WIDTH-1:0] twd_20_re [0:15],
    input logic signed [WIDTH-1:0] twd_20_im [0:15],      // <7.6>
    input logic                    shift_21_valid,

    output logic signed [WIDTH+2:0] twd_21_re [0:15],
    output logic signed [WIDTH+2:0] twd_21_im [0:15],     // <10.6>
    output logic                    shift_22_valid
);

    logic signed [WIDTH:0] w_21bfly_re[0:15];  // <8.6>  
    logic signed [WIDTH:0] w_21bfly_im[0:15];

    logic w_bfly21_valid;
    logic w_twd21_valid;

    assign shift_22_valid = w_twd21_valid;

    counter_v3 #(
        .PULSE_CYCLES(32)  
    ) U_SHIFT_VALID_CNT (
        .clk      (clk),
        .rstn     (rstn),
        .en       (shift_21_valid), 
        .out_pulse(w_bfly21_valid)  
    );

    bfly_v2 #(
        .WIDTH(13),
        .NUM_POINT(4)  // 블록 크기 (8→4, 4→2, 2→1)
    ) U_BFLY_21 (
        .clk(clk),
        .rstn(rstn),
        .bfly_valid(w_bfly21_valid),
        .din_re(twd_20_re),
        .din_im(twd_20_im),
        .bfly_re(w_21bfly_re),
        .bfly_im(w_21bfly_im),
        .twiddle_valid(w_twd21_valid)
    );

    //-------------------------------------twiddle_01 start-------------------------------------

    twd_mul21 #(
        .WIDTH  (14)
    ) U_TWD_MUL21 (
        .clk(clk),
        .rstn(rstn),
        .twd21_valid(w_twd21_valid),
        .i_21bfly_re(w_21bfly_re),
        .i_21bfly_im(w_21bfly_im),
        .twd_21_re(twd_21_re),     // <10.6>
        .twd_21_im(twd_21_im)
    );
    //-------------------------------------twiddle_01 end---------------------------------------
endmodule
