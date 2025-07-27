// module_00_tb.sv
`timescale 1ns / 1ps

// FFT/IFFT 테스트에 필요한 상수 정의 (선택 사항, 필요에 따라 조정)
`define N_FFT 256 // FFT 포인트 수 (이 값은 현재 512개 데이터 주입 로직에 직접 사용되지 않음)

// 파일에서 데이터를 읽기 위한 배열 (넉넉하게 256개 또는 그 이상으로 설정)
localparam DATA_DEPTH = 256; // 파일에서 읽을 최대 데이터 개수 (실제 512개 읽을 예정)

module module_00_tb();

    // DUT 파라미터와 동일하게 설정
    localparam WIDTH = 9;

    // 클럭 및 리셋 신호
    logic clk;
    logic rstn;

    // module_00 입력 신호
    logic signed [WIDTH-1:0] in_i [0:15]; // module_00의 in_i
    logic signed [WIDTH-1:0] in_q [0:15]; // module_00의 in_q
    logic din_valid; // module_00의 din_valid

    // module_00 출력 신호 (DUT의 출력)
    logic signed [WIDTH:0] twd_00_sum_re [0:15];
    logic signed [WIDTH:0] twd_00_sum_im [0:15];
    logic signed [WIDTH:0] twd_00_diff_re[0:15];
    logic signed [WIDTH:0] twd_00_diff_im[0:15];
    logic shift_01_valid;

    // 파일에서 읽어올 데이터를 저장할 배열
    // cos_i_dat.txt와 cos_q_dat.txt 파일은 16개씩 묶인 데이터가 아니라
    // 연속적인 단일 데이터들이 줄바꿈으로 되어 있다고 가정합니다.
    integer file_i_fd, file_q_fd;
    integer scan_count_i, scan_count_q;
    integer cycle_count; // 클럭 사이클 카운트

    // 00결과 텍스트파일 (매트랩 결과) 검증용 (필요시 활성화)
    // parameter string EXPECTED_RESULT_FILE = "00_expected_results.txt";
    // integer expected_fd;
    // logic signed [WIDTH:0] expected_sum_re [0:15];
    // logic signed [WIDTH:0] expected_sum_im [0:15];
    // logic signed [WIDTH:0] expected_diff_re[0:15];
    // logic signed [WIDTH:0] expected_diff_im[0:15];

    // DUT 인스턴스화
    module_00 #(
        .WIDTH(WIDTH)
    ) U_MODULE_00 (
        .clk (clk),
        .rstn (rstn),
        .in_i (in_i),
        .in_q (in_q),
        .din_valid (din_valid),
        .twd_00_sum_re (twd_00_sum_re),
        .twd_00_sum_im (twd_00_sum_im),
        .twd_00_diff_re (twd_00_diff_re),
        .twd_00_diff_im (twd_00_diff_im),
        .shift_01_valid (shift_01_valid)
    );

    // 클럭 생성 (100MHz 클럭, 주기 10ns)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        // 파형 덤프 설정 (Verdi에서 확인 가능)
        $dumpfile("module_00_tb.vcd"); // VCD 파일 생성
        $dumpvars(0, module_00_tb);    // 현재 모듈 (테스트벤치) 내 모든 신호 덤프

        // 초기화
        rstn = 0; // 리셋 활성화
        din_valid = 0;
        for (int k = 0; k < 16; k++) begin
            in_i[k] = '0;
            in_q[k] = '0;
        end

        $display("--------------------------------------------------");
        $display("module_00 테스트벤치 시작");
        $display("--------------------------------------------------");

        // 파일 열기
        file_i_fd = $fopen("cos_i_dat.txt", "r");
        file_q_fd = $fopen("cos_q_dat.txt", "r");

        if (file_i_fd == 0 || file_q_fd == 0) begin
            $display("ERROR: Could not open input data files (cos_i_dat.txt or cos_q_dat.txt). Please ensure they are in the simulation directory.");
            $stop;
        end
        
        // 매트랩 결과 파일 열기 (선택 사항)
        // expected_fd = $fopen(EXPECTED_RESULT_FILE, "r");
        // if (expected_fd == 0) begin
        //     $display("WARNING: Could not open expected results file %s. Verification will be skipped.", EXPECTED_RESULT_FILE);
        // end

        #10 rstn = 1; // 리셋 해제
        $display("리셋 해제.");

        cycle_count = 0;
        
        $display("INFO: Starting data input phase. din_valid will be high for 32 cycles.");
        din_valid = 1; // din_valid 신호를 32클럭 동안 1로 유지

        // 32클럭 동안 데이터를 주입하는 루프
        for (int current_input_cycle = 0; current_input_cycle < 32; current_input_cycle++) begin
            // 매 클럭마다 16개의 데이터 쌍을 파일에서 읽어 in_i와 in_q 배열에 채웁니다.
            for (int k = 0; k < 16; k++) begin
                scan_count_i = $fscanf(file_i_fd, "%d", in_i[k]);
                scan_count_q = $fscanf(file_q_fd, "%d", in_q[k]);
                
                if (scan_count_i == 0 || scan_count_q == 0) begin
                    $display("INFO: Reached end of input data files prematurely at input cycle %0d (data_idx %0d).", current_input_cycle, k);
                    // 파일이 중간에 끝나면 din_valid를 바로 내리고 루프 종료
                    din_valid = 0;
                    current_input_cycle = 32; // 루프 강제 종료
                    break;
                end
            end

            #10; // 1 클럭 주기 대기 (클럭 엣지에서 DUT가 입력값을 샘플링하도록)
            
            cycle_count++;
            $display("Time: %0t, Current Input Cycle: %0d, Total Cycles: %0d, Data block applied.", $time, current_input_cycle, cycle_count);

            // 매트랩 결과 검증 (선택 사항)
            // if (expected_fd != 0 && shift_01_valid) begin // shift_01_valid가 HIGH일 때 출력 검증
            //     $display("INFO: Checking results for cycle %0d", cycle_count);
            //     for (int k = 0; k < 16; k++) begin
            //         // 예상 결과 파일을 읽는 로직 추가
            //         // $fscanf(expected_fd, "%d %d %d %d", expected_sum_re[k], expected_sum_im[k], expected_diff_re[k], expected_diff_im[k]);
            //         // if (twd_00_sum_re[k] !== expected_sum_re[k]) $error("Mismatch at sum_re[%0d]! Expected: %0d, Got: %0d", k, expected_sum_re[k], twd_00_sum_re[k]);
            //         // ... 다른 출력들도 비교 ...
            //     end
            // end
        end

        din_valid = 0; // 32클럭 데이터 주입 완료 후 din_valid 비활성화

        #100; // 모든 파이프라인 데이터가 처리될 수 있도록 충분히 대기

        $fclose(file_i_fd);
        $fclose(file_q_fd);
        // if (expected_fd != 0) $fclose(expected_fd);

        $display("--------------------------------------------------");
        $display("module_00 테스트벤치 종료.");
        $display("--------------------------------------------------");
        $finish; // 시뮬레이션 종료
    end

    // 모니터링 (선택 사항)
    // always @(posedge clk) begin
    //     if (shift_01_valid) begin
    //         $display("Time: %0t, Output Valid!", $time);
    //         for (int k = 0; k < 4; k++) begin // 일부만 출력
    //             $display("  twd_00_sum_re[%0d]=%0d, twd_00_sum_im[%0d]=%0d", k, twd_00_sum_re[k], k, twd_00_sum_im[k]);
    //             $display("  twd_00_diff_re[%0d]=%0d, twd_00_diff_im[%0d]=%0d", k, twd_00_diff_im[k], k, twd_00_diff_re[k]); // Diff_re와 Diff_im 순서 확인
    //         end
    //     end
    // end

endmodule