`timescale 1ns / 1ps

module shift_reg #(
    parameter int WIDTH = 9,
    parameter int MEM_DEPTH = 256  // 예: 256, 128, 64 등 단계에 따라 설정
)(
    input  logic clk,
    input  logic rstn,

    input  logic signed [WIDTH-1:0] din_re[0:15],
    input  logic signed [WIDTH-1:0] din_im[0:15],
    input  logic                    valid,

    output logic signed [WIDTH-1:0] shift_data_re[0:15],
    output logic signed [WIDTH-1:0] shift_data_im[0:15]
);

    // 내부 shift 메모리
    logic signed [WIDTH-1:0] shift_mem_re[0:MEM_DEPTH-1];
    logic signed [WIDTH-1:0] shift_mem_im[0:MEM_DEPTH-1];

    // shift 동작: valid가 1일 때만 실행
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            for (int i = 0; i < MEM_DEPTH; i++) begin
                shift_mem_re[i] <= '0;
                shift_mem_im[i] <= '0;
            end
        end else if (valid) begin
            for (int i = MEM_DEPTH-1; i >= 16; i--) begin
                shift_mem_re[i] <= shift_mem_re[i-16];
                shift_mem_im[i] <= shift_mem_im[i-16];
            end
            for (int j = 0; j < 16; j++) begin
                shift_mem_re[j] <= din_re[j];
                shift_mem_im[j] <= din_im[j];
            end
        end
    end

    generate
        genvar k;
        for (k = 0; k < 16; k++) begin
            assign shift_data_re[k] = shift_mem_re[MEM_DEPTH - 16 + k];
            assign shift_data_im[k] = shift_mem_im[MEM_DEPTH - 16 + k];
        end
    endgenerate

endmodule

