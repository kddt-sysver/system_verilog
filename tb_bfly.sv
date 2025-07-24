// 16쌍
`timescale 1ns/1ps

module tb_bfly;

  parameter WIDTH = 12;
  parameter NUM_PAIR = 16;  // 변경된 NUM_PAIR 값

  logic clk, rstn;
  logic bfly_valid;
  logic signed [WIDTH-1:0] din_re, din_im;
  logic signed [WIDTH-1:0] shift_data_re, shift_data_im;
  logic signed [WIDTH:0] bfly_sum_re, bfly_sum_im;
  logic signed [WIDTH:0] bfly_diff_re, bfly_diff_im;
  logic twiddle_valid;

  // DUT
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
    din_re = 0; din_im = 0;
    shift_data_re = 0; shift_data_im = 0;
    @(posedge clk); rstn = 1;

    // === [1] IDLE 상태용 대기 ===
    bfly_valid = 0;
    for (int i = 0; i < NUM_PAIR; i++) begin
      @(posedge clk);
      din_re        <= $signed(i + 10);
      din_im        <= $signed(i + 100);
      shift_data_re <= $signed(i + 20);
      shift_data_im <= $signed(i + 200);
    end

    // === [2] SUM 연산 ===
    bfly_valid = 1;
    for (int i = 0; i < NUM_PAIR; i++) begin
      @(posedge clk);
      din_re        <= $signed(i + 30);
      din_im        <= $signed(i + 110);
      shift_data_re <= $signed(i + 40);
      shift_data_im <= $signed(i + 210);
    end
    bfly_valid = 0;

    // === [3] IDLE2 대기 ===
    for (int i = 0; i < NUM_PAIR; i++) begin
      @(posedge clk);
      din_re        <= $signed(i + 50);
      din_im        <= $signed(i + 120);
      shift_data_re <= $signed(i + 60);
      shift_data_im <= $signed(i + 220);
    end

    // === [4] DIFF 연산 ===
    bfly_valid = 1;
    for (int i = 0; i < NUM_PAIR; i++) begin
      @(posedge clk);
      din_re        <= $signed(i + 70);
      din_im        <= $signed(i + 130);
      shift_data_re <= $signed(i + 80);
      shift_data_im <= $signed(i + 230);
    end
    bfly_valid = 0;

    // === 마무리 ===
    repeat (5) @(posedge clk);
    $display("=== END TB ===");
    $finish;
  end

endmodule



//8쌍
/*
`timescale 1ns/1ps

module tb_bfly;

  parameter WIDTH = 12;
  parameter NUM_PAIR = 8;

  logic clk, rstn;
  logic bfly_valid;
  logic signed [WIDTH-1:0] din_re, din_im;
  logic signed [WIDTH-1:0] shift_data_re, shift_data_im;
  logic signed [WIDTH:0] bfly_sum_re, bfly_sum_im;
  logic signed [WIDTH:0] bfly_diff_re, bfly_diff_im;
  logic twiddle_valid;

  // DUT
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
    din_re = 0; din_im = 0;
    shift_data_re = 0; shift_data_im = 0;
    @(posedge clk); rstn = 1;

    // === [1] IDLE 상태용 대기 ===
    bfly_valid = 0;
    for (int i = 0; i < NUM_PAIR; i++) begin
      @(posedge clk);
      din_re        <= $signed(i + 10);
      din_im        <= $signed(i + 100);
      shift_data_re <= $signed(i + 20);
      shift_data_im <= $signed(i + 200);
    end

    // === [2] SUM 연산 ===
    bfly_valid = 1;
    for (int i = 0; i < NUM_PAIR; i++) begin
      @(posedge clk);
      din_re        <= $signed(i + 30);
      din_im        <= $signed(i + 110);
      shift_data_re <= $signed(i + 40);
      shift_data_im <= $signed(i + 210);
    end
    bfly_valid = 0;

    // === [3] IDLE2 대기 ===
    for (int i = 0; i < NUM_PAIR; i++) begin
      @(posedge clk);
      din_re        <= $signed(i + 50);
      din_im        <= $signed(i + 120);
      shift_data_re <= $signed(i + 60);
      shift_data_im <= $signed(i + 220);
    end

    // === [4] DIFF 연산 ===
    bfly_valid = 1;
    for (int i = 0; i < NUM_PAIR; i++) begin
      @(posedge clk);
      din_re        <= $signed(i + 70);
      din_im        <= $signed(i + 130);
      shift_data_re <= $signed(i + 80);
      shift_data_im <= $signed(i + 230);
    end
    bfly_valid = 0;

    // === 마무리 ===
    repeat (5) @(posedge clk);
    $display("=== END TB ===");
    $finish;
  end

endmodule
*/
