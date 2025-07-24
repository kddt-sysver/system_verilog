`timescale 1ns/1ps

module tb_bfly;

  parameter WIDTH = 12;
  parameter NUM_PAIR = 16;

  logic clk, rstn;
  logic bfly_valid;
  logic signed [WIDTH-1:0] din_re [0:NUM_PAIR-1];
  logic signed [WIDTH-1:0] din_im [0:NUM_PAIR-1];
  logic signed [WIDTH-1:0] shift_data_re [0:NUM_PAIR-1];
  logic signed [WIDTH-1:0] shift_data_im [0:NUM_PAIR-1];
  logic signed [WIDTH:0] bfly_sum_re [0:NUM_PAIR-1];
  logic signed [WIDTH:0] bfly_sum_im [0:NUM_PAIR-1];
  logic signed [WIDTH:0] bfly_diff_re [0:NUM_PAIR-1];
  logic signed [WIDTH:0] bfly_diff_im [0:NUM_PAIR-1];
  logic twiddle_valid;

  // DUT instantiation
  bfly #(
    .WIDTH(WIDTH),
    .NUM_PAIR(NUM_PAIR)
  ) dut (
    .clk(clk),
    .rstn(rstn),
    .bfly_valid(bfly_valid),
    .din_re(din_re),
    .din_im(din_im),
    .shift_data_re(shift_data_re),
    .shift_data_im(shift_data_im),
    .bfly_sum_re(bfly_sum_re),
    .bfly_sum_im(bfly_sum_im),
    .bfly_diff_re(bfly_diff_re),
    .bfly_diff_im(bfly_diff_im),
    .twiddle_valid(twiddle_valid)
  );

  // Clock generation
  initial clk = 0;
  always #5 clk = ~clk;  // 100MHz clock

  // Stimulus
  initial begin
    $display("=== START TB ===");
    rstn = 0;
    bfly_valid = 0;
    for (int i = 0; i < NUM_PAIR; i++) begin
      din_re[i] = 0;
      din_im[i] = 0;
      shift_data_re[i] = 0;
      shift_data_im[i] = 0;
    end

    @(posedge clk);
    rstn = 1;

    // === [1] IDLE ===
    for (int cyc = 0; cyc < NUM_PAIR; cyc++) begin
      @(posedge clk);
      for (int i = 0; i < NUM_PAIR; i++) begin
        din_re[i]        = $signed(cyc * 10 + i + 0);
        din_im[i]        = $signed(cyc * 10 + i + 100);
        shift_data_re[i] = $signed(cyc * 10 + i + 200);
        shift_data_im[i] = $signed(cyc * 10 + i + 300);
      end
      bfly_valid = 0;
    end

    // === [2] SUM ===
    for (int cyc = 0; cyc < NUM_PAIR; cyc++) begin
      @(posedge clk);
      for (int i = 0; i < NUM_PAIR; i++) begin
        din_re[i]        = $signed(cyc + 30);
        din_im[i]        = $signed(cyc + 130);
        shift_data_re[i] = $signed(cyc + 40);
        shift_data_im[i] = $signed(cyc + 230);
      end
      bfly_valid = 1;
    end

    // === [3] IDLE2 ===
    for (int cyc = 0; cyc < NUM_PAIR; cyc++) begin
      @(posedge clk);
      for (int i = 0; i < NUM_PAIR; i++) begin
        din_re[i]        = $signed(cyc + 50);
        din_im[i]        = $signed(cyc + 150);
        shift_data_re[i] = $signed(cyc + 60);
        shift_data_im[i] = $signed(cyc + 250);
      end
      bfly_valid = 0;
    end

    // === [4] DIFF ===
    for (int cyc = 0; cyc < NUM_PAIR; cyc++) begin
      @(posedge clk);
      for (int i = 0; i < NUM_PAIR; i++) begin
        din_re[i]        = $signed(cyc + 70);
        din_im[i]        = $signed(cyc + 170);
        shift_data_re[i] = $signed(cyc + 80);
        shift_data_im[i] = $signed(cyc + 270);
      end
      bfly_valid = 1;
    end

    // === [5] 마무리 ===
    bfly_valid = 0;
    repeat (5) @(posedge clk);

    $display("=== END TB ===");
    $finish;
  end

endmodule
