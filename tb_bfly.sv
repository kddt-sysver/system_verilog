`timescale 1ns/1ps

module tb_bfly;
  parameter WIDTH = 12;
  parameter NUM_PAIR = 256;

  logic clk, rstn;
  logic bfly_valid;
  logic signed [WIDTH-1:0] din_re [0:15];
  logic signed [WIDTH-1:0] din_im [0:15];
  logic signed [WIDTH-1:0] shift_data_re [0:15];
  logic signed [WIDTH-1:0] shift_data_im [0:15];
  logic signed [WIDTH:0] bfly_sum_re [0:15];
  logic signed [WIDTH:0] bfly_sum_im [0:15];
  logic signed [WIDTH:0] bfly_diff_re [0:15];
  logic signed [WIDTH:0] bfly_diff_im [0:15];
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
    for (int i = 0; i < 16; i++) begin
      din_re[i] = 0;
      din_im[i] = 0;
      shift_data_re[i] = 0;
      shift_data_im[i] = 0;
    end

    @(posedge clk);
    rstn = 1;
    @(posedge clk);

    // === [1] 16클럭 동안 shift register에 데이터 입력 ===
    $display("=== Phase 1: Loading data to shift register (16 clocks) ===");
    for (int cyc = 0; cyc < NUM_PAIR / 16; cyc++) begin
      @(posedge clk);
      for (int i = 0; i < 16; i++) begin
        din_re[i]        = $signed(cyc * 16 + i);
        din_im[i]        = $signed(cyc * 16 + i + 100);
        shift_data_re[i] = $signed(cyc * 16 + i + 200);
        shift_data_im[i] = $signed(cyc * 16 + i + 300);
      end
      $display("  Clock %0d: Loading data pair %0d~%0d", cyc+1, cyc*16, cyc*16+15);
    end

    // === [2] 16클럭 동안 butterfly 연산 수행 ===
    $display("=== Phase 2: Butterfly operations (16 clocks) ===");
    bfly_valid = 1;
    
    for (int cyc = 0; cyc < NUM_PAIR / 16; cyc++) begin
      // 매 클럭마다 새로운 16개 데이터 제공 (shift register에서 나온 데이터)
      for (int i = 0; i < 16; i++) begin
        din_re[i]        = $signed(cyc * 16 + i);
        din_im[i]        = $signed(cyc * 16 + i + 100);
        shift_data_re[i] = $signed(cyc * 16 + i + 200);
        shift_data_im[i] = $signed(cyc * 16 + i + 300);
      end
      
      @(posedge clk);
      
      // 매 클럭마다 16개 butterfly 연산 결과 출력
      $display("=== Butterfly Cycle %0d Results ===", cyc+1);
      for (int i = 0; i < 16; i++) begin
        $display("  [%0d] SUM_RE=%0d, SUM_IM=%0d, DIFF_RE=%0d, DIFF_IM=%0d", 
                 cyc*16+i, bfly_sum_re[i], bfly_sum_im[i], 
                 bfly_diff_re[i], bfly_diff_im[i]);
      end
    end
    
    bfly_valid = 0;
    
    // === [3] 결과 확인 ===
    @(posedge clk);
    $display("=== Final Status ===");
    $display("twiddle_valid = %0b", twiddle_valid);
    
    if (twiddle_valid) begin
      $display("SUCCESS: All 256 butterfly pairs processed!");
    end else begin
      $display("ERROR: twiddle_valid should be high!");
    end

    repeat(2) @(posedge clk);
    $display("=== END TB ===");
    $finish;
  end

endmodule
