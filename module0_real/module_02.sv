`timescale 1ns / 1ps

module module_02 #(
    parameter int WIDTH = 13
) (
    input logic clk,
    input logic rstn,
    //input  logic                    fft_mode,    // IFFT 모드용 켤레 처리

    input logic signed [WIDTH-1:0] twd_01_sum_re[0:15],
    input logic signed [WIDTH-1:0] twd_01_sum_im[0:15],
    input logic signed [WIDTH-1:0] twd_01_diff_re[0:15],
    input logic signed [WIDTH-1:0] twd_01_diff_im[0:15],
    input logic shift_02_valid,

    output logic signed [WIDTH+9:0] twd_02_sum_re [0:15],
    output logic signed [WIDTH+9:0] twd_02_sum_im [0:15],
    output logic signed [WIDTH+9:0] twd_02_diff_re[0:15],
    output logic signed [WIDTH+9:0] twd_02_diff_im[0:15],

    output logic CBFP_valid
);
    int i;
    logic signed [WIDTH-1:0] w_shift_data02_re[0:15];
    logic signed [WIDTH-1:0] w_shift_data02_im[0:15];

    logic signed [WIDTH:0] w_02bfly_sum_re[0:15];
    logic signed [WIDTH:0] w_02bfly_sum_im[0:15];
    logic signed [WIDTH:0] w_02bfly_diff_re[0:15];
    logic signed [WIDTH:0] w_02bfly_diff_im[0:15];

    logic signed [WIDTH-1:0] twd_data02_re[0:15];
    logic signed [WIDTH-1:0] twd_data02_im[0:15];

    logic signed [WIDTH-1:0] w_twd_01_diff_re[0:15];
    logic signed [WIDTH-1:0] w_twd_01_diff_im[0:15];

    logic w_twd02_valid;
    logic w_twd02_valid_d1;  // 1클럭 지연된 valid 신호
    logic w_bfly02_valid;
    logic w_shift_valid;
    logic [3:0] w_cnt;
    assign CBFP_valid = w_twd02_valid_d1;
    assign twd_data02_re = (w_cnt < 8) ? twd_01_sum_re : w_twd_01_diff_re;
    assign twd_data02_im = (w_cnt < 8) ? twd_01_sum_im : w_twd_01_diff_im;

    // valid 신호 지연
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            w_twd02_valid_d1 <= 1'b0;
        end else begin
            w_twd02_valid_d1 <= w_twd02_valid;
        end
    end

    counter_v3 #(
        .PULSE_CYCLES(32)
    ) U_SHIFT_VALID_CNT (
        .clk(clk),
        .rstn(rstn),
        .en(shift_02_valid),
        .out_pulse(w_shift_valid)
    );

    shift_reg #(
        .WIDTH(WIDTH),
        .MEM_DEPTH(128)  // 예: 256, 128, 64 등 단계에 따라 설정
    ) U_SHIFT_REG02_1 (
        .clk(clk),
        .rstn(rstn),
        .din_re(twd_01_diff_re),
        .din_im(twd_01_diff_im),
        .valid(w_shift_valid),
        .shift_data_re(w_twd_01_diff_re),
        .shift_data_im(w_twd_01_diff_im)
    );

    counter #(
        .COUNT_MAX_VAL(4)
    ) U_CNT (
        .clk      (clk),
        .rstn     (rstn),
        .en       (w_shift_valid),
        .count_out(w_cnt)
    );

    shift_reg #(
        .WIDTH(WIDTH),
        .MEM_DEPTH(64)  // 예: 256, 128, 64 등 단계에 따라 설정
    ) U_SHIFT_REG02_2 (
        .clk(clk),
        .rstn(rstn),
        .din_re(twd_data02_re),
        .din_im(twd_data02_im),
        .valid(w_shift_valid),
        .shift_data_re(w_shift_data02_re),
        .shift_data_im(w_shift_data02_im)
    );

    counter_v2 #(
        .COUNT_MAX_VAL(32),
        .DIV_RATIO(4)
    ) U_BFLY_CNT (
        .clk(clk),
        .rstn(rstn),
        .en(shift_02_valid),
        .out_pulse(w_bfly02_valid)
    );

    bfly #(
        .WIDTH(WIDTH)
    ) U_BFLY02 (
        .clk          (clk),
        .rstn         (rstn),
        .bfly_valid   (w_bfly02_valid),     // 연산 시 HIGH
        .din_re       (twd_data02_re),
        .din_im       (twd_data02_im),
        .shift_data_re(w_shift_data02_re),
        .shift_data_im(w_shift_data02_im),
        .bfly_sum_re  (w_02bfly_sum_re),
        .bfly_sum_im  (w_02bfly_sum_im),
        .bfly_diff_re (w_02bfly_diff_re),
        .bfly_diff_im (w_02bfly_diff_im),
        .twiddle_valid(w_twd02_valid)
    );

    //-------------------------------------twiddle_02 start-------------------------------------
    genvar j;

    logic [3:0] twd_02_cnt;
    logic signed [8:0] twd_02_sum_re_fac[0:15];
    logic signed [8:0] twd_02_sum_im_fac[0:15];
    logic signed [8:0] twd_02_diff_re_fac[0:15];
    logic signed [8:0] twd_02_diff_im_fac[0:15];
    logic [8:0] twf0_sum_idx[0:15];
    logic [8:0] twf0_diff_idx[0:15];
    logic signed [WIDTH+9:0] ac_02prod_sum_reg[0:15];  // Sum 브랜치 중간 AC
    logic signed [WIDTH+9:0] bd_02prod_sum_reg[0:15];  // Sum 브랜치 중간 BD
    logic signed [WIDTH+9:0] ad_02prod_sum_reg[0:15];  // Sum 브랜치 중간 AD
    logic signed [WIDTH+9:0] bc_02prod_sum_reg[0:15];  // Sum 브랜치 중간 BC
    logic signed [WIDTH+9:0] ac_02prod_diff_reg[0:15];  // Diff 브랜치 중간 AC
    logic signed [WIDTH+9:0] bd_02prod_diff_reg[0:15];  // Diff 브랜치 중간 BD
    logic signed [WIDTH+9:0] ad_02prod_diff_reg[0:15];  // Diff 브랜치 중간 AD
    logic signed [WIDTH+9:0] bc_02prod_diff_reg[0:15];  // Diff 브랜치 중간 BC

    counter #(
        .COUNT_MAX_VAL(4)
    ) U_TWD_02_CNT (
        .clk      (clk),
        .rstn     (rstn),
        .en       (w_twd02_valid),
        .count_out(twd_02_cnt)
    );

    //genvar j;
    for (j = 0; j < 16; j++) begin 
        assign twf0_sum_idx[j]  = j + 16 * (twd_02_cnt % 4) + 128 * (twd_02_cnt/4);
        twd0_512 U_TWF0_512_sum (
            .rom_address_in(twf0_sum_idx[j]),  // 0에서 511까지의 단일 인덱스 입력
            .twf_re_out(twd_02_sum_re_fac[j]),
            .twf_im_out(twd_02_sum_im_fac[j])
        );
    end
    for (j = 0; j < 16; j++) begin
        assign twf0_diff_idx[j] = j + 16 * (twd_02_cnt % 4) + 128 * (twd_02_cnt/4) + 64;
        twd0_512 U_TWF0_512_diff (
            .rom_address_in(twf0_diff_idx[j]),  // 0에서 511까지의 단일 인덱스 입력
            .twf_re_out(twd_02_diff_re_fac[j]),
            .twf_im_out(twd_02_diff_im_fac[j])
        );
    end

    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            // 리셋 시 출력 모두 0
            for (i = 0; i < 16; i++) begin
                twd_02_sum_re[i] <= '0;
                twd_02_sum_im[i] <= '0;
                twd_02_diff_re[i] <= '0;
                twd_02_diff_im[i] <= '0;

                // 중간 레지스터들도 리셋
                ac_02prod_sum_reg[i] <= '0;
                bd_02prod_sum_reg[i] <= '0;
                ad_02prod_sum_reg[i] <= '0;
                bc_02prod_sum_reg[i] <= '0;
                ac_02prod_diff_reg[i] <= '0;
                bd_02prod_diff_reg[i] <= '0;
                ad_02prod_diff_reg[i] <= '0;
                bc_02prod_diff_reg[i] <= '0;
            end
        end else begin
            // 첫 번째 클럭: 중간 곱셈 계산
            if (w_twd02_valid) begin
                for (int i = 0; i < 16; i++) begin
                    // Sum 브랜치 중간 곱셈
                    ac_02prod_sum_reg[i] <= w_02bfly_sum_re[i] * twd_02_sum_re_fac[i];
                    bd_02prod_sum_reg[i] <= w_02bfly_sum_im[i] * twd_02_sum_im_fac[i];
                    ad_02prod_sum_reg[i] <= w_02bfly_sum_re[i] * twd_02_sum_im_fac[i];
                    bc_02prod_sum_reg[i] <= w_02bfly_sum_im[i] * twd_02_sum_re_fac[i];

                    // Diff 브랜치 중간 곱셈
                    ac_02prod_diff_reg[i] <= w_02bfly_diff_re[i] * twd_02_diff_re_fac[i];
                    bd_02prod_diff_reg[i] <= w_02bfly_diff_im[i] * twd_02_diff_im_fac[i];
                    ad_02prod_diff_reg[i] <= w_02bfly_diff_re[i] * twd_02_diff_im_fac[i];
                    bc_02prod_diff_reg[i] <= w_02bfly_diff_im[i] * twd_02_diff_re_fac[i];
                end
            end
            
            // 두 번째 클럭: 최종 결과 계산
            if (w_twd02_valid_d1) begin
                for (int i = 0; i < 16; i++) begin
                    // Sum 브랜치 최종 결과
                    twd_02_sum_re[i] <= (ac_02prod_sum_reg[i] - bd_02prod_sum_reg[i]);
                    twd_02_sum_im[i] <= (ad_02prod_sum_reg[i] + bc_02prod_sum_reg[i]);

                    // Diff 브랜치 최종 결과
                    twd_02_diff_re[i] <= (ac_02prod_diff_reg[i] - bd_02prod_diff_reg[i]);
                    twd_02_diff_im[i] <= (ad_02prod_diff_reg[i] + bc_02prod_diff_reg[i]);
                end
            end
        end
    end

    //-------------------------------------twiddle_02 end---------------------------------------
endmodule
