`timescale 1ns / 1ps

module module_22 #(
    parameter int WIDTH = 16
) (
    input logic clk,
    input logic rstn,

    input logic signed [WIDTH-1:0] twd_21_re[0:15],
    input logic signed [WIDTH-1:0] twd_21_im[0:15],       // <10.6>
    input logic shift_22_valid,

    output logic signed [WIDTH:0] module_22_out_re[0:15],
    output logic signed [WIDTH:0] module_22_out_im[0:15],  // <11.6>
    output logic CBFP_valid
);

    logic w_bfly22_valid;
    logic w_twd22_valid;

    assign CBFP_valid = w_twd22_valid;

    counter_v3 #(
        .PULSE_CYCLES(32)  
    ) U_BFLY_VALID_CNT (
        .clk      (clk),
        .rstn     (rstn),
        .en       (shift_22_valid),  
        .out_pulse(w_bfly22_valid)  
    );

    bfly_v2 #(
        .WIDTH(16),
        .NUM_POINT(2)  // 블록 크기 (8→4, 4→2, 2→1)
    ) U_BFLY_22 (
        .clk(clk),
        .rstn(rstn),
        .bfly_valid(w_bfly22_valid),
        .din_re(twd_21_re),
        .din_im(twd_21_im),
        .bfly_re(module_22_out_re),
        .bfly_im(module_22_out_im),
        .twiddle_valid(w_twd22_valid)
    );


endmodule
