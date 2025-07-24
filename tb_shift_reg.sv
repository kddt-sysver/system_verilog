`timescale 1ns / 1ps

module tb_shift_reg;

    parameter int WIDTH      = 9;
    parameter int MEM_DEPTH  = 256;

    logic clk, rstn, valid;
    logic signed [WIDTH-1:0] din_re[0:15];
    logic signed [WIDTH-1:0] din_im[0:15];

    logic signed [WIDTH-1:0] shift_data_re[0:15];
    logic signed [WIDTH-1:0] shift_data_im[0:15];
    logic                    bfly_valid;

    // DUT
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
        .shift_data_im(shift_data_im),
        .bfly_valid(bfly_valid)
    );

    // Clock generation: 10ns period (100MHz)
    always #5 clk = ~clk;

    initial begin
        clk   = 0;
        rstn  = 0;
        valid = 0;

        // === Reset 20ns ===
        #20;
        rstn = 1;

        // === rst 해제 후 3클럭 기다림 ===
        repeat (3) @(posedge clk);

        // === valid 32클럭 ON ===
        valid = 1;
        for (int k = 0; k < 32; k++) begin
            for (int i = 0; i < 16; i++) begin
                din_re[i] = (k * 16 + i) % 64;  // <3.6> 범위 (0~63)
                din_im[i] = 0;
            end
            @(posedge clk);
        end
        valid = 0;

        // === 출력 확인 대기 ===
        repeat (100) @(posedge clk);
        $finish;
    end

endmodule
