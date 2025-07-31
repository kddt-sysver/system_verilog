`timescale 1ns / 1ps

module module_10 #(
    parameter WIDTH = 11  // CBFP 후 <5.6>으로 들어옴
) (
    input logic clk,
    input logic rstn,
    //input  logic                    fft_mode,    // IFFT 모드용 켤레 처리

    input signed [WIDTH-1:0] module_0_out_re[0:15],
    input signed [WIDTH-1:0] module_0_out_im[0:15],
    input                    module1_valid,

    output logic signed [WIDTH:0] twd_10_sum_re [0:15],
    output logic signed [WIDTH:0] twd_10_sum_im [0:15],
    output logic signed [WIDTH:0] twd_10_diff_re[0:15],
    output logic signed [WIDTH:0] twd_10_diff_im[0:15],
    output logic                  shift_11_valid
);
    int i;
    logic signed [WIDTH-1:0] w_shift_data10_re[0:15];
    logic signed [WIDTH-1:0] w_shift_data10_im[0:15];

    logic signed [WIDTH:0] w_10bfly_sum_re[0:15];  // <6.6>
    logic signed [WIDTH:0] w_10bfly_sum_im[0:15];  
    logic signed [WIDTH:0] w_10bfly_diff_re[0:15];  
    logic signed [WIDTH:0] w_10bfly_diff_im[0:15];  


    logic w_twd10_valid;
    logic w_bfly10_valid;
    

    assign shift_11_valid = w_twd10_valid;

    /*
    counter_v3 #(
        .PULSE_CYCLES(32)  // 유지할 펄스 길이
    ) U_SHIFT_VALID_CNT (
        .clk      (clk),
        .rstn     (rstn),
        .en       (module1_valid),  // 트리거 신호
        .out_pulse(w_shift_valid)    // PULSE_CYCLES 동안 1 유지
    );
    */
    

    shift_reg #(
        .WIDTH(WIDTH),
        .MEM_DEPTH(32)  // 예: 256, 128, 64 등 단계에 따라 설정
    ) U_SHIFT_REG10_2 (
        .clk(clk),
        .rstn(rstn),
        .din_re(module_0_out_re),
        .din_im(module_0_out_im),
        .valid(module1_valid),
        .shift_data_re(w_shift_data10_re),
        .shift_data_im(w_shift_data10_im)
    );

    counter_v2 #(
        .COUNT_MAX_VAL(32), 
        .DIV_RATIO(2)    
    ) U_BFLY_VALID_CNT(
        .clk(clk),
        .rstn(rstn),
        .en(module1_valid),             
        .out_pulse(w_bfly10_valid)      
    );

    bfly #(
        .WIDTH(WIDTH)
    ) U_BFLY10 (
        .clk          (clk),
        .rstn         (rstn),
        .bfly_valid   (w_bfly10_valid),  // 연산 시 HIGH
        .din_re       (module_0_out_re),
        .din_im       (module_0_out_im),
        .shift_data_re(w_shift_data10_re),
        .shift_data_im(w_shift_data10_im),
        .bfly_sum_re  (w_10bfly_sum_re),
        .bfly_sum_im  (w_10bfly_sum_im),
        .bfly_diff_re (w_10bfly_diff_re),
        .bfly_diff_im (w_10bfly_diff_im),
        .twiddle_valid(w_twd10_valid)
    );

    //-------------------------------------twiddle_10 start-------------------------------------
    twd_mul10 #(
        .WIDTH  (12),
        .CLK_CNT(4)
    ) U_TWD_MUL10 (
        .clk(clk),
        .rstn(rstn),
        .twd10_valid(w_twd10_valid),
        .i_10bfly_sum_re(w_10bfly_sum_re),  
        .i_10bfly_sum_im(w_10bfly_sum_im),
        .i_10bfly_diff_re(w_10bfly_diff_re),
        .i_10bfly_diff_im(w_10bfly_diff_im),
        .twd_10_sum_re(twd_10_sum_re),
        .twd_10_sum_im(twd_10_sum_im),
        .twd_10_diff_re(twd_10_diff_re),
        .twd_10_diff_im(twd_10_diff_im)
    );
    //-------------------------------------twiddle_10 end---------------------------------------
endmodule
