`timescale 1ns / 1ps

module module_00 #(
    parameter WIDTH = 9
) (
    input logic clk,
    input logic rstn,
    //input  logic                    fft_mode,    // IFFT 모드용 켤레 처리

    input signed [WIDTH-1:0] in_i     [0:15],
    input signed [WIDTH-1:0] in_q     [0:15],
    input                    din_valid,

    output logic signed [WIDTH:0] twd_00_sum_re [0:15],
    output logic signed [WIDTH:0] twd_00_sum_im [0:15],
    output logic signed [WIDTH:0] twd_00_diff_re[0:15],
    output logic signed [WIDTH:0] twd_00_diff_im[0:15],
    output logic                  shift_01_valid
);
    int i;
    logic signed [WIDTH-1:0] w_shift_data_re[0:15];
    logic signed [WIDTH-1:0] w_shift_data_im[0:15];

    logic signed [WIDTH:0] w_00bfly_sum_re[0:15];  //<4.6>
    logic signed [WIDTH:0] w_00bfly_sum_im[0:15];  //<4.6>
    logic signed [WIDTH:0] w_00bfly_diff_re[0:15];  //<4.6>
    logic signed [WIDTH:0] w_00bfly_diff_im[0:15];  //<4.6>

    logic w_twd00_valid;
    logic w_bfly00_valid;

    assign shift_01_valid = w_twd00_valid;

    shift_reg #(
        .WIDTH(WIDTH),
        .MEM_DEPTH(256)  // 예: 256, 128, 64 등 단계에 따라 설정
    ) U_SHIFT_REG00 (
        .clk(clk),
        .rstn(rstn),
        .din_re(in_i),
        .din_im(in_q),
        .valid(din_valid),
        .shift_data_re(w_shift_data_re),
        .shift_data_im(w_shift_data_im)
    );

    counter_v2 #(
        .COUNT_MAX_VAL(32), 
        .DIV_RATIO(16)    
    ) U_BFLY_VALID_CNT(
        .clk(clk),
        .rstn(rstn),
        .en(din_valid),             
        .out_pulse(w_bfly00_valid)      
    );

    bfly #(
        .WIDTH(WIDTH)
    ) U_BFLY00 (
        .clk          (clk),
        .rstn         (rstn),
        .bfly_valid   (w_bfly00_valid),  // 연산 시 HIGH
        .din_re       (in_i),
        .din_im       (in_q),
        .shift_data_re(w_shift_data_re),
        .shift_data_im(w_shift_data_im),
        .bfly_sum_re  (w_00bfly_sum_re),
        .bfly_sum_im  (w_00bfly_sum_im),
        .bfly_diff_re (w_00bfly_diff_re),
        .bfly_diff_im (w_00bfly_diff_im),
        .twiddle_valid(w_twd00_valid)
    );

    //-------------------------------------twiddle_00 start-------------------------------------
    twd_mul00 #(
        .WIDTH  (9),
        .CLK_CNT(4)
    ) U_TWD_MUL00 (
        .clk(clk),
        .rstn(rstn),
        .twd00_valid(w_twd00_valid),
        .i_00bfly_sum_re(w_00bfly_sum_re),  //<4.6>
        .i_00bfly_sum_im(w_00bfly_sum_im),
        .i_00bfly_diff_re(w_00bfly_diff_re),
        .i_00bfly_diff_im(w_00bfly_diff_im),
        .twd_00_sum_re(twd_00_sum_re),
        .twd_00_sum_im(twd_00_sum_im),
        .twd_00_diff_re(twd_00_diff_re),
        .twd_00_diff_im(twd_00_diff_im)
    );
    //-------------------------------------twiddle_00 end---------------------------------------
endmodule
