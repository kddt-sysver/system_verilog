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

    localparam logic signed [1:0] fac8_0_re[0:3] = {2'd1, 2'd1, 2'd1, 2'd0};
    localparam logic signed [1:0] fac8_0_im[0:3] = {2'd0, 2'd0, 2'd0, -2'd1};
    localparam logic signed [9:0] fac8_1_re[0:7] = {
        10'd256, 10'd256, 10'd256, 10'd0, 10'd256, 10'd181, 10'd256, -10'd181
    };
    localparam logic signed [9:0] fac8_1_im[0:7] = {
        10'd0, 10'd0, 10'd0, -10'd256, 10'd0, -10'd181, 10'd0, -10'd181
    };

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

    logic signed [WIDTH:0] twd_00bfly_sum_re[0:15];  //<4.6>
    logic signed [WIDTH:0] twd_00bfly_sum_im[0:15];  //<4.6>
    logic signed [WIDTH:0] twd_00bfly_diff_re[0:15];  //<4.6>
    logic signed [WIDTH:0] twd_00bfly_diff_im[0:15];  //<4.6>

    int i;
    logic [1:0] idx_00;
    logic [4:0] bundle_cnt;

    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) bundle_cnt <= 5'd0;
        else if (din_valid) bundle_cnt <= bundle_cnt + 5'd1;
    end

    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            for (int i = 0; i < 16; i++) begin
                twd_00bfly_sum_re[i]  <= '0;
                twd_00bfly_sum_im[i]  <= '0;
                twd_00bfly_diff_re[i] <= '0;
                twd_00bfly_diff_im[i] <= '0;
            end
        end else if (din_valid) begin       //twd_valid
            // 8묶음마다 idx가 0→1→2→3
            idx_00 = bundle_cnt[4:3];

            for (int i = 0; i < 16; i++) begin
                // real(sum)  = a*c − b*d
                twd_00bfly_sum_re [i] <=
        w_00bfly_sum_re [i] * fac8_0_re[idx_00]
      - w_00bfly_sum_im [i] * fac8_0_im[idx_00];

                // imag(sum)  = a*d + b*c
                twd_00bfly_sum_im [i] <=
        w_00bfly_sum_re [i] * fac8_0_im[idx_00]
      + w_00bfly_sum_im [i] * fac8_0_re[idx_00];

                // real(diff) = a*c − b*d
                twd_00bfly_diff_re[i] <=
        w_00bfly_diff_re[i] * fac8_0_re[idx_00]
      - w_00bfly_diff_im[i] * fac8_0_im[idx_00];

                // imag(diff) = a*d + b*c
                twd_00bfly_diff_im[i] <=
        w_00bfly_diff_re[i] * fac8_0_im[idx_00]
      + w_00bfly_diff_im[i] * fac8_0_re[idx_00];
            end
        end
    end

    logic signed [WIDTH+11:0] twd_01bfly_sum_re_ac [0:15];  //<5.6> * <2.8> -> <7.14>
    logic signed [WIDTH+11:0] twd_01bfly_sum_im_ad [0:15];  //<5.6> * <2.8> -> <7.14>
    logic signed [WIDTH+11:0] twd_01bfly_diff_re_bd[0:15];  //<5.6> * <2.8> -> <7.14>
    logic signed [WIDTH+11:0] twd_01bfly_diff_im_bc[0:15];  //<5.6> * <2.8> -> <7.14>

    logic [1:0] idx_01;
    logic [4:0] bundle_cnt;

    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) bundle_cnt <= 5'd0;
        else if (din_valid) bundle_cnt <= bundle_cnt + 5'd1;
    end

    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            // 리셋 시 출력 모두 0
            for (i = 0; i < 16; i++) begin
                twd_01bfly_sum_re_ac[i]  <= '0;
                twd_01bfly_sum_im_ad[i]  <= '0;
                twd_01bfly_diff_re_bd[i] <= '0;
                twd_01bfly_diff_im_bc[i] <= '0;
            end
        end else if (din_valid) begin  //twd_valid
            for (i = 0; i < 16; i++) begin
                // twiddle 계수 번호: 0~3 를 4개씩 묶어서 사용
                idx = i[3:1];  // i=0~3→0, 4~7→1, 8~11→2, 12~15→3

                // (a + jb) * (c + jd) = (a*c − b*d) + j(a*d + b*c)
                twd_01bfly_sum_re_ac[i] <= w_01bfly_sum_re[i] * fac8_1_re[idx];

                twd_01bfly_sum_im_ad[i] <= w_01bfly_sum_im[i] * fac8_1_im[idx];
            end
        end
    end

endmodule
