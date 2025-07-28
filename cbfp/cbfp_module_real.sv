`timescale 1ns/1ps
`default_nettype none

// CBFP Module: Convergent Block Floating-Point (Stage 0)
// This module now takes 16-bit input data (from pre_bfly00.txt) and scales it to <5.6> (11-bit) output.
// It relies on external 'sat', 'mag_detect', and 'shift_reg' modules.
module cbfp_module #(
    parameter int IN_W      = 16,  // Input data bit width (Adjusted to 16 for pre_bfly00.txt)
    parameter int OUT_W     = 11,  // Output data bit width (e.g., 11 for <5.6>)
    // Internal constants
    localparam int EXT_W    = 16,               // mag_detect input width (Adjusted to 16)
    localparam int IDX_W    = $clog2(EXT_W),    // mag_detect output bit width (Adjusted to $clog2(16)=4)
    localparam int NCHAN    = 16,               // Number of channels
    // Parameters for scaling adjustment
    // REF_SUM: Target MSB position for the output (8로 조정하여 pre_bfly00 -> bfly02 스케일링 일치).
    // FINAL_REF: Offset (set to 0 if REF_SUM directly represents target MSB).
    // shift_amt = REF_SUM - cur_min_idx - FINAL_REF
    // For <5.6> output, the MSB is at bit 10. 그러나 실제 데이터 매칭을 위해 8로 조정.
    parameter int REF_SUM   = 8,   // **수정됨: 10에서 8로 변경하여 데이터 스케일링 맞춤**
    parameter int FINAL_REF = 0    // No additional offset needed
)(
    input  logic                     clk,
    input  logic                     rstn,
    input  logic                     valid_in,
    input  logic signed [IN_W-1:0]   data_re_in [NCHAN-1:0],
    input  logic signed [IN_W-1:0]   data_im_in [NCHAN-1:0],
    output logic signed [OUT_W-1:0]  data_re_out[NCHAN-1:0],
    output logic signed [OUT_W-1:0]  data_im_out[NCHAN-1:0],
    output logic                     valid_out
);

    // ------------------------------------------------------------
    // 1) Delay alignment (shift register)
    //    Assumes 'shift_reg.sv' is available in the compilation environment.
    // ------------------------------------------------------------
    logic signed [IN_W-1:0] shift_data_re [NCHAN-1:0];
    logic signed [IN_W-1:0] shift_data_im [NCHAN-1:0];
    logic                   bfly_valid; // Valid signal from shift register

    shift_reg #(
        .WIDTH    (IN_W),
        .MEM_DEPTH(64), // Assuming 64 cycles delay for alignment as per MATLAB code structure
        .NCHAN    (NCHAN)
    ) u_shift_reg (
        .clk          (clk),
        .rstn         (rstn),
        .din_re       (data_re_in),
        .din_im       (data_im_in),
        .valid        (valid_in),
        .shift_data_re(shift_data_re),
        .shift_data_im(shift_data_im),
        .bfly_valid   (bfly_valid)
    );

    // ------------------------------------------------------------
    // 2) mag_detect: Find MSB position of absolute value
    //    Assumes 'mag_detect.sv' is available in the compilation environment.
    // ------------------------------------------------------------
    logic [IDX_W-1:0] mag_index_re [NCHAN-1:0]; // MSB index for real part
    logic [IDX_W-1:0] mag_index_im [NCHAN-1:0]; // MSB index for imaginary part
    logic [IDX_W-1:0] max_mag_index [NCHAN-1:0]; // Max of real/imag MSB index per channel

    genvar i;
    generate
        for (i = 0; i < NCHAN; i++) begin : G_MAG
            // Sign-extend to EXT_W (16 bits) for mag_detect input
            logic signed [EXT_W-1:0] ext_re, ext_im;
            assign ext_re = {{(EXT_W-IN_W){shift_data_re[i][IN_W-1]}}, shift_data_re[i]};
            assign ext_im = {{(EXT_W-IN_W){shift_data_im[i][IN_W-1]}}, shift_data_im[i]};

            // Instantiate mag_detect for real and imaginary parts
            mag_detect #(.WIDTH(EXT_W)) u_mag_re (
                .in    (ext_re),
                .index (mag_index_re[i])
            );
            mag_detect #(.WIDTH(EXT_W)) u_mag_im (
                .in    (ext_im),
                .index (mag_index_im[i])
            );

            // Determine the maximum MSB index for each channel (between real and imaginary)
            assign max_mag_index[i] = (mag_index_re[i] > mag_index_im[i]) ?
                                      mag_index_re[i] : mag_index_im[i];
        end
    endgenerate

    // ------------------------------------------------------------
    // 3) min_detect: Extract the minimum MSB among all 16 channels
    // ------------------------------------------------------------
    logic [IDX_W-1:0] cur_min_idx; // Minimum MSB index across all channels
    always_comb begin
        cur_min_idx = max_mag_index[0]; // Initialize with the first channel's max MSB
        for (int j = 1; j < NCHAN; j++) begin
            if (max_mag_index[j] < cur_min_idx) begin
                cur_min_idx = max_mag_index[j]; // FIXED: Corrected typo from max_mag_idx
            end
        end
    end

    // ------------------------------------------------------------
    // 4) Calculate SHIFT amount based on standard CBFP logic
    // ------------------------------------------------------------
    // shift_amt: The amount to shift the data to normalize it to the target scale.
    // For <5.6> output, the MSB is at bit 10 (0-indexed).
    // The shift amount should bring the current MSB (cur_min_idx) to the target MSB (REF_SUM).
    logic signed [IDX_W:0] shift_amt; // Includes sign bit (IDX_W is 4, so 5 bits total)
    always_comb begin
        shift_amt = REF_SUM - cur_min_idx - FINAL_REF;
    end

    // ------------------------------------------------------------
    // 5) Arithmetic Shift and Saturation (sat)
    //    Assumes 'sat.sv' is available in the compilation environment.
    // ------------------------------------------------------------
    // NORM_W_SAFE: Bit width for the normalized data before saturation.
    // Max positive shift_amt can be 8 (if cur_min_idx=0, then 8-0=8).
    // Max negative shift_amt can be 8-15 = -7.
    // IN_W (16) + max positive shift (8) = 24.
    localparam int NORM_W_SAFE = IN_W + REF_SUM + 1; // 16 + 8 + 1 = 25

    logic signed [NORM_W_SAFE-1:0] norm_data_re [NCHAN-1:0]; // Normalized real data
    logic signed [NORM_W_SAFE-1:0] norm_data_im [NCHAN-1:0]; // Normalized imaginary data

    generate
        for (i = 0; i < NCHAN; i++) begin : G_SHIFT
            always_comb begin
                // Sign-extend the input data to NORM_W_SAFE before shifting to preserve sign.
                if (shift_amt >= 0) begin
                    // Left shift (multiplication)
                    norm_data_re[i] = {{NORM_W_SAFE-IN_W{shift_data_re[i][IN_W-1]}}, shift_data_re[i]} <<< shift_amt;
                    norm_data_im[i] = {{NORM_W_SAFE-IN_W{shift_data_im[i][IN_W-1]}}, shift_data_im[i]} <<< shift_amt;
                end else begin
                    // Right shift (division)
                    norm_data_re[i] = {{NORM_W_SAFE-IN_W{shift_data_re[i][IN_W-1]}}, shift_data_re[i]} >>> -shift_amt;
                    norm_data_im[i] = {{NORM_W_SAFE-IN_W{shift_data_im[i][IN_W-1]}}, shift_data_im[i]} >>> -shift_amt;
                end
            end

            // Instantiate saturation module for real part
            sat #(
                .IN_W (NORM_W_SAFE), // Input width to sat module
                .OUT_W(OUT_W)        // Output width from sat module (11 for <5.6>)
            ) u_sat_re (
                .din  (norm_data_re[i]),
                .dout (data_re_out[i])
            );
            // Instantiate saturation module for imaginary part
            sat #(
                .IN_W (NORM_W_SAFE),
                .OUT_W(OUT_W)
            ) u_sat_im (
                .din  (norm_data_im[i]),
                .dout (data_im_out[i])
            );
        end
    endgenerate

    // ------------------------------------------------------------
    // 6) valid_out: 1-cycle delay for output valid signal
    // ------------------------------------------------------------
    logic valid_d;
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            valid_d <= 1'b0;
        end else begin
            valid_d <= bfly_valid; // Output valid signal from shift register
        end
    end
    assign valid_out = valid_d;

endmodule

`default_nettype wire
