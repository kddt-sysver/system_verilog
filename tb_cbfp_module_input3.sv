// tb_module0.sv
`timescale 1ns/1ps
`default_nettype none

module tb_module0;
  // 파라미터 (stage0 MATLAB과 동일하게)
  localparam int IN_W      = 16;
  localparam int OUT_W     = 13;
  localparam int SHIFT_W   = 5;
  localparam int REF_SUM   = 23;
  localparam int FINAL_REF = 9;
  localparam int LANES     = 16;
  localparam int TOTAL_SAM = 512;
  localparam int CYCLES    = TOTAL_SAM / LANES; // 32

  // clock/reset
  logic clk, rst_n;

  // DUT 스트리밍 입력
  logic                    valid_in;
  logic signed [IN_W-1:0]  data_re_in   [0:LANES-1];
  logic signed [IN_W-1:0]  data_im_in   [0:LANES-1];
  logic        [SHIFT_W-1:0] index1_re_in[0:LANES-1];
  logic        [SHIFT_W-1:0] index1_im_in[0:LANES-1];
  // stage0에선 index2는 0으로 고정
  logic        [SHIFT_W-1:0] index2_re_in[0:LANES-1] = '{default:0};
  logic        [SHIFT_W-1:0] index2_im_in[0:LANES-1] = '{default:0};

  // DUT 출력
  logic signed [OUT_W-1:0] data_re_out [0:LANES-1];
  logic signed [OUT_W-1:0] data_im_out [0:LANES-1];
  logic                   valid_out;

  // 블록 카운터 및 파일 I/O용 변수
  integer blk;
  integer fp, ret;
  integer real_v, imag_v, idx1_re, idx1_im;

  // DUT 인스턴스
  cbfp_module #(
    .IN_W     (IN_W),
    .OUT_W    (OUT_W),
    .SHIFT_W  (SHIFT_W),
    .REF_SUM  (REF_SUM),
    .FINAL_REF(FINAL_REF)
  ) dut (
    .clk            (clk),
    .rst_n          (rst_n),
    .valid_in       (valid_in),
    .data_re_in     (data_re_in),
    .data_im_in     (data_im_in),
    .index1_re_in   (index1_re_in),
    .index1_im_in   (index1_im_in),
    .index2_re_in   (index2_re_in),
    .index2_im_in   (index2_im_in),
    .data_re_out    (data_re_out),
    .data_im_out    (data_im_out),
    .valid_out      (valid_out)
  );

  // clock 생성
  initial clk = 0;
  always #5 clk = ~clk;

  // 입력 파형 읽기/스트리밍
  initial begin
    rst_n    = 0;
    valid_in = 0;
    #20;
    rst_n    = 1;
    #10;

    // cbfp_0.txt 열기
    fp = $fopen("cbfp_0.txt","r");
    if (fp == 0) $fatal("Cannot open cbfp_0.txt");

    // 512샘플을 32싸이클에 걸쳐 스트림
    for (int cycle = 0; cycle < CYCLES; cycle++) begin
      @(posedge clk);
      valid_in = 1;
      for (int lane = 0; lane < LANES; lane++) begin
        ret = $fscanf(fp,
          "twf_m0(%*d)=%*d+j%*d, pre_bfly02(%*d)=%d+j%d, index1_re(%*d)=%d, index1_im(%*d)=%d, bfly02(%*d)=%*d+j%*d\n",
          real_v, imag_v,
          idx1_re, idx1_im
        );
        if (ret != 4) $fatal("fscanf failed at cycle %0d lane %0d, ret=%0d", cycle, lane, ret);

        data_re_in[lane]   = real_v;
        data_im_in[lane]   = imag_v;
        index1_re_in[lane] = idx1_re;
        index1_im_in[lane] = idx1_im;
      end
    end
    $fclose(fp);

    // 마지막 블록까지 flush
    repeat(4) @(posedge clk);
    valid_in = 0;
  end

  // blk 카운터: reset 시 0, valid_out 시에만 증가
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)        blk <= 0;
    else if (valid_out) blk <= blk + 1;
  end

  // 모니터 & 비교 (출력만)
  always @(posedge clk) begin
    if (valid_out) begin
      $display("=== BLOCK %0d @%0t ===", blk, $time);
      for (int i = 0; i < LANES; i++) begin
        $write(" out[%0d]=%0d+j%0d", i, data_re_out[i], data_im_out[i]);
      end
      $display("");
    end
  end

endmodule

`default_nettype wire
