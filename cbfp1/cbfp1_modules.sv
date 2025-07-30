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

    // 각 블록별 최소 index 계산
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

    // 각 블록별 Shift Amount 계산 (내부 사용만)
    logic signed [$clog2(IN_W):0] shift_amt[NBLOCKS-1:0];
    for (blk = 0; blk < NBLOCKS; blk++) begin : gen_shift_amt
        always_comb begin
            // 디버그용: MATLAB의 실제 shift amount 표시
            if (block_min_idx[blk] > TRUNC_VALUE)
                shift_amt[blk] = TRUNC_VALUE; // right shift amount after left shift
            else
                shift_amt[blk] = TRUNC_VALUE - block_min_idx[blk]; // direct right shift
        end
    end

    // 각 블록별로 해당하는 shift_amt 적용 (MATLAB 방식)
    always_comb begin
        for (int ch = 0; ch < NCHAN; ch++) begin
            int block_id = ch / BLOCK_SIZE;
            logic signed [IN_W-1:0] shifted_re, shifted_im;
            
            // MATLAB CBFP 로직 구현
            if (block_min_idx[block_id] > TRUNC_VALUE) begin
                // cnt2_re(ii)>13 case: bitshift(bitshift(data, cnt2_re), -13)
                logic signed [IN_W+$clog2(IN_W)-1:0] temp_re, temp_im;
                temp_re = data_re_in[ch] <<< block_min_idx[block_id];
                temp_im = data_im_in[ch] <<< block_min_idx[block_id];
                shifted_re = temp_re >>> TRUNC_VALUE;
                shifted_im = temp_im >>> TRUNC_VALUE;
            end else begin
                // cnt2_re(ii)<=13 case: bitshift(data, (-13+cnt2_re))
                shifted_re = data_re_in[ch] >>> (TRUNC_VALUE - block_min_idx[block_id]);
                shifted_im = data_im_in[ch] >>> (TRUNC_VALUE - block_min_idx[block_id]);
            end
            
            // 최종 OUT_W 비트로 truncation
            data_re_out[ch] = shifted_re[OUT_W-1:0];
            data_im_out[ch] = shifted_im[OUT_W-1:0];
        end
    end

    // valid_out 파이프라인 (1clk 지연)
    logic valid_d;
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn)
            valid_d <= 1'b0;
        else
            valid_d <= valid_in;
    end
    assign valid_out = valid_d;

endmodule
`default_nettype wire
