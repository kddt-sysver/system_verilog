`timescale 1ns / 1ps
module twd_mul01 #(
    parameter int WIDTH = 9,
    CLK_CNT = 4
) (
    input logic clk,
    input logic rstn,
    input logic twd01_valid,
    input logic signed [WIDTH+1:0] i_01bfly_sum_re[0:15],  //<5.6>
    input logic signed [WIDTH+1:0] i_01bfly_sum_im[0:15],  //<5.6>
    input logic signed [WIDTH+1:0] i_01bfly_diff_re[0:15],  //<5.6>
    input logic signed [WIDTH+1:0] i_01bfly_diff_im[0:15],  //<5.6>
    output logic signed [WIDTH+3:0] twd_01bfly_sum_re [0:15],  //<5.6> * <2.8> -> <7.14> -> <7.6>
    output logic signed [WIDTH+3:0] twd_01bfly_sum_im [0:15],  //<5.6> * <2.8> -> <7.14> -> <7.6>
    output logic signed [WIDTH+3:0] twd_01bfly_diff_re[0:15],  //<5.6> * <2.8> -> <7.14> -> <7.6>
    output logic signed [WIDTH+3:0] twd_01bfly_diff_im[0:15]  //<5.6> * <2.8> -> <7.14> -> <7.6>
);
    /*fac8_1 = [1 + 0j, 1 + 0j, 1 + 0j, 0 - j, 1 + 0j,
    181+(-181)j, 1 + 0j, 181+(-181)j];*/
    //(a+bj)*(c+dj) = ac-bd+(ad+bc)j
    int i, j;
    logic signed [WIDTH+11:0] ac_01prod_diff_reg[0:15];  // Diff 브랜치 중간 AC
    logic signed [WIDTH+11:0] bd_01prod_diff_reg[0:15];  // Diff 브랜치 중간 BD
    logic signed [WIDTH+11:0] ad_01prod_diff_reg[0:15];  // Diff 브랜치 중간 AD
    logic signed [WIDTH+11:0] bc_01prod_diff_reg[0:15];  // Diff 브랜치 중간 BC

    logic signed [WIDTH+11:0] ac_01prod_sum_reg[0:15];  // Diff 브랜치 중간 AC
    logic signed [WIDTH+11:0] bd_01prod_sum_reg[0:15];  // Diff 브랜치 중간 BD
    logic signed [WIDTH+11:0] ad_01prod_sum_reg[0:15];  // Diff 브랜치 중간 AD
    logic signed [WIDTH+11:0] bc_01prod_sum_reg[0:15];  // Diff 브랜치 중간 BC
/*
    logic signed [WIDTH+3:0] reg_twd_01bfly_sum_re [0:15];  //<5.6> * <2.8> -> <7.14> -> <7.6>
    logic signed [WIDTH+3:0] reg_twd_01bfly_sum_im [0:15];  //<5.6> * <2.8> -> <7.14> -> <7.6>
    logic signed [WIDTH+3:0] reg_twd_01bfly_diff_re[0:15];  //<5.6> * <2.8> -> <7.14> -> <7.6>
    logic signed [WIDTH+3:0] reg_twd_01bfly_diff_im[0:15];  //<5.6> * <2.8> -> <7.14> -> <7.6>
*/
    logic [3:0] twd_01_cnt;
    logic [3:0] twd_01_idx;

    counter #(
        .COUNT_MAX_VAL(CLK_CNT)
    ) U_TWD_01_CNT (
        .clk      (clk),
        .rstn     (rstn),
        .en       (twd01_valid),  //twd00_valid
        .count_out(twd_01_cnt)
    );
    assign twd_01_idx = twd_01_cnt / 4;
/*
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            for (i = 0; i < 16; i++) begin
                twd_01bfly_sum_re[i]  <= '0;
                twd_01bfly_sum_im[i]  <= '0;
                twd_01bfly_diff_re[i] <= '0;
                twd_01bfly_diff_im[i] <= '0;
            end
        end else if (twd01_valid) begin
            for (i = 0; i < 16; i++) begin
                twd_01bfly_sum_re[i]  <= reg_twd_01bfly_sum_re[i];
                twd_01bfly_sum_im[i]  <= reg_twd_01bfly_sum_im[i];
                twd_01bfly_diff_re[i] <= reg_twd_01bfly_diff_re[i];
                twd_01bfly_diff_im[i] <= reg_twd_01bfly_diff_im[i];
            end
        end
    end
*/
    always @(*) begin
        case (twd_01_idx)
            0: begin
                for (j = 0; j < 16; j++) begin
                    twd_01bfly_sum_re[j]  = i_01bfly_sum_re[j];
                    twd_01bfly_sum_im[j]  = i_01bfly_sum_im[j];
                    twd_01bfly_diff_re[j] = i_01bfly_diff_re[j];
                    twd_01bfly_diff_im[j] = i_01bfly_diff_im[j];
                end
            end
            1: begin
                for (j = 0; j < 16; j++) begin
                    twd_01bfly_sum_re[j]  = i_01bfly_sum_re[j];
                    twd_01bfly_sum_im[j]  = i_01bfly_sum_im[j];
                    twd_01bfly_diff_re[j] = i_01bfly_diff_im[j];
                    twd_01bfly_diff_im[j] = -i_01bfly_diff_re[j];
                end
            end
            //c : 181, d : -181
            2: begin
                for (j = 0; j < 16; j++) begin
                    twd_01bfly_sum_re[j]  = i_01bfly_sum_re[j];
                    twd_01bfly_sum_im[j]  = i_01bfly_sum_im[j];
                    twd_01bfly_diff_re[j] = i_01bfly_diff_re[j];
                    twd_01bfly_diff_im[j] = i_01bfly_diff_im[j];
                end
            end
            3: begin
                for (j = 0; j < 16; j++) begin
                    ac_01prod_sum_reg[j] = i_01bfly_sum_re[j] * 181;
                    bd_01prod_sum_reg[j] = i_01bfly_sum_im[j] * (-181);
                    ad_01prod_sum_reg[j] = i_01bfly_sum_re[j] * (-181);
                    bc_01prod_sum_reg[j] = i_01bfly_sum_im[j] * 181;
                    // 반올림 적용: 오른쪽으로 8비트 시프트하기 전에 128을 더합니다.
                    twd_01bfly_sum_re[j] = (ac_01prod_sum_reg[j] - bd_01prod_sum_reg[j] + 128)>>>8;
                    twd_01bfly_sum_im[j] = (ad_01prod_sum_reg[j] + bc_01prod_sum_reg[j] + 128)>>>8;

                    ac_01prod_diff_reg[j] = i_01bfly_diff_re[j] * (-181);
                    bd_01prod_diff_reg[j] = i_01bfly_diff_im[j] * (-181);
                    ad_01prod_diff_reg[j] = i_01bfly_diff_re[j] * (-181);
                    bc_01prod_diff_reg[j] = i_01bfly_diff_im[j] * (-181);
                    // 반올림 적용: 오른쪽으로 8비트 시프트하기 전에 128을 더합니다.
                    twd_01bfly_diff_re[j] = (ac_01prod_diff_reg[j] - bd_01prod_diff_reg[j] + 128)>>>8;
                    twd_01bfly_diff_im[j] = (ad_01prod_diff_reg[j] + bc_01prod_diff_reg[j] + 128)>>>8;
                end
            end
            default: begin
                for (j = 0; j < 16; j++) begin
                    twd_01bfly_sum_re[j]  = i_01bfly_sum_re[j];
                    twd_01bfly_sum_im[j]  = i_01bfly_sum_im[j];
                    twd_01bfly_diff_re[j] = i_01bfly_diff_re[j];
                    twd_01bfly_diff_im[j] = i_01bfly_diff_im[j];
                end
            end
        endcase
    end
endmodule