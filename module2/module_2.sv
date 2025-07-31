`timescale 1ns / 1ps

module module_2 #(
    parameter int WIDTH = 12
) (
    input logic clk,
    input logic rstn,

    input signed [WIDTH-1:0] module_1_out_re[0:15],
    input signed [WIDTH-1:0] module_1_out_im[0:15],  // <6.6>
    input                    module2_valid,

    output logic signed [WIDTH+4:0] module_2_out_re[0:15],
    output logic signed [WIDTH+4:0] module_2_out_im[0:15],
    output logic CBFP_valid
);

    //-------------------------------------module_20------------------------------------------
    // input <6.6> -> output <7.6>
    logic signed [WIDTH:0] w_twd_20_re[0:15];  //<7.6>
    logic signed [WIDTH:0] w_twd_20_im[0:15];  //<7.6>
    logic w_shift_21_valid;

    module_20 #(
        .WIDTH(12)
    ) U_MODULE_20 (
        .clk(clk),
        .rstn(rstn),
        .module_1_out_re(module_1_out_re),  
        .module_1_out_im(module_1_out_im),  
        .module2_valid(module2_valid),
        .twd_20_re(w_twd_20_re),
        .twd_20_im(w_twd_20_im),
        .shift_21_valid(w_shift_21_valid)
    );
    //-------------------------------------module_21------------------------------------------
    // input <7.6> -> output <10.6>
    logic signed [WIDTH+3:0] w_twd_21_re [0:15];  //<8.6> * <2.8> -> <10.14> -> <10.6>
    logic signed [WIDTH+3:0] w_twd_21_im [0:15];  //<8.6> * <2.8> -> <10.14> -> <10.6>  
    logic w_shift_22_valid;

    module_21 #(
        .WIDTH(13)
    ) U_MODULE_21 (
        .clk(clk),
        .rstn(rstn),
        .twd_20_re(w_twd_20_re),  
        .twd_20_im(w_twd_20_im),
        .shift_21_valid(w_shift_21_valid),
        .twd_21_re(w_twd_21_re),
        .twd_21_im(w_twd_21_im),
        .shift_22_valid(w_shift_22_valid)
    );

    //-------------------------------------module_22------------------------------------------
    // input <10.6> -> output <11.6> 

    module_22 #(
        .WIDTH(16)
    ) U_MODULE_22 (
        .clk(clk),
        .rstn(rstn),
        .twd_21_re(w_twd_21_re),  
        .twd_21_im(w_twd_21_im),
        .shift_22_valid(w_shift_22_valid),
        .module_22_out_re(module_2_out_re),
        .module_22_out_im(module_2_out_im),
        .CBFP_valid(CBFP_valid)
    );

endmodule
