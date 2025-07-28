`timescale 1ns/1ps
`default_nettype none

module tb_cbfp_module;

  //==============================================================
  // Parameters
  //==============================================================
  parameter int IN_W         = 16;            // cbfp_module 입력 비트폭 (pre_bfly00.txt에 맞춰 16비트 유지)
  parameter int OUT_W        = 11;            // cbfp_module 출력 비트폭 (<5.6>)
  parameter int NUM_CHANNELS = 16;            // cbfp_module의 NCHAN과 일치
  parameter int NUM_SAMPLES  = 512;           // 전체 샘플 수 (cbfp_0.txt 또는 pre_bfly00.txt의 총 라인 수)
  localparam int MEM_DEPTH   = 64;            // cbfp_module 내부 shift_reg의 MEM_DEPTH

  //==============================================================
  // DUT I/O (cbfp_module의 인터페이스와 일치)
  //==============================================================
  logic                     clk, rstn;
  logic                     valid_in;
  logic signed [IN_W-1:0]   data_re_in  [0:NUM_CHANNELS-1];
  logic signed [IN_W-1:0]   data_im_in  [0:NUM_CHANNELS-1];
  logic signed [OUT_W-1:0]  data_re_out [0:NUM_CHANNELS-1];
  logic signed [OUT_W-1:0]  data_im_out [0:NUM_CHANNELS-1];
  logic                     valid_out;

  //==============================================================
  // Clock Generation
  //==============================================================
  initial clk = 0;
  always #5 clk = ~clk; // 10ns 주기 클럭 (100MHz)

  //==============================================================
  // File Buffers
  //==============================================================
  integer input_file_pre_bfly00, input_file_cbfp0, output_file, scan_result;
  logic signed [IN_W-1:0] full_re_in [0:NUM_SAMPLES-1]; // pre_bfly00.txt의 실수부 저장 버퍼 (16비트)
  logic signed [IN_W-1:0] full_im_in [0:NUM_SAMPLES-1]; // pre_bfly00.txt의 허수부 저장 버퍼 (16비트)
  logic signed [OUT_W-1:0] expected_re [0:NUM_SAMPLES-1]; // cbfp_0.txt의 bfly02 실수부 저장 버퍼 (11비트)
  logic signed [OUT_W-1:0] expected_im [0:NUM_SAMPLES-1]; // cbfp_0.txt의 bfly02 허수부 저장 버퍼 (11비트)

  // cbfp_0.txt 파일 파싱을 위한 더미 변수들 (bfly02 값만 추출)
  int dummy_twf_idx, dummy_twf_re, dummy_twf_im;
  int dummy_pre_bfly_idx, dummy_pre_bfly_re, dummy_pre_bfly_im; // pre_bfly02는 더미로 읽음
  int dummy_index1_re_idx, dummy_index1_re_val;
  int dummy_index1_im_idx, dummy_index1_im_val;
  int dummy_bfly_idx;

  //==============================================================
  // DUT Instantiation (cbfp_module)
  //==============================================================
  cbfp_module #(
    .IN_W      (IN_W),
    .OUT_W     (OUT_W)
    // REF_SUM과 FINAL_REF는 cbfp_module 내부의 기본값을 사용합니다.
  ) dut (
    .clk         (clk),
    .rstn        (rstn),
    .valid_in    (valid_in),
    .data_re_in  (data_re_in),
    .data_im_in  (data_im_in),
    .data_re_out (data_re_out),
    .data_im_out (data_im_out),
    .valid_out   (valid_out)
  );

  //==============================================================
  // Stimulus & File I/O
  //==============================================================
  initial begin
    $display("[TB] Starting cbfp_module standalone simulation");
    
    // Reset Sequence
    rstn       = 0;
    valid_in = 0;
    #20 rstn = 1; // 20ns 리셋 후 해제

    // 1. Input file "pre_bfly00.txt" 읽기 (cbfp_module의 실제 입력)
    input_file_pre_bfly00 = $fopen("pre_bfly00.txt", "r");
    if (input_file_pre_bfly00 == 0) $fatal("[TB] Failed to open input file 'pre_bfly00.txt'. Please ensure it exists and contains signed decimal values (e.g., '12345+j-6789').");
    
    for (int i = 0; i < NUM_SAMPLES; i++) begin
      scan_result = $fscanf(input_file_pre_bfly00, "%d+j%d\n", full_re_in[i], full_im_in[i]);
      if (scan_result != 2) begin
        $error("[TB] Error reading pre_bfly00.txt at line %0d. Expected 'real+jimag' format.", i+1);
        $finish;
      end
    end
    $fclose(input_file_pre_bfly00);
    $display("[TB] Successfully loaded input data from pre_bfly00.txt.");

    // 2. Expected output file "cbfp_0.txt" 읽기 (bfly02 값만 추출)
    input_file_cbfp0 = $fopen("cbfp_0.txt", "r");
    if (input_file_cbfp0 == 0) $fatal("[TB] Failed to open input file 'cbfp_0.txt'. Please ensure it exists and contains data in the specified format.");
    
    for (int i = 0; i < NUM_SAMPLES; i++) begin
      scan_result = $fscanf(input_file_cbfp0, "twf_m0(%d)=%d+j%d, pre_bfly02(%d)=%d+j%d, index1_re(%d)=%d, index1_im(%d)=%d, bfly02(%d)=%d+j%d\n",
          dummy_twf_idx, dummy_twf_re, dummy_twf_im,
          dummy_pre_bfly_idx, dummy_pre_bfly_re, dummy_pre_bfly_im, // pre_bfly02는 더미로 읽음
          dummy_index1_re_idx, dummy_index1_re_val,
          dummy_index1_im_idx, dummy_index1_im_val,
          dummy_bfly_idx, expected_re[i], expected_im[i] // bfly02 값을 예상 출력 버퍼에 저장
      );
      if (scan_result != 13) begin // 총 13개의 필드를 읽어야 함
        $error("[TB] Error reading cbfp_0.txt at line %0d. Expected 'twf_m0(...), pre_bfly02(...), index1_re(...), index1_im(...), bfly02(...)' format.", i+1);
        $finish;
      end
    end
    $fclose(input_file_cbfp0);
    $display("[TB] Successfully loaded expected output (bfly02) from cbfp_0.txt.");

    // Output 파일 열기 (실제 시뮬레이션 결과 저장용)
    output_file = $fopen("cbfp_standalone_out.txt", "w");
    if (output_file == 0) $fatal("[TB] Failed to open output file 'cbfp_standalone_out.txt'");
    $display("[TB] Simulation output will be written to cbfp_standalone_out.txt");

    // 16개 채널씩 블록 단위로 입력 데이터 인가
    for (int sample_idx = 0; sample_idx < NUM_SAMPLES; sample_idx += NUM_CHANNELS) begin
      for (int ch = 0; ch < NUM_CHANNELS; ch++) begin
        if ((sample_idx + ch) < NUM_SAMPLES) begin
          data_re_in[ch] = full_re_in[sample_idx + ch]; // pre_bfly00.txt에서 읽은 데이터 사용
          data_im_in[ch] = full_im_in[sample_idx + ch]; // pre_bfly00.txt에서 읽은 데이터 사용
        end else begin
          // 남은 채널은 0으로 채우거나 유효하지 않게 처리 (필요시)
          data_re_in[ch] = '0;
          data_im_in[ch] = '0;
        end
      end
      valid_in = 1; // 데이터 유효 신호 인가
      @(posedge clk); // 클럭 엣지 대기
    end
    valid_in = 0; // 모든 데이터 인가 후 valid_in 비활성화

    // cbfp_module의 파이프라인 딜레이를 고려하여 충분히 대기
    // (shift_reg의 MEM_DEPTH + 모듈 내부 조합 로직 딜레이)
    repeat (MEM_DEPTH + 5) @(posedge clk); // 충분한 클럭 사이클 대기

    // 파일 닫고 시뮬레이션 종료
    $fclose(output_file);
    $display("[TB] Simulation completed. Check cbfp_standalone_out.txt for results and compare with bfly02 values from cbfp_0.txt.");
    $finish;
  end

  //==============================================================
  // Output Monitor (Valid 출력 시 파일에 데이터 쓰기 및 비교)
  //==============================================================
  int output_sample_count; // Declare without initialization here

  always_ff @(posedge clk or negedge rstn) begin // Add rstn to sensitivity list
    if (!rstn) begin
      output_sample_count <= 0; // Initialize on reset
    end else if (valid_out) begin
      for (int k = 0; k < NUM_CHANNELS; k++) begin
        $fwrite(output_file, "%0d %0d\n",
                data_re_out[k], data_im_out[k]);
        
        // 예상 출력과 실제 출력 비교
        if (output_sample_count < NUM_SAMPLES) begin
          if (data_re_out[k] !== expected_re[output_sample_count] ||
              data_im_out[k] !== expected_im[output_sample_count]) begin
            $error("[TB] Mismatch at sample %0d, channel %0d: Expected %d+j%d, Got %d+j%d",
                   output_sample_count, k,
                   expected_re[output_sample_count], expected_im[output_sample_count],
                   data_re_out[k], data_im_out[k]);
          end
        end
        output_sample_count++;
      end
    end
  end

endmodule

`default_nettype wire
