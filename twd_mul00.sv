module twd_mul00 #(
    parameter int WIDTH = 9,
    CLK_CNT = 4
) (
    input logic clk,
    input logic rstn,
    input logic twd00_valid,
    input logic signed [WIDTH:0] i_00bfly_sum_re[0:15],  //<4.6>
    input logic signed [WIDTH:0] i_00bfly_sum_im[0:15],
    input logic signed [WIDTH:0] i_00bfly_diff_re[0:15],
    input logic signed [WIDTH:0] i_00bfly_diff_im[0:15],
    output logic signed [WIDTH:0] twd_00bfly_sum_re[0:15],
    output logic signed [WIDTH:0] twd_00bfly_sum_im[0:15],
    output logic signed [WIDTH:0] twd_00bfly_diff_re[0:15],
    output logic signed [WIDTH:0] twd_00bfly_diff_im[0:15]
);
    int i, j;
    logic signed [WIDTH:0] reg_twd_00bfly_sum_re [0:15];  //<5.6> * <2.8> -> <7.14> -> <7.6>
    logic signed [WIDTH:0] reg_twd_00bfly_sum_im [0:15];  //<5.6> * <2.8> -> <7.14> -> <7.6>
    logic signed [WIDTH:0] reg_twd_00bfly_diff_re[0:15];  //<5.6> * <2.8> -> <7.14> -> <7.6>
    logic signed [WIDTH:0] reg_twd_00bfly_diff_im[0:15];  //<5.6> * <2.8> -> <7.14> -> <7.6>
    logic [3:0] twd_00_cnt;
    logic [3:0] twd_00_idx;

    counter #(
        .WIDTH(CLK_CNT)
    ) U_TWD_01_CNT (
        .clk      (clk),
        .rstn     (rstn),
        .en       (twd00_valid),  //twd00_valid            
        .count_out(twd_00_cnt)
    );
    assign twd_00_idx = twd_00_cnt / 8;

    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            for (i = 0; i < 16; i++) begin
                twd_00bfly_sum_re[i]  <= '0;
                twd_00bfly_sum_im[i]  <= '0;
                twd_00bfly_diff_re[i] <= '0;
                twd_00bfly_diff_im[i] <= '0;
            end
        end else if (twd00_valid) begin
            for (i = 0; i < 16; i++) begin
                twd_00bfly_sum_re[i]  <= reg_twd_00bfly_sum_re[i];
                twd_00bfly_sum_im[i]  <= reg_twd_00bfly_sum_im[i];
                twd_00bfly_diff_re[i] <= reg_twd_00bfly_diff_re[i];
                twd_00bfly_diff_im[i] <= reg_twd_00bfly_diff_im[i];
            end
        end
    end

    always @(*) begin
        case (twd_00_idx)
            0: begin
                for (j = 0; j < 16; j++) begin
                    reg_twd_00bfly_sum_re[j]  = i_00bfly_sum_re[j];
                    reg_twd_00bfly_sum_im[j]  = i_00bfly_sum_im[j];
                    reg_twd_00bfly_diff_re[j] = i_00bfly_diff_re[j];
                    reg_twd_00bfly_diff_im[j] = i_00bfly_diff_im[j];
                end
            end
            1: begin
                for (j = 0; j < 16; j++) begin
                    reg_twd_00bfly_sum_re[j] = i_00bfly_sum_re[j];
                    reg_twd_00bfly_sum_im[j] = i_00bfly_sum_im[j];
                    reg_twd_00bfly_diff_re[i] <= i_00bfly_diff_im[i];
                    reg_twd_00bfly_diff_im[i] <= -i_00bfly_diff_re[i];
                end
            end
            default: begin
                reg_twd_00bfly_sum_re[j]  = i_00bfly_sum_re[j];
                reg_twd_00bfly_sum_im[j]  = i_00bfly_sum_im[j];
                reg_twd_00bfly_diff_re[j] = i_00bfly_diff_re[j];
                reg_twd_00bfly_diff_im[j] = i_00bfly_diff_im[j];
            end
        endcase
    end
endmodule
