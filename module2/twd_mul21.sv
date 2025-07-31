`timescale 1ns / 1ps
module twd_mul21 #(
    parameter int WIDTH = 14
) (
    input  logic clk,
    input  logic rstn,
    input  logic twd21_valid,

    input  logic signed [WIDTH-1:0] i_21bfly_re[0:15],
    input  logic signed [WIDTH-1:0] i_21bfly_im[0:15],

    output logic signed [WIDTH+1:0] twd_21_re[0:15],
    output logic signed [WIDTH+1:0] twd_21_im[0:15]
);

    // fac8_1 = [256, 256, 256, -j*256, 256, 181-j*181, 256, -181-j*181];
    localparam signed [9:0] FAC_RE[0:7] = '{ 256, 256, 256,   0, 256,  181, 256, -181 };
    localparam signed [9:0] FAC_IM[0:7] = '{   0,   0,   0, -256,   0, -181,   0, -181 };

    int j;
    int nn;
    logic signed [WIDTH+9:0] ac, bd, ad, bc; // 곱셈 임시

    always_comb begin
        if (twd21_valid) begin
            for (j = 0; j < 16; j++) begin
                nn = j % 8;

                // === 복소수 곱셈 ( (a+jb)*(c+jd) ) ===
                ac = i_21bfly_re[j] * FAC_RE[nn];
                bd = i_21bfly_im[j] * FAC_IM[nn];
                ad = i_21bfly_re[j] * FAC_IM[nn];
                bc = i_21bfly_im[j] * FAC_RE[nn];

                // Q2.8 → 반올림 후 8비트 시프트 (round)
                twd_21_re[j] = (ac - bd + 128) >>> 8;
                twd_21_im[j] = (ad + bc + 128) >>> 8;
            end
        end
        else begin
            for (j = 0; j < 16; j++) begin
                twd_21_re[j] = '0;
                twd_21_im[j] = '0;
            end
        end
    end

endmodule
