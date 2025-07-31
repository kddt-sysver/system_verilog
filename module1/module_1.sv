module module_1 #(
    parameter int WIDTH = 11
) (
    input logic clk,
    input logic rstn,
    //input  logic                    fft_mode,    // IFFT 모드용 켤레 처리

    input signed [WIDTH-1:0] module_0_out_re[0:15],
    input signed [WIDTH-1:0] module_0_out_im[0:15],
    input                    module1_valid,

    output logic signed [WIDTH:0] module_1_out_re[0:15],
    output logic signed [WIDTH:0] module_1_out_im[0:15],
    output logic        [    4:0] idx1           [0:15],
    output logic                  module2_valid
);
    int i;

    //-------------------------------------module_00------------------------------------------
    logic signed [WIDTH:0] w_twd_10_sum_re[0:15];  // <6.6>
    logic signed [WIDTH:0] w_twd_10_sum_im[0:15];
    logic signed [WIDTH:0] w_twd_10_diff_re[0:15];
    logic signed [WIDTH:0] w_twd_10_diff_im[0:15];
    logic w_shift_11_valid;

    module_10 #(
        .WIDTH(11)
    ) U_MODULE_10 (
        .clk(clk),
        .rstn(rstn),
        //input  logic                    fft_mode,    // IFFT 모드용 켤레 처리
        .module_0_out_re(module_0_out_re),
        .module_0_out_im(module_0_out_im),
        .module1_valid(module1_valid),
        .twd_10_sum_re(w_twd_10_sum_re),
        .twd_10_sum_im(w_twd_10_sum_im),
        .twd_10_diff_re(w_twd_10_diff_re),
        .twd_10_diff_im(w_twd_10_diff_im),
        .shift_11_valid(w_shift_11_valid)
    );

    //-------------------------------------module_01------------------------------------------
    logic signed [WIDTH+3:0] w_twd_11_sum_re [0:15];  // <7.6> * <2.8> -> <9.14> -> <9.6>
    logic signed [WIDTH+3:0] w_twd_11_sum_im[0:15];
    logic signed [WIDTH+3:0] w_twd_11_diff_re[0:15];
    logic signed [WIDTH+3:0] w_twd_11_diff_im[0:15];
    logic w_shift_12_valid;

    module_11 #(
        .WIDTH(12)
    ) U_MODULE_11 (
        .clk(clk),
        .rstn(rstn),
        //input  logic                    fft_mode,    // IFFT 모드용 켤레 처리
        .twd_10_sum_re(w_twd_10_sum_re),
        .twd_10_sum_im(w_twd_10_sum_im),
        .twd_10_diff_re(w_twd_10_diff_re),
        .twd_10_diff_im(w_twd_10_diff_im),
        .shift_11_valid(w_shift_11_valid),
        .twd_11_sum_re(w_twd_11_sum_re),
        .twd_11_sum_im(w_twd_11_sum_im),
        .twd_11_diff_re(w_twd_11_diff_re),
        .twd_11_diff_im(w_twd_11_diff_im),
        .shift_12_valid(w_shift_12_valid)
    );

    //-------------------------------------module_02------------------------------------------
    logic signed [WIDTH+13:0] w_twd_12_re[0:15];  // <12.13>
    logic signed [WIDTH+13:0] w_twd_12_im[0:15];
    logic w_cbfp_valid;

    module_12 #(
        .WIDTH(15)
    ) U_MODULE_12 (
        .clk           (clk),
        .rstn          (rstn),
        //input  logic                    fft_mode,    // IFFT 모드용 켤레 처리
        .twd_11_sum_re (w_twd_11_sum_re),
        .twd_11_sum_im (w_twd_11_sum_im),
        .twd_11_diff_re(w_twd_11_diff_re),
        .twd_11_diff_im(w_twd_11_diff_im),
        .shift_12_valid(w_shift_12_valid),
        .twd_12_re     (w_twd_12_re),
        .twd_12_im     (w_twd_12_im),
        .CBFP_valid    (w_cbfp_valid)
    );

    //-------------------------------------CBFP------------------------------------------
    
    top_cbfp1 #(
        .IN_W       (25),  //<12.13>
        .OUT_W      (12),  //<6.6>
        .NCHAN      (16),  // 매 clk 16샘플(2블록)
        .BLOCK_SIZE (8),
        .NBLOCKS    (2),
        .TRUNC_VALUE(13)
    ) U_CBFP_1 (
        .clk(clk),
        .rstn(rstn),
        .data_re_in(w_twd_12_re),
        .data_im_in(w_twd_12_im),
        .valid_in(w_cbfp_valid),
        .data_re_out(module_1_out_re),
        .data_im_out(module_1_out_im),
        .idx1(idx1),  // 블록별 동일 idx
        .valid_out(module2_valid)
    );
    

endmodule
