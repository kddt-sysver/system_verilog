`timescale 1ns / 1ps

module cbfp0_module #(
    parameter int IN_W        = 23,  //<10.13>
    parameter int OUT_W       = 11,  //<5.6>
    parameter int NCHAN       = 16,  //한 번에 처리하는 데이터 수
    parameter int TRUNC_VALUE = 12   //잘라야하는 값
) (
    input  logic                    clk,
    input  logic                    rstn,
    input  logic                    valid_in,
    input  logic signed [ IN_W-1:0] data_re_in [NCHAN-1:0],
    input  logic signed [ IN_W-1:0] data_im_in [NCHAN-1:0],
    output logic signed [OUT_W-1:0] data_re_out[NCHAN-1:0],
    output logic signed [OUT_W-1:0] data_im_out[NCHAN-1:0],
    output logic        [      4:0] idx0       [     0:15],  //cbfp0 idx
    output logic                    valid_out
);

    logic signed [IN_W-1:0] shift_data_re[NCHAN-1:0];
    logic signed [IN_W-1:0] shift_data_im[NCHAN-1:0];
    logic [1:0] cbfp_cnt;
    logic valid_in_d;
    logic shift_valid;
    logic valid_out_trigg;
    logic valid_pipe[4:0];
    // 최종 valid_out은 데이터가 유효한 시점에 나감
    assign valid_out_trigg = valid_pipe[4];

    counter_v3 #(
        .PULSE_CYCLES(36)
    ) U_CBFP_SHIFT_CNT_V3 (
        .clk(clk),
        .rstn(rstn),
        .en(valid_in),  // 트리거 신호 (펄스 or 레벨)
        .out_pulse(shift_valid)  // en 들어온 즉시 1, PULSE_CYCLES 동안 유지
    );

    shift_reg #(
        .WIDTH(IN_W),
        .MEM_DEPTH(64)  // 예: 256, 128, 64 등 단계에 따라 설정
    ) U_CBFP_SHIFT (
        .clk(clk),
        .rstn(rstn),
        .din_re(data_re_in),
        .din_im(data_im_in),
        .valid(shift_valid),
        .shift_data_re(shift_data_re),
        .shift_data_im(shift_data_im)
    );

    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            valid_in_d <= 0;
        end else begin
            valid_in_d <= valid_in;
        end
    end

    counter #(
        .COUNT_MAX_VAL(2)      // 카운트 폭을 직접 지정 (예: 4비트 → 0..15 순환)
    ) U_CBFP_CNT (
        .clk      (clk),
        .rstn     (rstn),
        .en       (valid_in_d),  // 카운트 인에이블
        .count_out(cbfp_cnt)     // 현재 카운트 값
    );

    logic [$clog2(IN_W)-1:0] mag_index_re  [NCHAN-1:0];
    logic [$clog2(IN_W)-1:0] mag_index_im  [NCHAN-1:0];
    logic [$clog2(IN_W)-1:0] w_mag_index_re[NCHAN-1:0];
    logic [$clog2(IN_W)-1:0] w_mag_index_im[NCHAN-1:0];
    logic [$clog2(IN_W)-1:0] min_mag_index [NCHAN-1:0];

    genvar i;
    for (i = 0; i < NCHAN; i++) begin
        mag_detect #(
            .WIDTH(IN_W)
        ) u_mag_re (
            .in   (data_re_in[i]),
            .index(w_mag_index_re[i])
        );
        mag_detect #(
            .WIDTH(IN_W)
        ) u_mag_im (
            .in   (data_im_in[i]),
            .index(w_mag_index_im[i])
        );
        assign mag_index_re[i] = IN_W - 2 - w_mag_index_re[i];
        assign mag_index_im[i] = IN_W - 2 - w_mag_index_im[i];
        assign min_mag_index[i] = (mag_index_re[i] < mag_index_im[i]) ?
                                       mag_index_re[i] : mag_index_im[i];
    end

    logic [$clog2(IN_W)-1:0] cur_min_mag_idx[3:0];

    always_comb begin
        cur_min_mag_idx[cbfp_cnt] = min_mag_index[0];
        for (int j = 1; j < NCHAN; j++) begin
            if (min_mag_index[j] < cur_min_mag_idx[cbfp_cnt]) begin
                cur_min_mag_idx[cbfp_cnt] = min_mag_index[j];
            end
        end
    end


    logic [$clog2(IN_W)-1:0] final_cur_min_idx;
    always_comb begin
        final_cur_min_idx = cur_min_mag_idx[0];
        for (int j = 1; j < 4; j++) begin
            if (cur_min_mag_idx[cbfp_cnt] < final_cur_min_idx) begin
                final_cur_min_idx = cur_min_mag_idx[cbfp_cnt];
            end
        end
    end

    // 갱신된 final_cur_min_idx를 저장할 레지스터

    logic signed [IN_W:0] shift_amt;
    logic signed [IN_W:0] reg_shift_amt;


    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            reg_shift_amt <= 0;
        end else if (cbfp_cnt == 3) begin
            shift_amt <= final_cur_min_idx - TRUNC_VALUE;
        end
    end

    always_comb begin
        for (int j = 0; j < 16; j++) begin
            idx0[i] = shift_amt + TRUNC_VALUE;
        end
    end

    always_comb begin
        for (int i = 0; i < NCHAN; i++) begin
            if (shift_amt > 0) begin
                data_re_out[i] = shift_data_re[i] <<< shift_amt;
                data_im_out[i] = shift_data_im[i] <<< shift_amt;
            end else begin
                data_re_out[i] = shift_data_re[i] >>> -shift_amt;
                data_im_out[i] = shift_data_im[i] >>> -shift_amt;
            end
        end
    end


    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            for (int k = 0; k < 5; k++) begin
                valid_pipe[k] <= 1'b0;
            end
        end else begin
            valid_pipe[0] <= valid_in;
            valid_pipe[1] <= valid_pipe[0];
            valid_pipe[2] <= valid_pipe[1];
            valid_pipe[3] <= valid_pipe[2];
            valid_pipe[4] <= valid_pipe[3];
        end
    end

    // 최종 valid_out은 데이터가 유효한 시점에 나감
    assign valid_out_trigg = valid_pipe[4];
    counter_v3 #(
        .PULSE_CYCLES(32)
    ) U_CBFP_CNT_V3 (
        .clk(clk),
        .rstn(rstn),
        .en(valid_out_trigg),  // 트리거 신호 (펄스 or 레벨)
        .out_pulse(valid_out)  // en 들어온 즉시 1, PULSE_CYCLES 동안 유지
    );


endmodule
