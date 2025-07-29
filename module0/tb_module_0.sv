`timescale 1ns / 1ps

module tb_module_0;

    localparam WIDTH = 9;
    localparam DATA_DEPTH = 512;

    logic clk;
    logic rstn;
    logic din_valid;

    logic signed [WIDTH-1:0] in_i [0:15];
    logic signed [WIDTH-1:0] in_q [0:15];

    logic signed [WIDTH+1:0] module_00_out_re [0:15];
    logic signed [WIDTH+1:0] module_00_out_im [0:15];
    logic module1_valid;

    logic signed [WIDTH-1:0] in_i_mem[0:DATA_DEPTH-1];
    logic signed [WIDTH-1:0] in_q_mem[0:DATA_DEPTH-1];

    integer file_i_fd, file_q_fd;
    integer scan_count_i, scan_count_q;
    integer cycle_count;

    // DUT 인스턴스
    module_0 #(
        .WIDTH(WIDTH)
    ) dut (
        .clk(clk),
        .rstn(rstn),
        .in_i(in_i),
        .in_q(in_q),
        .din_valid(din_valid),
        .module_00_out_re(module_00_out_re),
        .module_00_out_im(module_00_out_im),
        .module1_valid(module1_valid)
    );

    // Clock generation
    always #5 clk = ~clk;

    // 테스트 시나리오
    initial begin
        $dumpfile("tb_module_0.vcd");
        $dumpvars(0, tb_module_0);  // ✅ 이름 통일

        // 초기화
        clk = 0;
        rstn = 0;
        din_valid = 0;
        for (int k = 0; k < 16; k++) begin
            in_i[k] = 0;
            in_q[k] = 0;
        end

        $display("--------------------------------------------------");
        $display("tb_module_0 테스트벤치 시작");
        $display("--------------------------------------------------");

        file_i_fd = $fopen("cos_i_dat.txt", "r");
        file_q_fd = $fopen("cos_q_dat.txt", "r");
        if (file_i_fd == 0 || file_q_fd == 0) begin
            $display("ERROR: 입력 파일 열기 실패.");
            $stop;
        end

        #20; rstn = 1; #10;
        $display("리셋 해제. 32클럭 동안 입력 시작");

        cycle_count = 0;
        din_valid = 1;

        input_loop: for (int i = 0; i < 32; i++) begin
            for (int j = 0; j < 16; j++) begin
                scan_count_i = $fscanf(file_i_fd, "%d", in_i[j]);
                scan_count_q = $fscanf(file_q_fd, "%d", in_q[j]);
                if (scan_count_i == 0 || scan_count_q == 0) begin
                    $display("파일 끝 도달 (i=%0d, j=%0d)", i, j);
                    din_valid = 0;
                    disable input_loop;  // ✅ named block 사용
                end
            end

            @(posedge clk);
            #2.5;  // din_valid는 클럭 중간부터 유지
            cycle_count++;
        end

        din_valid = 0;
        @(posedge clk);
        #1000;

        $fclose(file_i_fd);
        $fclose(file_q_fd);

        $display("--------------------------------------------------");
        $display("tb_module_0 테스트 종료");
        $display("--------------------------------------------------");

        $finish;
    end

    // 출력 모니터링
    always @(posedge clk) begin
        if (module1_valid) begin
            $display("[OUT] time=%0t module1_valid=1", $time);
            for (int k = 0; k < 4; k++) begin
                $display("  sum_re[%0d]=%0d, sum_im[%0d]=%0d", k, module_00_out_re[k], k, module_00_out_im[k]);
            end
        end
    end

endmodule
