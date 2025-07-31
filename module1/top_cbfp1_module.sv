`timescale 1ns / 1ps

module top_cbfp1 #(
    parameter int IN_W        = 25,  //<12.13>
    parameter int OUT_W       = 12,  //<6.6>
    parameter int NCHAN       = 16,  // 매 clk 16샘플(2블록)
    parameter int BLOCK_SIZE  = 8,
    parameter int NBLOCKS     = NCHAN / BLOCK_SIZE,
    parameter int TRUNC_VALUE = 13
)(
    input  logic                    clk,
    input  logic                    rstn,
    input  logic signed [IN_W-1:0]  data_re_in [0:NCHAN-1],
    input  logic signed [IN_W-1:0]  data_im_in [0:NCHAN-1],
    input  logic                    valid_in,
    output logic signed [OUT_W-1:0] data_re_out [0:NCHAN-1],
    output logic signed [OUT_W-1:0] data_im_out [0:NCHAN-1],
    output logic signed [$clog2(IN_W)-1:0] idx1 [0:NCHAN-1], // 블록별 동일 idx
    output logic                    valid_out
);

    cbfp1_module #(
        .IN_W       (IN_W),
        .OUT_W      (OUT_W),
        .NCHAN      (NCHAN),
        .BLOCK_SIZE (BLOCK_SIZE),
        .NBLOCKS    (NBLOCKS),
        .TRUNC_VALUE(TRUNC_VALUE)
    ) U_CBFP1 (
        .clk        (clk),
        .rstn       (rstn),
        .valid_in   (valid_in),
        .data_re_in (data_re_in),
        .data_im_in (data_im_in),
        .data_re_out(data_re_out),
        .data_im_out(data_im_out),
        .idx1       (idx1),
        .valid_out  (valid_out)
    );

endmodule
