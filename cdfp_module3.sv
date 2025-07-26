`timescale 1ns/1ps
`default_nettype none

module cbfp_module #(
  parameter int IN_W      = 16,
  parameter int OUT_W     = 13,
  parameter int SHIFT_W   = 5,
  parameter int REF_SUM   = 23,
  parameter int FINAL_REF = 9
)(
  input  logic                     clk,
  input  logic                     rst_n,
  input  logic                     valid_in,
  input  logic signed [IN_W-1:0]   data_re_in [0:15],
  input  logic signed [IN_W-1:0]   data_im_in [0:15],
  input  logic        [SHIFT_W-1:0] index1_re_in[0:15],
  input  logic        [SHIFT_W-1:0] index1_im_in[0:15],
  input  logic        [SHIFT_W-1:0] index2_re_in[0:15],
  input  logic        [SHIFT_W-1:0] index2_im_in[0:15],

  output logic signed [OUT_W-1:0]  data_re_out[0:15],
  output logic signed [OUT_W-1:0]  data_im_out[0:15],
  output logic                     valid_out
);

  //--------------------------------------------------------------------------
  //  Internal helper functions
  //--------------------------------------------------------------------------

  // mag_detect: 절댓값 최상위 비트 인덱스
  function automatic int mag_fn(input logic signed [IN_W-1:0] x);
    int idx;
    logic [IN_W-1:0] absx;
    begin
      absx = x[IN_W-1] ? -x : x;
      for (idx = IN_W-1; idx >= 0; idx = idx-1)
        if (absx[idx]) return idx;
      return 0;
    end
  endfunction

  // min_detect: 두 값 중 작은 쪽
  function automatic int min_fn(input int a, input int b);
    begin
      return (a < b) ? a : b;
    end
  endfunction

  // sat_fn: IN_W+8 → OUT_W 비트 포화
  function automatic logic signed [OUT_W-1:0] sat_fn(input logic signed [IN_W+8-1:0] v);
    logic signed [IN_W+8-1:0] maxv, minv;
    begin
      maxv = {1'b0, {(IN_W+8-1){1'b1}}};
      minv = {1'b1, {(IN_W+8-1){1'b0}}};
      if (v > maxv)  return maxv[OUT_W-1:0];
      if (v < minv)  return minv[OUT_W-1:0];
      return v[OUT_W-1:0];
    end
  endfunction

  //--------------------------------------------------------------------------
  //  Parameters & locals
  //--------------------------------------------------------------------------
  localparam int LANES = 16;
  localparam int WIN   = 64;
  localparam int DEPTH = WIN;
  localparam int PHASE = DEPTH / LANES; // 4

  //--------------------------------------------------------------------------
  //  State & storage
  //--------------------------------------------------------------------------
  logic signed [IN_W-1:0] win_re[0:DEPTH-1], win_im[0:DEPTH-1];
  logic [$clog2(REF_SUM+1)-1:0] cnt_re, cnt_im;
  logic [2:0] phase_cnt;
  int tmp_re [0:LANES-1];
  int tmp_im [0:LANES-1];

  // Pipeline registers for output shift amounts
  logic [$clog2(REF_SUM+1)-1:0] shift_re_pipe, shift_im_pipe;
  logic output_enable;

  // Loop indices
  int i, j, l;

  //--------------------------------------------------------------------------
  //  Main processing pipeline
  //--------------------------------------------------------------------------
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      phase_cnt <= 0;
      cnt_re    <= REF_SUM;
      cnt_im    <= REF_SUM;
      shift_re_pipe <= 0;
      shift_im_pipe <= 0;
      output_enable <= 1'b0;
      for (i = 0; i < DEPTH; i = i+1) begin
        win_re[i] <= '0;
        win_im[i] <= '0;
      end
    end else if (valid_in) begin
      
      // 1) Per-lane magnitude detection
      for (j = 0; j < LANES; j = j+1) begin
        tmp_re[j] = mag_fn(data_re_in[j]);
        tmp_im[j] = mag_fn(data_im_in[j]);
      end

      // 2) Block-level min detection
      if (phase_cnt == 0) begin
        // Start new block - initialize with first lane
        cnt_re = tmp_re[0];
        cnt_im = tmp_im[0];
        for (j = 1; j < LANES; j = j+1) begin
          cnt_re = min_fn(tmp_re[j], cnt_re);
          cnt_im = min_fn(tmp_im[j], cnt_im);
        end
      end else begin
        // Continue block - update running minimum
        for (j = 0; j < LANES; j = j+1) begin
          cnt_re = min_fn(tmp_re[j], cnt_re);
          cnt_im = min_fn(tmp_im[j], cnt_im);
        end
      end

      // 3) Sliding window shift (always shift regardless of phase)
      for (i = DEPTH-1; i >= LANES; i = i-1) begin
        win_re[i] <= win_re[i-LANES];
        win_im[i] <= win_im[i-LANES];
      end
      for (j = 0; j < LANES; j = j+1) begin
        win_re[j] <= data_re_in[j];
        win_im[j] <= data_im_in[j];
      end

      // 4) Phase counter and pipeline control
      if (phase_cnt == PHASE-1) begin
        // Block complete - pipeline the shift amounts for next cycle output
        shift_re_pipe <= cnt_re;
        shift_im_pipe <= cnt_im;
        phase_cnt <= 0;
        // Enable output starting from next cycle (when 5th group arrives)
        output_enable <= 1'b1;
      end else begin
        phase_cnt <= phase_cnt + 1;
        // Keep previous shift amounts if not block boundary
      end
      
    end else begin
      // No valid input - disable output
      output_enable <= 1'b0;
    end
  end

  //--------------------------------------------------------------------------
  //  Output generation (combinational for current cycle output)
  //--------------------------------------------------------------------------
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      valid_out <= 1'b0;
      for (l = 0; l < LANES; l = l+1) begin
        data_re_out[l] <= '0;
        data_im_out[l] <= '0;
      end
    end else begin
      // Output is valid when we have valid input AND output is enabled
      valid_out <= valid_in && output_enable;
      
      if (valid_in && output_enable) begin
        for (l = 0; l < LANES; l = l+1) begin
          logic signed [IN_W+8-1:0] ext_re, ext_im;
          logic signed [IN_W+8-1:0] shifted_re, shifted_im;
          
          // Use data from the oldest position (will be shifted out)
          // This is the data that was 64 positions ago
          ext_re = {{8{win_re[DEPTH-LANES+l][IN_W-1]}}, win_re[DEPTH-LANES+l]};
          ext_im = {{8{win_im[DEPTH-LANES+l][IN_W-1]}}, win_im[DEPTH-LANES+l]};
          
          // Apply the pipelined shift amounts (from previous block's detection)
          shifted_re = ext_re <<< (FINAL_REF - shift_re_pipe);
          shifted_im = ext_im <<< (FINAL_REF - shift_im_pipe);
          
          // Saturate to output width
          data_re_out[l] <= sat_fn(shifted_re);
          data_im_out[l] <= sat_fn(shifted_im);
        end
      end
    end
  end

endmodule

`default_nettype wire
