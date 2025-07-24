`timescale 1ns / 1ps

module shift_reg #(
    parameter int DATA_WIDTH = 9,     // 예: <3.6>
    parameter int MEM_DEPTH  = 128    // step0_0=256, step0_1=128, step0_2=64 ...
) (
    input  logic clk,
    input  logic rstn,

    input  logic signed [DATA_WIDTH-1:0] din_re[0:15],
    input  logic signed [DATA_WIDTH-1:0] din_im[0:15],
    input  logic                         valid,

    output logic signed [DATA_WIDTH-1:0] shift_data_re[0:15],
    output logic signed [DATA_WIDTH-1:0] shift_data_im[0:15],
    output logic                         bfly_valid
);

    localparam int TOTAL_INPUTS   = 512;
    localparam int PHASE_LENGTH   = MEM_DEPTH / 16;  // 몇 클럭마다 phase 전환할지

    // 내부 메모리
    logic signed [DATA_WIDTH-1:0] shift_mem_re[0:MEM_DEPTH-1];
    logic signed [DATA_WIDTH-1:0] shift_mem_im[0:MEM_DEPTH-1];

    // 내부 상태
    logic [$clog2(TOTAL_INPUTS+1)-1:0] input_count;
    logic [$clog2(PHASE_LENGTH)-1:0]   phase_count;
    logic                              phase_select;

    // bfly_valid 출력
    assign bfly_valid = (phase_select == 1) && valid;

    // phase_count 및 phase_select FSM
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            input_count  <= 0;
            phase_count  <= 0;
            phase_select <= 0;
        end else if (valid && input_count < TOTAL_INPUTS) begin
            input_count <= input_count + 16;

            if (phase_count == PHASE_LENGTH - 1) begin
                phase_count  <= 0;
                phase_select <= ~phase_select;
            end else begin
                phase_count <= phase_count + 1;
            end
        end
    end

    // 쉬프트 연산
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            for (int i = 0; i < MEM_DEPTH; i++) begin
                shift_mem_re[i] <= '0;
                shift_mem_im[i] <= '0;
            end
        end else if (valid) begin
            for (int i = MEM_DEPTH - 1; i >= 16; i--) begin
                shift_mem_re[i] <= shift_mem_re[i - 16];
                shift_mem_im[i] <= shift_mem_im[i - 16];
            end
            for (int j = 0; j < 16; j++) begin
                shift_mem_re[j] <= din_re[j];
                shift_mem_im[j] <= din_im[j];
            end
        end
    end

    // 출력: shift된 가장 오래된 16개
    generate
        genvar k;
        for (k = 0; k < 16; k++) begin
            assign shift_data_re[k] = shift_mem_re[MEM_DEPTH - 16 + k];
            assign shift_data_im[k] = shift_mem_im[MEM_DEPTH - 16 + k];
        end
    endgenerate

endmodule
