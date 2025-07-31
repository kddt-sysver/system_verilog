`timescale 1ns / 1ps

module top_cbfp0 #(
    parameter int IN_W        = 23,  //<10.13>
    parameter int OUT_W       = 11,  //<5.6>
    parameter int NCHAN       = 16,  //한 번에 처리하는 데이터 수
    parameter int TRUNC_VALUE = 12   //잘라야하는 값
) (
    input  logic                    clk,
    input  logic                    rstn,
    input  logic signed [ IN_W-1:0] twd_02_sum_re    [     0:15],
    input  logic signed [ IN_W-1:0] twd_02_sum_im    [     0:15],
    input  logic signed [ IN_W-1:0] twd_02_diff_re   [     0:15],
    input  logic signed [ IN_W-1:0] twd_02_diff_im   [     0:15],
    input  logic                    CBFP_valid,
    output logic signed [OUT_W-1:0] data_re_out      [NCHAN-1:0],
    output logic signed [OUT_W-1:0] data_im_out      [NCHAN-1:0],
    output logic        [      4:0] idx0             [     0:15],  //cbfp0 idx
    output logic                    shift10_valid_out
);

    logic signed [IN_W-1:0] shift_diff_data_re[0:15];
    logic signed [IN_W-1:0] shift_diff_data_im[0:15];
    logic signed [IN_W-1:0] i_re_data[0:15];
    logic signed [IN_W-1:0] i_im_data[0:15];
    logic [2:0] cbfp0_cnt;
    logic w_valid_out_d;
    logic w_valid_out;
    assign i_re_data = (cbfp0_cnt < 4) ? twd_02_sum_re : shift_diff_data_re;
    assign i_im_data = (cbfp0_cnt < 4) ? twd_02_sum_im : shift_diff_data_im;

    counter_v3 #(
        .PULSE_CYCLES(32)
    ) U_TOPCBFP_CNT_V3 (
        .clk(clk),
        .rstn(rstn),
        .en(CBFP_valid),  // 트리거 신호 (펄스 or 레벨)
        .out_pulse(w_valid_out)  // en 들어온 즉시 1, PULSE_CYCLES 동안 유지
    );

    always_ff @(posedge clk or negedge rstn) begin : blockName
        if (!rstn) begin
            w_valid_out_d <= 0;
        end else begin
            w_valid_out_d <= w_valid_out;
        end
    end

    counter #(
        .COUNT_MAX_VAL(3)      // 카운트 폭을 직접 지정 (예: 4비트 → 0..15 순환)
    ) U_TOPCBFP_CNT (
        .clk      (clk),
        .rstn     (rstn),
        .en       (w_valid_out_d),  // 카운트 인에이블
        .count_out(cbfp0_cnt)       // 현재 카운트 값
    );

    shift_reg #(
        .WIDTH(IN_W),
        .MEM_DEPTH(64)  // 예: 256, 128, 64 등 단계에 따라 설정
    ) U_MODULE0_SHIFT (
        .clk(clk),
        .rstn(rstn),
        .din_re(twd_02_diff_re),
        .din_im(twd_02_diff_im),
        .valid(w_valid_out),
        .shift_data_re(shift_diff_data_re),
        .shift_data_im(shift_diff_data_im)
    );

    cbfp0_module #(
        .IN_W       (IN_W),        //<10.13>
        .OUT_W      (OUT_W),       //<5.6>
        .NCHAN      (NCHAN),       //한 번에 처리하는 데이터 수
        .TRUNC_VALUE(TRUNC_VALUE)  //잘라야하는 값
    ) U_CBFP0 (
        .clk(clk),
        .rstn(rstn),
        .valid_in(w_valid_out),
        .data_re_in(i_re_data),
        .data_im_in(i_im_data),
        .data_re_out(data_re_out),
        .data_im_out(data_im_out),
        .valid_out(shift10_valid_out),
        .idx0(idx0)
    );
endmodule
