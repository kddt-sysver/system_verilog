
`timescale 1ns / 1ps
module twd_mul11 #(
    parameter int WIDTH = 13,
    CLK_CNT = 4
) (
    input logic clk,
    input logic rstn,
    input logic twd11_valid,
    input logic signed [WIDTH-1:0] i_11bfly_sum_re[0:15],  //<5.6>
    input logic signed [WIDTH-1:0] i_11bfly_sum_im[0:15],  //<5.6>
    input logic signed [WIDTH-1:0] i_11bfly_diff_re[0:15],  //<5.6>
    input logic signed [WIDTH-1:0] i_11bfly_diff_im[0:15],  //<5.6>
    output logic signed [WIDTH+1:0] twd_11bfly_sum_re [0:15],  //<5.6> * <2.8> -> <7.14> -> <7.6>
    output logic signed [WIDTH+1:0] twd_11bfly_sum_im [0:15],  //<5.6> * <2.8> -> <7.14> -> <7.6>
    output logic signed [WIDTH+1:0] twd_11bfly_diff_re[0:15],  //<5.6> * <2.8> -> <7.14> -> <7.6>
    output logic signed [WIDTH+1:0] twd_11bfly_diff_im[0:15]  //<5.6> * <2.8> -> <7.14> -> <7.6>
);
    //fac8_1 = [256, 256, 256, -j*256, 256, 181-j*181, 256, -181-j*181];
    //(a+bj)*(c+dj) = ac-bd+(ad+bc)j
    int i, j;
    logic signed [WIDTH+11:0] ac_11prod_diff_reg[0:7];  // Diff 브랜치 중간 AC
    logic signed [WIDTH+11:0] bd_11prod_diff_reg[0:7];  // Diff 브랜치 중간 BD
    logic signed [WIDTH+11:0] ad_11prod_diff_reg[0:7];  // Diff 브랜치 중간 AD
    logic signed [WIDTH+11:0] bc_11prod_diff_reg[0:7];  // Diff 브랜치 중간 BC

    logic signed [WIDTH+11:0] ac_11prod_sum_reg[0:7];  // Diff 브랜치 중간 AC
    logic signed [WIDTH+11:0] bd_11prod_sum_reg[0:7];  // Diff 브랜치 중간 BD
    logic signed [WIDTH+11:0] ad_11prod_sum_reg[0:7];  // Diff 브랜치 중간 AD
    logic signed [WIDTH+11:0] bc_11prod_sum_reg[0:7];  // Diff 브랜치 중간 BC

    logic twd_11_cnt;

    counter #(
        .COUNT_MAX_VAL(1)
    ) U_TWD_11_CNT (
        .clk      (clk),
        .rstn     (rstn),
        .en       (twd11_valid),
        .count_out(twd_11_cnt)
    );

    always @(*) begin
        case (twd_11_cnt)
            0: begin
                for (j = 0; j < 8; j++) begin
                    twd_11bfly_sum_re[j] = i_11bfly_sum_re[j];
                    twd_11bfly_sum_im[j] = i_11bfly_sum_im[j];
                    twd_11bfly_diff_re[j] = i_11bfly_diff_re[j];
                    twd_11bfly_diff_im[j] = i_11bfly_diff_im[j];
                    twd_11bfly_sum_re[j+8] = i_11bfly_sum_re[j+8];
                    twd_11bfly_sum_im[j+8] = i_11bfly_sum_im[j+8];
                    twd_11bfly_diff_re[j+8] = i_11bfly_diff_im[j+8];
                    twd_11bfly_diff_im[j+8] = -i_11bfly_diff_re[j+8];
                end
            end
            1: begin
                for (j = 0; j < 8; j++) begin
                    twd_11bfly_sum_re[j] = i_11bfly_sum_re[j];
                    twd_11bfly_sum_im[j] = i_11bfly_sum_im[j];
                    twd_11bfly_diff_re[j] = i_11bfly_diff_re[j];
                    twd_11bfly_diff_im[j] = i_11bfly_diff_im[j];

                    ac_11prod_sum_reg[j] = i_11bfly_sum_re[j+8] * 181;
                    bd_11prod_sum_reg[j] = i_11bfly_sum_im[j+8] * (-181);
                    ad_11prod_sum_reg[j] = i_11bfly_sum_re[j+8] * (-181);
                    bc_11prod_sum_reg[j] = i_11bfly_sum_im[j+8] * 181;
                    // 반올림 적용: 오른쪽으로 8비트 시프트하기 전에 128을 더합니다.
                    twd_11bfly_sum_re[j+8] = (ac_11prod_sum_reg[j] - bd_11prod_sum_reg[j] + 128)>>>8;
                    twd_11bfly_sum_im[j+8] = (ad_11prod_sum_reg[j] + bc_11prod_sum_reg[j] + 128)>>>8;

                    ac_11prod_diff_reg[j] = i_11bfly_diff_re[j+8] * (-181);
                    bd_11prod_diff_reg[j] = i_11bfly_diff_im[j+8] * (-181);
                    ad_11prod_diff_reg[j] = i_11bfly_diff_re[j+8] * (-181);
                    bc_11prod_diff_reg[j] = i_11bfly_diff_im[j+8] * (-181);
                    // 반올림 적용: 오른쪽으로 8비트 시프트하기 전에 128을 더합니다.
                    twd_11bfly_diff_re[j+8] = (ac_11prod_diff_reg[j] - bd_11prod_diff_reg[j] + 128)>>>8;
                    twd_11bfly_diff_im[j+8] = (ad_11prod_diff_reg[j] + bc_11prod_diff_reg[j] + 128)>>>8;
                end
            end
            default: begin
                for (j = 0; j < 16; j++) begin
                    twd_11bfly_sum_re[j]  = i_11bfly_sum_re[j];
                    twd_11bfly_sum_im[j]  = i_11bfly_sum_im[j];
                    twd_11bfly_diff_re[j] = i_11bfly_diff_re[j];
                    twd_11bfly_diff_im[j] = i_11bfly_diff_im[j];
                end
            end
        endcase
    end
endmodule


