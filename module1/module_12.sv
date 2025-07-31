module module_12 #(
    parameter int WIDTH = 15
) (
    input logic clk,
    input logic rstn,
    //input  logic                    fft_mode,    // IFFT 모드용 켤레 처리

    input logic signed [WIDTH-1:0] twd_11_sum_re[0:15],  // <9.6>
    input logic signed [WIDTH-1:0] twd_11_sum_im[0:15],
    input logic signed [WIDTH-1:0] twd_11_diff_re[0:15],
    input logic signed [WIDTH-1:0] twd_11_diff_im[0:15],
    input logic shift_12_valid,



    output logic signed [WIDTH+9:0] twd_12_re[0:15],  // <12.13>
    output logic signed [WIDTH+9:0] twd_12_im[0:15],

    output logic CBFP_valid
);
    int i;
    //logic signed [WIDTH-1:0] w_shift_data12_re[0:15];
    //logic signed [WIDTH-1:0] w_shift_data12_im[0:15];

    logic signed [WIDTH-1:0] w_twd_11_diff_re[0:15];
    logic signed [WIDTH-1:0] w_twd_11_diff_im[0:15];

    logic signed [WIDTH:0] w_12bfly_re[0:15];
    logic signed [WIDTH:0] w_12bfly_im[0:15];

    logic signed [WIDTH-1:0] twd_data12_re[0:15];
    logic signed [WIDTH-1:0] twd_data12_im[0:15];


    logic w_bfly12_valid;
    logic w_twd12_valid;
    logic w_shift_valid;
    //logic [1:0] w_cnt;

    assign twd_data12_re = (shift_12_valid) ? twd_11_sum_re : w_twd_11_diff_re;
    assign twd_data12_im = (shift_12_valid) ? twd_11_sum_im : w_twd_11_diff_im;


    counter_v4 #(
        .PULSE_CYCLES(32)
    ) U_SHIFT_VALID_CNT (
        .clk(clk),
        .rstn(rstn),
        .en(shift_12_valid),
        .out_pulse(w_shift_valid)
    );

    shift_reg #(
        .WIDTH(WIDTH),
        .MEM_DEPTH(16)  // 예: 256, 128, 64 등 단계에 따라 설정
    ) U_SHIFT_REG12 (
        .clk(clk),
        .rstn(rstn),
        .din_re(twd_11_diff_re),
        .din_im(twd_11_diff_im),
        .valid(w_shift_valid),
        .shift_data_re(w_twd_11_diff_re),
        .shift_data_im(w_twd_11_diff_im)
    );


    counter_v4 #(
        .PULSE_CYCLES(32)
    ) U_BFLY_CNT (
        .clk(clk),
        .rstn(rstn),
        .en(shift_12_valid),
        .out_pulse(w_bfly12_valid)
    );


    bfly_v2 #(
        .WIDTH(WIDTH),
        .NUM_POINT(16)  // 블록 크기 (8→4, 4→2, 2→1)
    ) U_BFLY_22 (
        .clk(clk),
        .rstn(rstn),
        .bfly_valid(w_bfly12_valid),
        .din_re(twd_data12_re),
        .din_im(twd_data12_im),
        .bfly_re(w_12bfly_re),
        .bfly_im(w_12bfly_im),
        .twiddle_valid(w_twd12_valid)
    );

    //-------------------------------------twiddle_12 start-------------------------------------

    //-------------------------------------twiddle_12 start-------------------------------------
    genvar j;

    logic [1:0] twd_12_cnt;
    logic signed [8:0] twd_12_re_fac[0:15];
    logic signed [8:0] twd_12_im_fac[0:15];
    logic [8:0] twf1_idx[0:15];
    logic signed [WIDTH+9:0] ac_12prod_reg[0:15];  // Sum 브랜치 중간 AC
    logic signed [WIDTH+9:0] bd_12prod_reg[0:15];  // Sum 브랜치 중간 BD
    logic signed [WIDTH+9:0] ad_12prod_reg[0:15];  // Sum 브랜치 중간 AD
    logic signed [WIDTH+9:0] bc_12prod_reg[0:15];  // Sum 브랜치 중간 BC

    counter #(
        .COUNT_MAX_VAL(2)
    ) U_TWD_12_CNT (
        .clk      (clk),
        .rstn     (rstn),
        .en       (w_twd12_valid),
        .count_out(twd_12_cnt)
    );

    counter_v4 #(
        .PULSE_CYCLES(32)
    ) U_CBFP1_CNT (
        .clk(clk),
        .rstn(rstn),
        .en(w_twd12_valid),
        .out_pulse(CBFP_valid)
    );

    //genvar j;
    for (j = 0; j < 16; j++) begin
        assign twf1_idx[j] = j + twd_12_cnt * 16;
        twd1_64 U_TWF1_64_sum (
            .rom_address_in(twf1_idx[j]),  // 0에서 511까지의 단일 인덱스 입력
            .twf_re_out(twd_12_re_fac[j]),
            .twf_im_out(twd_12_im_fac[j])
        );
    end

    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            // 리셋 시 출력 모두 0
            for (i = 0; i < 16; i++) begin
                twd_12_re[i] <= '0;
                twd_12_im[i] <= '0;

                // 중간 레지스터들도 리셋
                ac_12prod_reg[i] <= '0;
                bd_12prod_reg[i] <= '0;
                ad_12prod_reg[i] <= '0;
                bc_12prod_reg[i] <= '0;
            end
        end else if (w_twd12_valid) begin  //twd01_valid
            //(a+bj)*(c+dj) = ac-bd+(ad+bc)j
            for (int i = 0; i < 16; i++) begin
                ac_12prod_reg[i] <= w_12bfly_re[i] * twd_12_re_fac[i];
                bd_12prod_reg[i] <= w_12bfly_im[i] * twd_12_im_fac[i];
                ad_12prod_reg[i] <= w_12bfly_re[i] * twd_12_im_fac[i];
                bc_12prod_reg[i] <= w_12bfly_im[i] * twd_12_re_fac[i];

                // 실수부: (ac_prod_sum_reg[i] - bd_prod_sum_reg[i])
                twd_12_re[i] <= (ac_12prod_reg[i] - bd_12prod_reg[i] ); // <9.13> -> <10.13>
                // 허수부: (ad_prod_sum_reg[i] + bc_prod_sum_reg[i])
                twd_12_im[i] <= (ad_12prod_reg[i] + bc_12prod_reg[i] ); // <9.13> -> <10.13>
            end
        end
    end
    //-------------------------------------twiddle_12 end---------------------------------------

    //-------------------------------------twiddle_12 end---------------------------------------
endmodule
