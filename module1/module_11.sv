
`timescale 1ns / 1ps

module module_11 #(
    parameter int WIDTH = 12
) (
    input logic clk,
    input logic rstn,
    //input  logic                    fft_mode,    // IFFT 모드용 켤레 처리

    input logic signed [WIDTH-1:0] twd_10_sum_re [0:15],
    input logic signed [WIDTH-1:0] twd_10_sum_im [0:15],
    input logic signed [WIDTH-1:0] twd_10_diff_re[0:15],
    input logic signed [WIDTH-1:0] twd_10_diff_im[0:15],
    input logic                    shift_11_valid,

    output logic signed [WIDTH+2:0] twd_11_sum_re [0:15],
    output logic signed [WIDTH+2:0] twd_11_sum_im [0:15],
    output logic signed [WIDTH+2:0] twd_11_diff_re[0:15],
    output logic signed [WIDTH+2:0] twd_11_diff_im[0:15],
    output logic                    shift_12_valid
);
    logic signed [WIDTH-1:0] w_shift_data10_re[0:15];
    logic signed [WIDTH-1:0] w_shift_data10_im[0:15];

    logic signed [WIDTH-1:0] w_twd_10_diff_re[0:15];
    logic signed [WIDTH-1:0] w_twd_10_diff_im[0:15];

    logic signed [WIDTH-1:0] twd_data10_re[0:15];
    logic signed [WIDTH-1:0] twd_data10_im[0:15];

    logic signed [WIDTH:0] w_11bfly_sum_re[0:15];
    logic signed [WIDTH:0] w_11bfly_sum_im[0:15];
    logic signed [WIDTH:0] w_11bfly_diff_re[0:15];
    logic signed [WIDTH:0] w_11bfly_diff_im[0:15];

    logic w_bfly11_valid;
    logic w_shift_valid;
    logic w_twd11_valid;
    //logic [2:0] w_cnt;


    assign shift_12_valid = w_twd11_valid;

    assign twd_data10_re  = shift_11_valid ? twd_10_sum_re : w_twd_10_diff_re;
    assign twd_data10_im  = shift_11_valid ? twd_10_sum_im : w_twd_10_diff_im;

    
    counter_v4 #(
        .PULSE_CYCLES(32)  // 유지할 펄스 길이
    ) U_SHIFT_VALID_CNT (
        .clk      (clk),
        .rstn     (rstn),
        .en       (shift_11_valid),  // 트리거 신호
        .out_pulse(w_shift_valid)    // PULSE_CYCLES 동안 1 유지
    );
    

    shift_reg #(
        .WIDTH(WIDTH),
        .MEM_DEPTH(32)  // 예: 256, 128, 64 등 단계에 따라 설정
    ) U_SHIFT_REG11_1 (
        .clk(clk),
        .rstn(rstn),
        .din_re(twd_10_diff_re),
        .din_im(twd_10_diff_im),
        .valid(w_shift_valid),
        .shift_data_re(w_twd_10_diff_re),
        .shift_data_im(w_twd_10_diff_im)
    );


    counter_v2 #(
        .COUNT_MAX_VAL(32),
        .DIV_RATIO(1)
    ) U_BFLY_VALID_CNT (
        .clk(clk),
        .rstn(rstn),
        .en(shift_11_valid),
        .out_pulse(w_bfly11_valid)
    );

    shift_reg #(
        .WIDTH(WIDTH),
        .MEM_DEPTH(16)  // 예: 256, 128, 64 등 단계에 따라 설정
    ) U_SHIFT_REG11_2 (
        .clk(clk),
        .rstn(rstn),
        .din_re(twd_data10_re),
        .din_im(twd_data10_im),
        .valid(w_shift_valid),
        .shift_data_re(w_shift_data10_re),
        .shift_data_im(w_shift_data10_im)
    );



    bfly #(
        .WIDTH(WIDTH)
    ) U_BFLY11 (
        .clk          (clk),
        .rstn         (rstn),
        .bfly_valid   (w_bfly11_valid),     // 연산 시 HIGH
        .din_re       (twd_data10_re),
        .din_im       (twd_data10_im),
        .shift_data_re(w_shift_data10_re),
        .shift_data_im(w_shift_data10_im),
        .bfly_sum_re  (w_11bfly_sum_re),
        .bfly_sum_im  (w_11bfly_sum_im),
        .bfly_diff_re (w_11bfly_diff_re),
        .bfly_diff_im (w_11bfly_diff_im),
        .twiddle_valid(w_twd11_valid)
    );

    //-------------------------------------twiddle_11 start-------------------------------------

    twd_mul11 #(
        .WIDTH  (13)
    ) U_TWD_MUL11 (
        .clk(clk),
        .rstn(rstn),
        .twd11_valid(w_twd11_valid),
        .i_11bfly_sum_re(w_11bfly_sum_re),  // <7.6>
        .i_11bfly_sum_im(w_11bfly_sum_im),  
        .i_11bfly_diff_re(w_11bfly_diff_re),
        .i_11bfly_diff_im(w_11bfly_diff_im),  
        .twd_11bfly_sum_re(twd_11_sum_re),  // <7.6> * <2.8> -> <9.14> -> <9.6>
        .twd_11bfly_sum_im(twd_11_sum_im),  
        .twd_11bfly_diff_re(twd_11_diff_re),  
        .twd_11bfly_diff_im(twd_11_diff_im)  
    );
    //-------------------------------------twiddle_11 end---------------------------------------
endmodule


