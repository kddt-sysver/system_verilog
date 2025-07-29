module module_1 #(
    parameter int WIDTH = 11
) (
    input logic clk,
    input logic rstn,
    //input  logic                    fft_mode,    // IFFT 모드용 켤레 처리

    input signed [WIDTH-1:0] module_00_out_re[0:15],
    input signed [WIDTH-1:0] module_00_out_im[0:15],
    input                    module1_valid,

    output logic signed [WIDTH:0] module_01_out_re[0:15],
    output logic signed [WIDTH:0] module_01_out_im[0:15],
    output logic                    module2_valid
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
        .module_00_out_re(module_00_out_re),
        .module_00_out_im(module_00_out_im),
        .module1_valid(module1_valid),
        .twd_10_sum_re(w_twd_10_sum_re),
        .twd_10_sum_im(w_twd_10_sum_im),
        .twd_10_diff_re(w_twd_10_diff_re),
        .twd_10_diff_im(w_twd_10_diff_im),
        .shift_11_valid(w_shift_11_valid)
    );

    //-------------------------------------module_01------------------------------------------
    logic signed [WIDTH+3:0] w_twd_11_sum_re [0:15];  // <7.6> * <2.8> -> <9.14> -> <9.6>
    logic signed [WIDTH+3:0] w_twd_11_sum_im [0:15];  
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
    logic signed [WIDTH+13:0] w_twd_12_sum_re[0:15];  // <9.6>
    logic signed [WIDTH+13:0] w_twd_12_sum_im[0:15]; 
    logic signed [WIDTH+13:0] w_twd_12_diff_re[0:15];  
    logic signed [WIDTH+13:0] w_twd_12_diff_im[0:15];  
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
        .twd_12_sum_re (w_twd_12_sum_re),
        .twd_12_sum_im (w_twd_12_sum_im),
        .twd_12_diff_re(w_twd_12_diff_re),
        .twd_12_diff_im(w_twd_12_diff_im),
        .CBFP_valid    (w_cbfp_valid)
    );

endmodule
