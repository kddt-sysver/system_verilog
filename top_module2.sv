`timescale 1ns / 1ps

module module_2 #(
    parameter int WIDTH = 12
) (
    input logic clk,
    input logic rstn,

    input  signed [WIDTH-1:0] in_i [0:15],
    input  signed [WIDTH-1:0] in_q [0:15],
    input                    din_valid,

    output logic signed [WIDTH:0] module_20_out_re[0:15], //<8.6>
    output logic signed [WIDTH:0] module_20_out_im[0:15], //<8.6>
    output logic                    module2_valid
);

    //-------------------------------------module_20------------------------------------------
    logic signed [WIDTH:0] w_twd_20_sum_re [0:15];  //<7.6>
    logic signed [WIDTH:0] w_twd_20_sum_im [0:15];  //<7.6>
    logic signed [WIDTH:0] w_twd_20_diff_re[0:15];  //<7.6>
    logic signed [WIDTH:0] w_twd_20_diff_im[0:15];  //<7.6>
    logic w_shift_21_valid;

    module_20 #(
        .WIDTH(WIDTH)
    ) U_MODULE_20 (
        .clk        (clk),
        .rstn       (rstn),
        //input logic
        .in_i      (in_i),
        .in_q      (in_q),
        .din_valid  (din_valid),
        .twd_20_sum_re     (w_twd_20_sum_re),
        .twd_20_sum_im     (w_twd_20_sum_im),
        .twd_20_diff_re    (w_twd_20_diff_re),
        .twd_20_diff_im    (w_twd_20_diff_im),
        .shift_21valid_out  (w_shift_21_valid)
    );

    //-------------------------------------module_21------------------------------------------
    logic signed [WIDTH+2:0] w_twd_21_sum_re [0:15];  //<7.6> * <2.7> -> <9.13> -> <9.6>
    logic signed [WIDTH+2:0] w_twd_21_sum_im [0:15];  //<7.6> * <2.7> -> <9.13> -> <9.6>  
    logic signed [WIDTH+2:0] w_twd_21_diff_re[0:15];  //<7.6> * <2.7> -> <9.13> -> <9.6>
    logic signed [WIDTH+2:0] w_twd_21_diff_im[0:15];  //<7.6> * <2.7> -> <9.13> -> <9.6>
    logic w_shift_22_valid;

    module_21 #(
        .WIDTH(WIDTH+1)
    ) U_MODULE_21 (
        .clk         (clk),
        .rstn        (rstn),
        //input logic                      fft_mode,   /ifft어쩌구저쩌구
        .twd_20_sum_re   (w_twd_20_sum_re),
        .twd_20_sum_im   (w_twd_20_sum_im),
        .twd_20_diff_re  (w_twd_20_diff_re),
        .twd_20_diff_im  (w_twd_20_diff_im),
        .shift_21_valid    (w_shift_21_valid),
        .twd_21_sum_re  (w_twd_21_sum_re),
        .twd_21_sum_im  (w_twd_21_sum_im),
        .twd_21_diff_re (w_twd_21_diff_re),
        .twd_21_diff_im (w_twd_21_diff_im),
        .shift_22_valid   (w_shift_22_valid)
    );

    //-------------------------------------module_22------------------------------------------
    logic signed [WIDTH+1:0] module_22_out_re[0:15];  //<8.6>
    logic signed [WIDTH+1:0] module_22_out_im[0:15];  //<8.6>
    
    
    module_22 #(
        .WIDTH(WIDTH+3)
    ) U_MODULE_22 (
        .clk         (clk),
        .rstn        (rstn),
        //input logic
        .twd_21_sum_re_in   (w_twd_21_sum_re),
        .twd_21_sum_im_in   (w_twd_21_sum_im),
        .twd_21_diff_re_in  (w_twd_21_diff_re),
        .twd_21_diff_im_in  (w_twd_21_diff_im),
        .shift_22_valid     (w_shift_22_valid),
        .out_re      (module_22_out_re),
        .out_im      (module_22_out_im),
        .valid_out   (module2_valid)
    );

endmodule
