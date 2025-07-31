`timescale 1ns / 1ps

module module_01 #(
    parameter int WIDTH = 10
) (
    input logic clk,
    input logic rstn,
    //input  logic                    fft_mode,    // IFFT 모드용 켤레 처리

    input logic signed [WIDTH-1:0] twd_00_sum_re [0:15],
    input logic signed [WIDTH-1:0] twd_00_sum_im [0:15],
    input logic signed [WIDTH-1:0] twd_00_diff_re[0:15],
    input logic signed [WIDTH-1:0] twd_00_diff_im[0:15],
    input logic                    shift_01_valid,

    output logic signed [WIDTH+2:0] twd_01_sum_re [0:15],
    output logic signed [WIDTH+2:0] twd_01_sum_im [0:15],
    output logic signed [WIDTH+2:0] twd_01_diff_re[0:15],
    output logic signed [WIDTH+2:0] twd_01_diff_im[0:15],
    output logic                    shift_02_valid
);
    logic signed [WIDTH-1:0] w_shift_data00_re[0:15];
    logic signed [WIDTH-1:0] w_shift_data00_im[0:15];

    logic signed [WIDTH-1:0] w_twd_00_diff_re[0:15];
    logic signed [WIDTH-1:0] w_twd_00_diff_im[0:15];

    logic signed [WIDTH-1:0] twd_data00_re[0:15];
    logic signed [WIDTH-1:0] twd_data00_im[0:15];

    logic signed [WIDTH:0] w_01bfly_sum_re[0:15];
    logic signed [WIDTH:0] w_01bfly_sum_im[0:15];
    logic signed [WIDTH:0] w_01bfly_diff_re[0:15];
    logic signed [WIDTH:0] w_01bfly_diff_im[0:15];

    logic w_bfly01_valid;
    logic w_shift_valid;
    logic w_twd01_valid;
    logic [4:0] w_cnt;


    assign shift_02_valid = w_twd01_valid;

    assign twd_data00_re  = (w_cnt < 16) ? twd_00_sum_re : w_twd_00_diff_re;
    assign twd_data00_im  = (w_cnt < 16) ? twd_00_sum_im : w_twd_00_diff_im;

    counter_v3 #(
        .PULSE_CYCLES(32)  // 유지할 펄스 길이
    ) U_SHIFT_VALID_CNT (
        .clk      (clk),
        .rstn     (rstn),
        .en       (shift_01_valid),  // 트리거 신호
        .out_pulse(w_shift_valid)    // PULSE_CYCLES 동안 1 유지
    );

    shift_reg #(
        .WIDTH(WIDTH),
        .MEM_DEPTH(256)  // 예: 256, 128, 64 등 단계에 따라 설정
    ) U_SHIFT_REG01_1 (
        .clk(clk),
        .rstn(rstn),
        .din_re(twd_00_diff_re),
        .din_im(twd_00_diff_im),
        .valid(w_shift_valid),
        .shift_data_re(w_twd_00_diff_re),
        .shift_data_im(w_twd_00_diff_im)
    );

    counter #(
        .COUNT_MAX_VAL(5)
    ) U_cnt (
        .clk      (clk),
        .rstn     (rstn),
        .en       (shift_01_valid),
        .count_out(w_cnt)
    );

    counter_v2 #(
        .COUNT_MAX_VAL(32),
        .DIV_RATIO(8)
    ) U_BFLY_VALID_CNT (
        .clk(clk),
        .rstn(rstn),
        .en(shift_01_valid),
        .out_pulse(w_bfly01_valid)
    );

    shift_reg #(
        .WIDTH(WIDTH),
        .MEM_DEPTH(128)  // 예: 256, 128, 64 등 단계에 따라 설정
    ) U_SHIFT_REG01_2 (
        .clk(clk),
        .rstn(rstn),
        .din_re(twd_data00_re),
        .din_im(twd_data00_im),
        .valid(w_shift_valid),
        .shift_data_re(w_shift_data00_re),
        .shift_data_im(w_shift_data00_im)
    );

    bfly #(
        .WIDTH(WIDTH)
    ) U_BFLY01 (
        .clk          (clk),
        .rstn         (rstn),
        .bfly_valid   (w_bfly01_valid),     // 연산 시 HIGH
        .din_re       (twd_data00_re),
        .din_im       (twd_data00_im),
        .shift_data_re(w_shift_data00_re),
        .shift_data_im(w_shift_data00_im),
        .bfly_sum_re  (w_01bfly_sum_re),
        .bfly_sum_im  (w_01bfly_sum_im),
        .bfly_diff_re (w_01bfly_diff_re),
        .bfly_diff_im (w_01bfly_diff_im),
        .twiddle_valid(w_twd01_valid)
    );

    //-------------------------------------twiddle_01 start-------------------------------------

    twd_mul01 #(
        .WIDTH  (9),
        .CLK_CNT(4)
    ) U_TWD_MUL01 (
        .clk(clk),
        .rstn(rstn),
        .twd01_valid(w_twd01_valid),
        .i_01bfly_sum_re(w_01bfly_sum_re),  //<5.6>
        .i_01bfly_sum_im(w_01bfly_sum_im),  //<5.6>
        .i_01bfly_diff_re(w_01bfly_diff_re),  //<5.6>
        .i_01bfly_diff_im(w_01bfly_diff_im),  //<5.6>
        .twd_01bfly_sum_re(twd_01_sum_re),  //<5.6> * <2.8> -> <7.14> -> <7.6>
        .twd_01bfly_sum_im(twd_01_sum_im),  //<5.6> * <2.8> -> <7.14> -> <7.6>
        .twd_01bfly_diff_re(twd_01_diff_re),  //<5.6> * <2.8> -> <7.14> -> <7.6>
        .twd_01bfly_diff_im(twd_01_diff_im)  //<5.6> * <2.8> -> <7.14> -> <7.6>
    );
    //-------------------------------------twiddle_01 end---------------------------------------
endmodule
