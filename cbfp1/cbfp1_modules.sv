`timescale 1ns / 1ps
module top_cbfp1 #(
    parameter int IN_W        = 25,  //<12.13>
    parameter int OUT_W       = 12,  //<6.6>
    parameter int NCHAN       = 16,  // 매 clk 16샘플(2블록)
    parameter int BLOCK_SIZE  = 8,   // 블록 크기 (8샘플)
    parameter int NBLOCKS     = NCHAN / BLOCK_SIZE, // 블록 개수 (2개)
    parameter int TRUNC_VALUE = 13   // 잘라야 하는 값 (MATLAB 기준)
)(
    input  logic                    clk,
    input  logic                    rstn,
    input  logic signed [IN_W-1:0]  twd_02_sum_re  [0:NCHAN-1],
    input  logic signed [IN_W-1:0]  twd_02_sum_im  [0:NCHAN-1],
    input  logic                    CBFP_valid,   // valid_in
    output logic signed [OUT_W-1:0] data_re_out   [0:NCHAN-1],
    output logic signed [OUT_W-1:0] data_im_out   [0:NCHAN-1],
    output logic                    shift10_valid_out
);

    // CBFP1 모듈 직접 연결
    cbfp1_module #(
        .IN_W       (IN_W),
        .OUT_W      (OUT_W),
        .NCHAN      (NCHAN),
        .BLOCK_SIZE (BLOCK_SIZE),     // 추가
        .NBLOCKS    (NBLOCKS),        // 추가
        .TRUNC_VALUE(TRUNC_VALUE)
    ) U_CBFP1 (
        .clk        (clk),
        .rstn       (rstn),
        .valid_in   (CBFP_valid),     // 외부에서 바로 valid_in
        .data_re_in (twd_02_sum_re),
        .data_im_in (twd_02_sum_im),
        .data_re_out(data_re_out),
        .data_im_out(data_im_out),
        .valid_out  (shift10_valid_out)
    );

endmodule
`default_nettype wire
