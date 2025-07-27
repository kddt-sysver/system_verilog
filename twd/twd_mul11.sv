`timescale 1ns/1ps
module twd_mul11 #(
    parameter int WIDTH = 13, 
    parameter int CLK_CNT = 8
) (
    input logic clk,
    input logic rstn,
    input logic twd11_valid,
    input logic signed [WIDTH-1:0] i_11bfly_sum_re[0:15],  // <7.6>
    input logic signed [WIDTH-1:0] i_11bfly_sum_im[0:15],  
    input logic signed [WIDTH-1:0] i_11bfly_diff_re[0:15],  
    input logic signed [WIDTH-1:0] i_11bfly_diff_im[0:15],  
    output logic signed [WIDTH+1:0] twd_11bfly_sum_re [0:15],  // <7.6> * <2.8> -> <9.14> -> <9.6>
    output logic signed [WIDTH+1:0] twd_11bfly_sum_im [0:15],  
    output logic signed [WIDTH+1:0] twd_11bfly_diff_re[0:15],  
    output logic signed [WIDTH+1:0] twd_11bfly_diff_im[0:15] 
);
    /*fac8_1 = [1 + 0j, 1 + 0j, 1 + 0j, 0 - j, 1 + 0j, 
    181+(-181)j, 1 + 0j, 181+(-181)j];*/
    //(a+bj)*(c+dj) = ac-bd+(ad+bc)j
    int i, j;
    logic signed [WIDTH+10:0] ac_11prod_diff_reg[0:15];  // Diff 브랜치 중간 AC
    logic signed [WIDTH+10:0] bd_11prod_diff_reg[0:15];  // Diff 브랜치 중간 BD
    logic signed [WIDTH+10:0] ad_11prod_diff_reg[0:15];  // Diff 브랜치 중간 AD
    logic signed [WIDTH+10:0] bc_11prod_diff_reg[0:15];  // Diff 브랜치 중간 BC

    logic signed [WIDTH+1:0] reg_twd_11bfly_sum_re [0:15];  // <7.6> * <2.8> -> <9.14> -> <9.6>
    logic signed [WIDTH+1:0] reg_twd_11bfly_sum_im [0:15];  
    logic signed [WIDTH+1:0] reg_twd_11bfly_diff_re[0:15];  
    logic signed [WIDTH+1:0] reg_twd_11bfly_diff_im[0:15];  
    logic [3:0] twd_11_cnt;
    logic [3:0] twd_11_idx;

    counter #(
        .COUNT_MAX_VAL(CLK_CNT)
    ) U_TWD_11_CNT (
        .clk      (clk),
        .rstn     (rstn),
        .en       (twd11_valid),  
        .count_out(twd_11_cnt)
    );
    assign twd_11_idx = twd_11_cnt / 2; // 2클럭마다
    
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            for (i = 0; i < 16; i++) begin
                twd_11bfly_sum_re[i]  <= '0;
                twd_11bfly_sum_im[i]  <= '0;
                twd_11bfly_diff_re[i] <= '0;
                twd_11bfly_diff_im[i] <= '0;
            end
        end else if (twd11_valid) begin
            for (i = 0; i < 16; i++) begin
                twd_11bfly_sum_re[i]  <= reg_twd_11bfly_sum_re[i];
                twd_11bfly_sum_im[i]  <= reg_twd_11bfly_sum_im[i];
                twd_11bfly_diff_re[i] <= reg_twd_11bfly_diff_re[i];
                twd_11bfly_diff_im[i] <= reg_twd_11bfly_diff_im[i];
            end
        end
    end

    always @(*) begin
        case (twd_11_idx)
            0, 1, 2, 4, 6: begin // twiddle = 1
                for (j = 0; j < 16; j++) begin
                    reg_twd_11bfly_sum_re[j]  = i_11bfly_sum_re[j];
                    reg_twd_11bfly_sum_im[j]  = i_11bfly_sum_im[j];
                    reg_twd_11bfly_diff_re[j] = i_11bfly_diff_re[j];
                    reg_twd_11bfly_diff_im[j] = i_11bfly_diff_im[j];
                end
            end
            3: begin // twiddle = -j
                for (j = 0; j < 16; j++) begin
                    reg_twd_11bfly_sum_re[j]  = i_11bfly_sum_re[j];
                    reg_twd_11bfly_sum_im[j]  = i_11bfly_sum_im[j];
                    reg_twd_11bfly_diff_re[j] =  i_11bfly_diff_im[j];
                    reg_twd_11bfly_diff_im[j] = -i_11bfly_diff_re[j];
                end
            end
            5: begin // twiddle = 181 - j181
                for (j = 0; j < 16; j++) begin
                    reg_twd_11bfly_sum_re[j] = i_11bfly_sum_re[j];
                    reg_twd_11bfly_sum_im[j] = i_11bfly_sum_im[j];

                    ac_11prod_diff_reg[j] = i_11bfly_diff_re[j] * 181;
                    bd_11prod_diff_reg[j] = i_11bfly_diff_im[j] * (-181);
                    ad_11prod_diff_reg[j] = i_11bfly_diff_re[j] * (-181);
                    bc_11prod_diff_reg[j] = i_11bfly_diff_im[j] * 181;

                    reg_twd_11bfly_diff_re[j] = (ac_11prod_diff_reg[j] - bd_11prod_diff_reg[j]) >>> 8;
                    reg_twd_11bfly_diff_im[j] = (ad_11prod_diff_reg[j] + bc_11prod_diff_reg[j]) >>> 8;
                end
            end
            7: begin // twiddle = -181 - j181
                for (j = 0; j < 16; j++) begin
                    reg_twd_11bfly_sum_re[j] = i_11bfly_sum_re[j];
                    reg_twd_11bfly_sum_im[j] = i_11bfly_sum_im[j];

                    ac_11prod_diff_reg[j] = i_11bfly_diff_re[j] * (-181);
                    bd_11prod_diff_reg[j] = i_11bfly_diff_im[j] * (-181);
                    ad_11prod_diff_reg[j] = i_11bfly_diff_re[j] * 181;
                    bc_11prod_diff_reg[j] = i_11bfly_diff_im[j] * (-181);

                    reg_twd_11bfly_diff_re[j] = (ac_11prod_diff_reg[j] - bd_11prod_diff_reg[j]) >>> 8;
                    reg_twd_11bfly_diff_im[j] = (ad_11prod_diff_reg[j] + bc_11prod_diff_reg[j]) >>> 8;
                end
            end
            default: begin
                for (j = 0; j < 16; j++) begin
                    reg_twd_11bfly_sum_re[j]  = i_11bfly_sum_re[j];
                    reg_twd_11bfly_sum_im[j]  = i_11bfly_sum_im[j];
                    reg_twd_11bfly_diff_re[j] = i_11bfly_diff_re[j];
                    reg_twd_11bfly_diff_im[j] = i_11bfly_diff_im[j];
                end
            end
        endcase
    end
endmodule

