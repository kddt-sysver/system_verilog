module module_0 #(
    parameter int WIDTH = 9
) (
    input logic clk,
    input logic rstn,
    //input  logic                    fft_mode,    // IFFT 모드용 켤레 처리

    input signed [WIDTH-1:0] in_i     [0:15],
    input signed [WIDTH-1:0] in_q     [0:15],
    input                    din_valid,

    output logic signed [WIDTH+1:0] out_re   [0:15],
    output logic signed [WIDTH+1:0] out_im   [0:15],
    output logic                    out_valid
);
    int i;
    logic signed [WIDTH:0] w_00bfly_sum_re[0:15];  //<4.6>
    logic signed [WIDTH:0] w_00bfly_sum_im[0:15];  //<4.6>
    logic signed [WIDTH:0] w_00bfly_diff_re[0:15];  //<4.6>
    logic signed [WIDTH:0] w_00bfly_diff_im[0:15];  //<4.6>
    logic signed [WIDTH+1:0] w_01bfly_sum_re[0:15];  //<5.6>
    logic signed [WIDTH+1:0] w_01bfly_sum_im[0:15];  //<5.6>
    logic signed [WIDTH+1:0] w_01bfly_diff_re[0:15];  //<5.6>
    logic signed [WIDTH+1:0] w_01bfly_diff_im[0:15];  //<5.6>
    logic signed [WIDTH+3:0] w_02bfly_sum_re[0:15];  //<7.6>
    logic signed [WIDTH+3:0] w_02bfly_sum_im[0:15];  //<7.6>
    logic signed [WIDTH+3:0] w_02bfly_diff_re[0:15];  //<7.6>
    logic signed [WIDTH+3:0] w_02bfly_diff_im[0:15];  //<7.6>

    logic signed [WIDTH-1:0] w_shift_data_re[0:15];
    logic signed [WIDTH-1:0] w_shift_data_im[0:15];

    logic w_twd00_valid;
    logic [3:0] w_bfly00_valid_cnt;
    shift_reg #(
        .WIDTH(WIDTH),
        .MEM_DEPTH(256)  // 예: 256, 128, 64 등 단계에 따라 설정
    ) U_SHIFT_REG00 (
        .clk(clk),
        .rstn(rstn),
        .din_re(in_i),
        .din_im(in_q),
        .valid(din_valid),
        .shift_data_re(w_shift_data_re),
        .shift_data_im(w_shift_data_im)
    );

    counter #(
        .WIDTH(4)
    ) U_bfly_00_cnt (
        .clk      (clk),
        .rstn     (rstn),
        .en       (din_valid),          //twd00_valid            
        .count_out(w_bfly00_valid_cnt)
    );

    bfly #(
        .WIDTH(WIDTH),
        .NUM_PAIR(256)  // 16쌍 × N 클럭
    ) U_BFLY00 (
        .clk          (clk),
        .rstn         (rstn),
        .bfly_valid   (w_bfly00_valid_cnt),  // 연산 시 HIGH
        .din_re       (in_i),
        .din_im       (in_q),
        .shift_data_re(w_shift_data_re),
        .shift_data_im(w_shift_data_im),
        .bfly_sum_re  (w_00bfly_sum_re),
        .bfly_sum_im  (w_00bfly_sum_im),
        .bfly_diff_re (w_00bfly_diff_re),
        .bfly_diff_im (w_00bfly_diff_im),
        .twiddle_valid(w_twd00_valid)
    );

    //-------------------------------------twiddle_00 start-------------------------------------
    logic signed [WIDTH:0] twd_00bfly_sum_re [0:15];  //<4.6>
    logic signed [WIDTH:0] twd_00bfly_sum_im [0:15];  //<4.6>
    logic signed [WIDTH:0] twd_00bfly_diff_re[0:15];  //<4.6>
    logic signed [WIDTH:0] twd_00bfly_diff_im[0:15];  //<4.6>
    twd_mul00#(
        .WIDTH  (9),
        .CLK_CNT(4)
    ) (
        .clk(clk),
        .rstn(rstn),
        .twd00_valid(w_twd00_valid),
        .i_00bfly_sum_re(w_00bfly_sum_re),  //<4.6>
        .i_00bfly_sum_im(w_00bfly_sum_im),
        .i_00bfly_diff_re(w_00bfly_diff_re),
        .i_00bfly_diff_im(w_00bfly_diff_im),
        .twd_00bfly_sum_re(twd_00bfly_sum_re),
        .twd_00bfly_sum_im(twd_00bfly_sum_im),
        .twd_00bfly_diff_re(twd_00bfly_diff_re),
        .twd_00bfly_diff_im(twd_00bfly_diff_im)
    );
    //-------------------------------------twiddle_00 end---------------------------------------

    //-------------------------------------twiddle_01 start-------------------------------------
    logic signed [WIDTH+3:0] w_twd_01bfly_sum_re [0:15];  //<5.6> * <2.8> -> <7.14> -> <7.6>
    logic signed [WIDTH+3:0] w_twd_01bfly_sum_im [0:15];  //<5.6> * <2.8> -> <7.14> -> <7.6>
    logic signed [WIDTH+3:0] w_twd_01bfly_diff_re[0:15];  //<5.6> * <2.8> -> <7.14> -> <7.6>
    logic signed [WIDTH+3:0] w_twd_01bfly_diff_im[0:15];  //<5.6> * <2.8> -> <7.14> -> <7.6>
    twd_mul01#(
        .WIDTH  (9),
        .CLK_CNT(4)
    ) (
        .clk(clk),
        .rstn(rstn),
        .twd01_valid(twd01_valid),
        .i_01bfly_sum_re(w_01bfly_sum_re),  //<5.6>
        .i_01bfly_sum_im(w_01bfly_sum_im),  //<5.6>
        .i_01bfly_diff_re(w_01bfly_diff_re),  //<5.6>
        .i_01bfly_diff_im(w_01bfly_diff_im),  //<5.6>
        .twd_01bfly_sum_re (w_twd_01bfly_sum_re),  //<5.6> * <2.8> -> <7.14> -> <7.6>
        .twd_01bfly_sum_im (w_twd_01bfly_sum_im),  //<5.6> * <2.8> -> <7.14> -> <7.6>
        .twd_01bfly_diff_re(w_twd_01bfly_diff_re),  //<5.6> * <2.8> -> <7.14> -> <7.6>
        .twd_01bfly_diff_im(w_twd_01bfly_diff_im)  //<5.6> * <2.8> -> <7.14> -> <7.6>
    );
    //-------------------------------------twiddle_01 end---------------------------------------

    //-------------------------------------twiddle_02 start-------------------------------------
    genvar j;
    logic signed [WIDTH+13:0] twd_02bfly_sum_re [0:15];  //<7.6> * <2.7> -> <9.13> -> <10.13>
    logic signed [WIDTH+13:0] twd_02bfly_sum_im [0:15];  //<7.6> * <2.7> -> <9.13> -> <10.13>
    logic signed [WIDTH+13:0] twd_02bfly_diff_re[0:15];  //<7.6> * <2.7> -> <9.13> -> <10.13>
    logic signed [WIDTH+13:0] twd_02bfly_diff_im[0:15];  //<7.6> * <2.7> -> <9.13> -> <10.13>


    logic [3:0] twd_02_cnt;
    logic [8:0] twd_02_sum_re_fac[0:15];
    logic [8:0] twd_02_sum_im_fac[0:15];
    logic [8:0] twd_02_diff_re_fac[0:15];
    logic [8:0] twd_02_diff_im_fac[0:15];
    logic [8:0] twf0_sum_idx[0:15];
    logic [8:0] twf0_diff_idx[0:15];
    logic signed [WIDTH+12:0] ac_02prod_sum_reg[0:15];  // Sum 브랜치 중간 AC
    logic signed [WIDTH+12:0] bd_02prod_sum_reg[0:15];  // Sum 브랜치 중간 BD
    logic signed [WIDTH+12:0] ad_02prod_sum_reg[0:15];  // Sum 브랜치 중간 AD
    logic signed [WIDTH+12:0] bc_02prod_sum_reg[0:15];  // Sum 브랜치 중간 BC
    logic signed [WIDTH+12:0] ac_02prod_diff_reg[0:15];  // Diff 브랜치 중간 AC
    logic signed [WIDTH+12:0] bd_02prod_diff_reg[0:15];  // Diff 브랜치 중간 BD
    logic signed [WIDTH+12:0] ad_02prod_diff_reg[0:15];  // Diff 브랜치 중간 AD
    logic signed [WIDTH+12:0] bc_02prod_diff_reg[0:15];  // Diff 브랜치 중간 BC

    counter #(
        .WIDTH(4)
    ) U_TWD_02_CNT (
        .clk      (clk),
        .rstn     (rstn),
        .en       (din_valid),  //twd00_valid            
        .count_out(twd_02_cnt)
    );

    //genvar j;
    for (j = 0; j < 16; j++) begin
        assign twf0_sum_idx[j] = j + 128 * (twd_02_cnt / 4);
        twf0_512 U_TWF0_512 (
            .rom_address_in(twf0_sum_idx[j]),  // 0에서 511까지의 단일 인덱스 입력
            .twf_re_out(twd_02_sum_re_fac[j]),
            .twf_im_out(twd_02_sum_im_fac[j])
        );
    end
    for (j = 0; j < 16; j++) begin
        assign twf0_diff_idx[j] = j + 128 * (twd_02_cnt / 4) + 64;
        twf0_512 U_TWF0_512 (
            .rom_address_in(twf0_diff_idx[j]),  // 0에서 511까지의 단일 인덱스 입력
            .twf_re_out(twd_02_diff_re_fac[j]),
            .twf_im_out(twd_02_diff_im_fac[j])
        );
    end

    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            // 리셋 시 출력 모두 0
            for (i = 0; i < 16; i++) begin
                twd_02bfly_sum_re[i]  <= '0;
                twd_02bfly_sum_im[i]  <= '0;
                twd_02bfly_diff_re[i] <= '0;
                twd_02bfly_diff_im[i] <= '0;

                // 중간 레지스터들도 리셋
                ac_02prod_sum_reg[i]  <= '0;
                bd_02prod_sum_reg[i]  <= '0;
                ad_02prod_sum_reg[i]  <= '0;
                bc_02prod_sum_reg[i]  <= '0;
                ac_02prod_diff_reg[i] <= '0;
                bd_02prod_diff_reg[i] <= '0;
                ad_02prod_diff_reg[i] <= '0;
                bc_02prod_diff_reg[i] <= '0;
            end
        end else if (din_valid) begin  //twd01_valid
            //(a+bj)*(c+dj) = ac-bd+(ad+bc)j
            for (int i = 0; i < 16; i++) begin
                ac_02prod_sum_reg[i] <= w_02bfly_sum_re[i] * twd_02_sum_re_fac[i];
                bd_02prod_sum_reg[i] <= w_02bfly_sum_im[i] * twd_02_sum_im_fac[i];
                ad_02prod_sum_reg[i] <= w_02bfly_sum_re[i] * twd_02_sum_im_fac[i];
                bc_02prod_sum_reg[i] <= w_02bfly_sum_im[i] * twd_02_sum_re_fac[i];

                // 실수부: (ac_prod_sum_reg[i] - bd_prod_sum_reg[i])
                twd_02bfly_sum_re[i] <= (ac_02prod_sum_reg[i] - bd_02prod_sum_reg[i] ); // <9.13> -> <10.13>
                // 허수부: (ad_prod_sum_reg[i] + bc_prod_sum_reg[i])
                twd_02bfly_sum_im[i] <= (ad_02prod_sum_reg[i] + bc_02prod_sum_reg[i] ); // <9.13> -> <10.13>

                // --- 'diff' 브랜치 복소수 곱셈 처리 ---
                // 입력: w_01bfly_diff_re[i] (A), w_01bfly_diff_im[i] (B)
                // 트위들: fac8_1_re[idx_01] (C), fac8_1_im[idx_01] (D)
                ac_02prod_diff_reg[i] <= w_02bfly_diff_re[i] * twd_02_diff_re_fac[i];
                bd_02prod_diff_reg[i] <= w_02bfly_diff_im[i] * twd_02_diff_im_fac[i];
                ad_02prod_diff_reg[i] <= w_02bfly_diff_re[i] * twd_02_diff_im_fac[i];
                bc_02prod_diff_reg[i] <= w_02bfly_diff_im[i] * twd_02_diff_re_fac[i];

                // 실수부: (ac_prod_diff_reg[i] - bd_prod_diff_reg[i])
                twd_02bfly_diff_re[i] <= (ac_02prod_diff_reg[i] - bd_02prod_diff_reg[i]); // <9.13> -> <10.13>
                // 허수부: (ad_prod_diff_reg[i] + bc_prod_diff_reg[i])
                twd_02bfly_diff_im[i] <= (ad_02prod_diff_reg[i] + bc_02prod_diff_reg[i]); // <9.13> -> <10.13>
            end
        end
    end
    //-------------------------------------twiddle_02 end---------------------------------------

endmodule
