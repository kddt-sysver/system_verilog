`timescale 1ns / 1ps

module tb_shift_reg;

    parameter WIDTH = 9;
    parameter MEM_DEPTH = 256;

    logic clk;
    logic rstn;
    logic valid;

    logic signed [WIDTH-1:0] din_re[0:15];
    logic signed [WIDTH-1:0] din_im[0:15];

    logic signed [WIDTH-1:0] shift_data_re[0:15];
    logic signed [WIDTH-1:0] shift_data_im[0:15];

    // DUT instantiation
    shift_reg #(
        .WIDTH(WIDTH),
        .MEM_DEPTH(MEM_DEPTH)
    ) dut (
        .clk(clk),
        .rstn(rstn),
        .din_re(din_re),
        .din_im(din_im),
        .valid(valid),
        .shift_data_re(shift_data_re),
        .shift_data_im(shift_data_im)
    );

    // Clock generation
    always #5 clk = ~clk;

    // Test stimulus
    initial begin
        integer i, j;
        clk = 0;
        rstn = 0;
        valid = 0;

        for (j = 0; j < 16; j++) begin
            din_re[j] = 0;
            din_im[j] = 0;
        end

        #12;
        rstn = 1;

        // 32번 반복 (총 512개 입력 = 16개 x 32클럭)
        for (i = 0; i < 32; i++) begin
            @(posedge clk);
            valid = 1;
            for (j = 0; j < 16; j++) begin
                din_re[j] = i*16 + j;              // 예: 0, 1, 2, ..., 511
                din_im[j] = -(i*16 + j);           // 예: 0, -1, -2, ..., -511
            end
        end

        // 입력 멈춤
        @(posedge clk);
        valid = 0;

        // 이후 1~2클럭 동안 출력 유지 확인
        repeat (5) @(posedge clk);

        $finish;
    end

endmodule
