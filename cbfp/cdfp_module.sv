`timescale 1ns/1ps
`default_nettype none

// ============================================================================
// final_normalize_module2  (index1+index2 -> final shift <9.4> + saturation)
// ============================================================================
module final_normalize_module2 #(
    parameter int IN_W     = 16,  // input width (e.g., 16b from bfly22_tmp)
    parameter int OUT_W    = 13,  // final width (<9.4>)
    parameter int SHIFT_W  = 5,
    parameter int REF_SUM  = 23,
    parameter int FINAL_REF= 9
)(
    input  logic clk,
    input  logic rst_n,
    input  logic valid_in,

    input  logic signed [IN_W-1:0] data_re_in [0:511],
    input  logic signed [IN_W-1:0] data_im_in [0:511],
    input  logic [SHIFT_W-1:0]     index1_re_in [0:511],
    input  logic [SHIFT_W-1:0]     index1_im_in [0:511],
    input  logic [SHIFT_W-1:0]     index2_re_in [0:511],
    input  logic [SHIFT_W-1:0]     index2_im_in [0:511],

    output logic signed [OUT_W-1:0] data_re_out[0:511],
    output logic signed [OUT_W-1:0] data_im_out[0:511],
    output logic valid_out
);

    // regs
    logic signed [IN_W-1:0] data_re_reg [0:511];
    logic signed [IN_W-1:0] data_im_reg [0:511];
    logic [SHIFT_W:0] indexsum_re_reg [0:511];
    logic [SHIFT_W:0] indexsum_im_reg [0:511];
    logic valid_reg;

    logic signed [IN_W+8-1:0] tmp_re [0:511];
    logic signed [IN_W+8-1:0] tmp_im [0:511];
    logic signed [OUT_W-1:0] sat_re [0:511];
    logic signed [OUT_W-1:0] sat_im [0:511];

    // capture
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_reg <= 1'b0;
            for (int i=0; i<512; i++) begin
                data_re_reg[i]     <= '0;
                data_im_reg[i]     <= '0;
                indexsum_re_reg[i] <= '0;
                indexsum_im_reg[i] <= '0;
            end
        end else begin
            valid_reg <= 1'b0;
            if (valid_in) begin
                valid_reg <= 1'b1;
                for (int i=0; i<512; i++) begin
                    data_re_reg[i]     <= data_re_in[i];
                    data_im_reg[i]     <= data_im_in[i];
                    indexsum_re_reg[i] <= index1_re_in[i] + index2_re_in[i];
                    indexsum_im_reg[i] <= index1_im_in[i] + index2_im_in[i];
                end
            end
        end
    end

    // output scaling
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_out <= 1'b0;
            for (int i=0; i<512; i++) begin
                tmp_re[i] <= '0;
                tmp_im[i] <= '0;
            end
        end else begin
            valid_out <= valid_reg;
            if (valid_reg) begin
                for (int i=0; i<512; i++) begin
                    if (indexsum_re_reg[i] >= REF_SUM) begin
                        tmp_re[i] <= '0;
                    end else begin
                        automatic int sh_re = FINAL_REF - indexsum_re_reg[i];
                        tmp_re[i] = {{8{data_re_reg[i][IN_W-1]}}, data_re_reg[i]};
                        if (sh_re > 0)      tmp_re[i] = tmp_re[i] <<< sh_re;
                        else if (sh_re < 0) tmp_re[i] = tmp_re[i] >>> (-sh_re);
                    end
                    if (indexsum_im_reg[i] >= REF_SUM) begin
                        tmp_im[i] <= '0;
                    end else begin
                        automatic int sh_im = FINAL_REF - indexsum_im_reg[i];
                        tmp_im[i] = {{8{data_im_reg[i][IN_W-1]}}, data_im_reg[i]};
                        if (sh_im > 0)      tmp_im[i] = tmp_im[i] <<< sh_im;
                        else if (sh_im < 0) tmp_im[i] = tmp_im[i] >>> (-sh_im);
                    end
                end
            end
        end
    end

    // instantiate saturator
    generate
        genvar k;
        for (k = 0; k < 512; k++) begin : GEN_SAT
            sat #(.IN_W(IN_W+8), .OUT_W(OUT_W)) u_sat_re (
                .din(tmp_re[k]),
                .dout(sat_re[k])
            );
            sat #(.IN_W(IN_W+8), .OUT_W(OUT_W)) u_sat_im (
                .din(tmp_im[k]),
                .dout(sat_im[k])
            );
        end
    endgenerate

    // assign final output
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int i=0; i<512; i++) begin
                data_re_out[i] <= '0;
                data_im_out[i] <= '0;
            end
        end else if (valid_reg) begin
            for (int i=0; i<512; i++) begin
                data_re_out[i] <= sat_re[i];
                data_im_out[i] <= sat_im[i];
            end
        end
    end

endmodule

`default_nettype wire
