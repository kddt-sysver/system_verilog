`timescale 1ns / 1ps

module module_0 #(
    parameter int WIDTH = 9
) (
    input logic clk,
    input logic rstn,
    //input  logic                    fft_mode,    // IFFT 모드용 켤레 처리

    input signed [WIDTH-1:0] in_i     [0:15],
    input signed [WIDTH-1:0] in_q     [0:15],
    input                    din_valid,

    output logic signed [WIDTH+1:0] module_00_out_re[0:15],
    output logic signed [WIDTH+1:0] module_00_out_im[0:15],
    output logic                    module1_valid
);
    int i;

    //-------------------------------------module_00------------------------------------------
    logic signed [WIDTH:0] w_twd_00_sum_re[0:15];  //<4.6>
    logic signed [WIDTH:0] w_twd_00_sum_im[0:15];  //<4.6>
    logic signed [WIDTH:0] w_twd_00_diff_re[0:15];  //<4.6>
    logic signed [WIDTH:0] w_twd_00_diff_im[0:15];  //<4.6>
    logic w_shift_01_valid;

    module_00 #(
        .WIDTH(9)
    ) U_MODULE_00 (
        .clk(clk),
        .rstn(rstn),
        //input  logic                    fft_mode,    // IFFT 모드용 켤레 처리
        .in_i(in_i),
        .in_q(in_q),
        .din_valid(din_valid),
        .twd_00_sum_re(w_twd_00_sum_re),
        .twd_00_sum_im(w_twd_00_sum_im),
        .twd_00_diff_re(w_twd_00_diff_re),
        .twd_00_diff_im(w_twd_00_diff_im),
        .shift_01_valid(w_shift_01_valid)
    );

    //-------------------------------------module_01------------------------------------------
    logic signed [WIDTH+3:0] w_twd_01_sum_re [0:15];  //<5.6> * <2.8> -> <7.14> -> <7.6>
    logic signed [WIDTH+3:0] w_twd_01_sum_im [0:15];  //<5.6> * <2.8> -> <7.14> -> <7.6>
    logic signed [WIDTH+3:0] w_twd_01_diff_re[0:15];  //<5.6> * <2.8> -> <7.14> -> <7.6>
    logic signed [WIDTH+3:0] w_twd_01_diff_im[0:15];  //<5.6> * <2.8> -> <7.14> -> <7.6>
    logic w_shift_02_valid;

    module_01 #(
        .WIDTH(10)
    ) U_MODULE_01 (
        .clk(clk),
        .rstn(rstn),
        //input  logic                    fft_mode,    // IFFT 모드용 켤레 처리
        .twd_00_sum_re(w_twd_00_sum_re),
        .twd_00_sum_im(w_twd_00_sum_im),
        .twd_00_diff_re(w_twd_00_diff_re),
        .twd_00_diff_im(w_twd_00_diff_im),
        .shift_01_valid(w_shift_01_valid),
        .twd_01_sum_re(w_twd_01_sum_re),
        .twd_01_sum_im(w_twd_01_sum_im),
        .twd_01_diff_re(w_twd_01_diff_re),
        .twd_01_diff_im(w_twd_01_diff_im),
        .shift_02_valid(w_shift_02_valid)
    );

    //-------------------------------------module_02------------------------------------------
    logic signed [WIDTH+13:0] w_twd_02_sum_re[0:15];  //<7.6>
    logic signed [WIDTH+13:0] w_twd_02_sum_im[0:15];  //<7.6>
    logic signed [WIDTH+13:0] w_twd_02_diff_re[0:15];  //<7.6>
    logic signed [WIDTH+13:0] w_twd_02_diff_im[0:15];  //<7.6>
    logic w_cbfp_valid;

    module_02 #(
        .WIDTH(13)
    ) U_MODULE_02 (
        .clk           (clk),
        .rstn          (rstn),
        //input  logic                    fft_mode,    // IFFT 모드용 켤레 처리
        .twd_01_sum_re (w_twd_01_sum_re),
        .twd_01_sum_im (w_twd_01_sum_im),
        .twd_01_diff_re(w_twd_01_diff_re),
        .twd_01_diff_im(w_twd_01_diff_im),
        .shift_02_valid(w_shift_02_valid),  //  w_twd01_valid
        .twd_02_sum_re (w_twd_02_sum_re),
        .twd_02_sum_im (w_twd_02_sum_im),
        .twd_02_diff_re(w_twd_02_diff_re),
        .twd_02_diff_im(w_twd_02_diff_im),
        .CBFP_valid    (w_cbfp_valid)
    );

endmodule
