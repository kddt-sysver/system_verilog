`timescale 1ns / 1ps

module cbfp1_module #(
    parameter int IN_W        = 25,  //<12.13>
    parameter int OUT_W       = 12,  //<6.6>
    parameter int NCHAN       = 16,  // 병렬 처리 채널 수
    parameter int BLOCK_SIZE  = 8,   // 블록 크기 (8샘플)
    parameter int NBLOCKS     = NCHAN / BLOCK_SIZE, // 블록 개수 (2개)
    parameter int TRUNC_VALUE = 13   // MATLAB 코드 기준 (25bit -> 12bit)
)(
    input  logic                    clk,
    input  logic                    rstn,
    input  logic                    valid_in,
    input  logic signed [IN_W-1:0]  data_re_in [NCHAN-1:0],
    input  logic signed [IN_W-1:0]  data_im_in [NCHAN-1:0],
    output logic signed [OUT_W-1:0] data_re_out[NCHAN-1:0],
    output logic signed [OUT_W-1:0] data_im_out[NCHAN-1:0],
    output logic signed [$clog2(IN_W)-1:0] idx1 [NCHAN-1:0], // 블록별 동일 idx 출력
    output logic                    valid_out
);

    // Magnitude Detect
    logic [$clog2(IN_W)-1:0] mag_index_re[NCHAN-1:0];
    logic [$clog2(IN_W)-1:0] mag_index_im[NCHAN-1:0];
    logic [$clog2(IN_W)-1:0] w_mag_index_re[NCHAN-1:0];
    logic [$clog2(IN_W)-1:0] w_mag_index_im[NCHAN-1:0];
    logic [$clog2(IN_W)-1:0] min_mag_index[NCHAN-1:0];

    genvar i;
    for (i = 0; i < NCHAN; i++) begin
        mag_detect #(.WIDTH(IN_W)) u_mag_re (
            .in   (data_re_in[i]),
            .index(w_mag_index_re[i])
        );
        mag_detect #(.WIDTH(IN_W)) u_mag_im (
            .in   (data_im_in[i]),
            .index(w_mag_index_im[i])
        );
        assign mag_index_re[i] = IN_W - 2 - w_mag_index_re[i];
        assign mag_index_im[i] = IN_W - 2 - w_mag_index_im[i];
        assign min_mag_index[i] = (mag_index_re[i] < mag_index_im[i]) ?
                                  mag_index_re[i] : mag_index_im[i];
    end

    // 블록별 최소 index
    logic [$clog2(IN_W)-1:0] block_min_idx[NBLOCKS-1:0];
    genvar blk;
    for (blk = 0; blk < NBLOCKS; blk++) begin : gen_block_min
        always_comb begin
            block_min_idx[blk] = min_mag_index[blk * BLOCK_SIZE];
            for (int j = 1; j < BLOCK_SIZE; j++) begin
                if (min_mag_index[blk * BLOCK_SIZE + j] < block_min_idx[blk])
                    block_min_idx[blk] = min_mag_index[blk * BLOCK_SIZE + j];
            end
        end
    end

    // 블록별 shift 적용 + idx 출력
    always_comb begin
        for (int ch = 0; ch < NCHAN; ch++) begin
            int block_id = ch / BLOCK_SIZE;
            logic signed [IN_W-1:0] shifted_re, shifted_im;

            // 블록별 동일 index 출력
            idx1[ch] = block_min_idx[block_id];

            if (block_min_idx[block_id] > TRUNC_VALUE) begin
                logic signed [IN_W+$clog2(IN_W)-1:0] temp_re, temp_im;
                temp_re = data_re_in[ch] <<< block_min_idx[block_id];
                temp_im = data_im_in[ch] <<< block_min_idx[block_id];
                shifted_re = temp_re >>> TRUNC_VALUE;
                shifted_im = temp_im >>> TRUNC_VALUE;
            end else begin
                shifted_re = data_re_in[ch] >>> (TRUNC_VALUE - block_min_idx[block_id]);
                shifted_im = data_im_in[ch] >>> (TRUNC_VALUE - block_min_idx[block_id]);
            end

            data_re_out[ch] = shifted_re[OUT_W-1:0];
            data_im_out[ch] = shifted_im[OUT_W-1:0];
        end
    end

    // valid_out 1clk delay
    logic valid_d;
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn)
            valid_d <= 1'b0;
        else
            valid_d <= valid_in;
    end
    assign valid_out = valid_d;

endmodule
