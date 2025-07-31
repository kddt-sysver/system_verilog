`timescale 1ns / 1ps

module top_fft_fixed #(
    parameter WIDTH = 9
) (
    input logic clk,
    input logic rstn,
    //input logic fft_mode, // 0: ifft, 1: fft

    input signed [WIDTH-1:0] din_i    [0:15],
    input signed [WIDTH-1:0] din_q    [0:15],
    input                    din_valid,

    output logic signed [WIDTH+3:0] dout_re[0:511],
    output logic signed [WIDTH+3:0] dout_im[0:511],
    output logic                    dout_en
);

    //-------------------------------------module_0------------------------------------------
    // input <3.6> -> output <5.6>
    logic signed [WIDTH+1:0] w_module_0_out_re[0:15];
    logic signed [WIDTH+1:0] w_module_0_out_im[0:15];
    logic [4:0] w_idx0[0:15];
    logic [4:0] idx0_delay[0:7][0:15];
    logic [4:0] w_idx0_d[0:15];
    logic w_module_1_valid;

    module_0 #(
        .WIDTH(9)
    ) U_MODULE_0 (
        .clk(clk),
        .rstn(rstn),
        .in_i(din_i),
        .in_q(din_q),
        .din_valid(din_valid),
        .module_0_out_re(w_module_0_out_re),
        .module_0_out_im(w_module_0_out_im),
        .idx0(w_idx0),  //cbfp0 idx
        .module1_valid(w_module_1_valid)
    );
    always_ff @(posedge clk or posedge rstn) begin
        if (!rstn) begin
            for (int j = 0; j < 16; j++) begin
                idx0_delay[0][j] <= 0;
                idx0_delay[1][j] <= 0;
                idx0_delay[2][j] <= 0;
                idx0_delay[3][j] <= 0;
                idx0_delay[4][j] <= 0;
                idx0_delay[5][j] <= 0;
                idx0_delay[6][j] <= 0;
                idx0_delay[7][j] <= 0;
                w_idx0_d[j] <= 0;
            end
        end else begin
            for (int j = 0; j < 16; j++) begin
                idx0_delay[0][j] <= w_idx0[j];
                idx0_delay[1][j] <= idx0_delay[0][j];
                idx0_delay[2][j] <= idx0_delay[1][j];
                idx0_delay[3][j] <= idx0_delay[2][j];
                idx0_delay[4][j] <= idx0_delay[3][j];
                idx0_delay[5][j] <= idx0_delay[4][j];
                idx0_delay[6][j] <= idx0_delay[5][j];
                idx0_delay[7][j] <= idx0_delay[6][j];
                w_idx0_d[j] <= idx0_delay[7][j];
            end
        end
    end
    //-------------------------------------module_1------------------------------------------
    // input <5.6> -> output <6.6>
    logic signed [WIDTH+2:0] w_module_1_out_re[0:15];
    logic signed [WIDTH+2:0] w_module_1_out_im[0:15];
    logic [4:0] w_idx1_d[0:15];
    logic [4:0] w_idx1[0:15];
    logic [4:0] idx1_delay[0:1][0:15];
    logic w_module_2_valid;

    module_1 #(
        .WIDTH(9)
    ) U_MODULE_1 (
        .clk(clk),
        .rstn(rstn),
        .module_0_out_re(w_module_0_out_re),
        .module_0_out_im(w_module_0_out_im),
        .module1_valid(w_module_1_valid),
        .module_1_out_re(w_module_1_out_re),
        .module_1_out_im(w_module_1_out_im),
        .idx1(w_idx1),  //cbfp1 idx
        .module2_valid(w_module_2_valid)
    );
    always_ff @(posedge clk or posedge rstn) begin
        if (!rstn) begin
            for (int j = 0; j < 16; j++) begin
                idx1_delay[0][j] <= 0;
                idx1_delay[1][j] <= 0;
                w_idx1_d[j] <= 0;
            end
        end else begin
            for (int j = 0; j < 16; j++) begin
                idx1_delay[0][j] <= w_idx1[j];
                idx1_delay[1][j] <= idx1_delay[0][j];
                w_idx1_d[j] <= idx1_delay[1][j];
            end
        end
    end
    //-------------------------------------module_2------------------------------------------
    // input <6.6> -> output <11.6>
    logic signed [WIDTH+7:0] w_module_2_out_re[0:15];
    logic signed [WIDTH+7:0] w_module_2_out_im[0:15];
    logic w_cbfp_valid;

    module_2 #(
        .WIDTH(12)
    ) U_MODULE_2 (
        .clk            (clk),
        .rstn           (rstn),
        .module_1_out_re(w_module_1_out_re),
        .module_1_out_im(w_module_1_out_im),  // <6.6>
        .module2_valid  (w_module_2_valid),
        .module_2_out_re(w_module_2_out_re),
        .module_2_out_im(w_module_2_out_im),
        .CBFP_valid     (w_cbfp_valid)
    );
    //-------------------------------------CBFP2------------------------------------------

    cbfp2 U_CBFP2 (
        .clk(clk),
        .rstn(rstn),
        .idx0(w_idx0_d),  //최대 shift idx 23bit, bfly22와 9clk차이
        .cbfp2_valid(w_cbfp_valid),
        .idx1(w_idx1_d),  //최대 shift idx 25bit, bfly22와 3clk차이
        .i_bfly22_re(w_module_2_out_re),  //(+-+-+-...) 16bit
        .i_bfly22_im(w_module_2_out_im),  //(+-+-+-...) 16bit
        .dout_valid(dout_en),
        .o_cbfp2_re(dout_re),  // <9.4>
        .o_cbfp2_im(dout_im)  // <9.4>
    );

endmodule
