`timescale 1ns/1ps
`default_nettype none

module cbfp_module #(
  parameter  IN_W      = 16,
  parameter  OUT_W     = 13,
  parameter  SHIFT_W   = $clog2(IN_W), 
  parameter  REF_SUM   = 23,
  parameter  FINAL_REF = 9

)(
  input  logic                     clk,
  input  logic                     rstn,
  input  logic                     valid_in,
  input  logic signed [IN_W-1:0]   data_re_in [0:15],
  input  logic signed [IN_W-1:0]   data_im_in [0:15],

  output logic signed [OUT_W-1:0]  data_re_out[0:15],
  output logic signed [OUT_W-1:0]  data_im_out[0:15],
  output logic                     valid_out
);

  // ---------------------------------------------
  // Shift Register for Delay Alignment
  // ---------------------------------------------
  logic signed [IN_W-1:0] shift_data_re[0:15];
  logic signed [IN_W-1:0] shift_data_im[0:15];

  shift_reg #(
    .WIDTH(IN_W),
    .MEM_DEPTH(64)
  ) u_shift_reg (
    .clk(clk),
    .rstn(rstn),
    .din_re(data_re_in),
    .din_im(data_im_in),
    .valid(valid_in),
    .shift_data_re(shift_data_re),
    .shift_data_im(shift_data_im)
  );

  // ---------------------------------------------
  // mag_detect: 절댓값의 MSB 위치 탐색
  // ---------------------------------------------
  logic [SHIFT_W-1:0] mag_index_re[0:15];
  logic [SHIFT_W-1:0] mag_index_im[0:15];
  logic [SHIFT_W-1:0] max_mag_index[0:15];

  genvar i;
  generate
    for (i = 0; i < 16; i++) begin : G_MAG
      mag_detect #(.WIDTH(IN_W)) u_mag_re (
        .in(shift_data_re[i]),
        .index(mag_index_re[i])
      );
      mag_detect #(.WIDTH(IN_W)) u_mag_im (
        .in(shift_data_im[i]),
        .index(mag_index_im[i])
      );

      assign max_mag_index[i] = (mag_index_re[i] > mag_index_im[i]) ?
                                 mag_index_re[i] : mag_index_im[i];
    end
  endgenerate

  // ---------------------------------------------
  // min_detect: 전체 샘플 중 최소 MSB 위치 탐색
  // ---------------------------------------------
  logic [SHIFT_W-1:0] cur_min_idx;
  logic [SHIFT_W-1:0] min_tmp;

  integer j;
  always_comb begin
   min_tmp = max_mag_index[0];
    for (j = 1; j < 16; j++) begin
     if (max_mag_index[j] < min_tmp)
       min_tmp = max_mag_index[j];
    end
   cur_min_idx = min_tmp;
 end


  // ---------------------------------------------
  // Shift Amount for CBFP
  // shift_amt = REF_SUM - cur_min_idx - FINAL_REF
  // ---------------------------------------------
  logic signed [SHIFT_W:0] shift_amt;
  always_comb begin
    shift_amt = REF_SUM - cur_min_idx - FINAL_REF;
  end

  // ---------------------------------------------
  // Apply Bit Shift and Saturation
  // ---------------------------------------------
  logic signed [IN_W+7:0] norm_data_re[0:15];
  logic signed [IN_W+7:0] norm_data_im[0:15];

  generate
    for (i = 0; i < 16; i++) begin : G_SHIFT
      assign norm_data_re[i] = shift_data_re[i] <<< shift_amt;
      assign norm_data_im[i] = shift_data_im[i] <<< shift_amt;

      sat #(.IN_W(IN_W+8), .OUT_W(OUT_W)) u_sat_re (
        .din(norm_data_re[i]),
        .dout(data_re_out[i])
      );
      sat #(.IN_W(IN_W+8), .OUT_W(OUT_W)) u_sat_im (
        .din(norm_data_im[i]),
        .dout(data_im_out[i])
      );
    end
  endgenerate

  // ---------------------------------------------
  // Valid Output (1clk Delay)
  // ---------------------------------------------
  logic valid_in_d;
  always_ff @(posedge clk or negedge rstn) begin
    if (!rstn)
      valid_in_d <= 1'b0;
    else
      valid_in_d <= valid_in;
  end

  assign valid_out = valid_in_d;

endmodule

`default_nettype wire
