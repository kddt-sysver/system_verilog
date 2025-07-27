`timescale 1ns/1ps
`default_nettype none

// ============================================================================
// cbfp_streaming_module (streaming version of final_normalize_module2)
// Processes 16 samples per cycle, accumulates over 32 cycles (total 512 pts)
// ============================================================================
module cbfp_streaming_module #(
    parameter int IN_W     = 16,
    parameter int OUT_W    = 13,
    parameter int SHIFT_W  = 5,
    parameter int REF_SUM  = 23,
    parameter int FINAL_REF= 9
)(
    input  logic clk,
    input  logic rst_n,
    input  logic valid_in,

    input  logic signed [IN_W-1:0] data_re_in [0:15],
    input  logic signed [IN_W-1:0] data_im_in [0:15],
    input  logic [SHIFT_W-1:0]     index1_re_in [0:15],
    input  logic [SHIFT_W-1:0]     index1_im_in [0:15],
    input  logic [SHIFT_W-1:0]     index2_re_in [0:15],
    input  logic [SHIFT_W-1:0]     index2_im_in [0:15],

    output logic signed [OUT_W-1:0] data_re_out [0:15],
    output logic signed [OUT_W-1:0] data_im_out [0:15],
    output logic valid_out
);

    // Internal buffers for 512 samples
    logic signed [IN_W-1:0] data_re_buf [0:511];
    logic signed [IN_W-1:0] data_im_buf [0:511];
    logic [SHIFT_W:0] indexsum_re_buf [0:511];
    logic [SHIFT_W:0] indexsum_im_buf [0:511];

    // Temporary and final output storage
    logic signed [IN_W+8-1:0] tmp_re [0:15];
    logic signed [IN_W+8-1:0] tmp_im [0:15];
    logic signed [OUT_W-1:0] sat_re [0:15];
    logic signed [OUT_W-1:0] sat_im [0:15];

    // State and pointers
    logic [5:0] write_ptr, read_ptr;
    logic accumulating, outputting;
    logic valid_reg;

    // Loop indices (module-scope to avoid multiple drivers)
    int buf_idx;
    int acc_idx;
    int out_idx;
    int addr_idx;
    int final_idx;  // for final output loops
    int buf_idx;
    int acc_idx;
    int out_idx;
    int addr_idx;

    // Accumulate and output state machine
    // Final output register stage
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (final_idx = 0; final_idx < 16; final_idx++) begin
                data_re_out[final_idx] <= '0;
                data_im_out[final_idx] <= '0;
            end
            valid_out <= 0;
        end else begin
            valid_out <= valid_reg;
            if (valid_reg) begin
                for (final_idx = 0; final_idx < 16; final_idx++) begin
                    data_re_out[final_idx] <= sat_re[final_idx];
                    data_im_out[final_idx] <= sat_im[final_idx];
                end
            end
        end
    end

endmodule

`default_nettype wire
