`timescale 1ns / 1ps

module shift_reg #(
    parameter int WIDTH = 9,         // 예: <3.6>
    parameter int MEM_DEPTH  = 128   // step0_0=256, step0_1=128, step0_2=64 ...
) (
    input logic clk,
    input logic rstn,

    input logic signed [WIDTH-1:0] din_re[0:15],
    input logic signed [WIDTH-1:0] din_im[0:15],
    input logic                    valid,

    output logic signed [WIDTH-1:0] shift_data_re[0:15],
    output logic signed [WIDTH-1:0] shift_data_im[0:15],
    output logic                    bfly_valid
);

    localparam int TOTAL_IMPUTS = 512;
    localparam int PHASE_LENGTH = MEM_DEPTH / 16;

    // 내부 메모리
    logic signed [WIDTH-1:0] shift_mem_re[0:MEM_DEPTH-1];
    logic signed [WIDTH-1:0] shift_mem_im[0:MEM_DEPTH-1];

    // 출력용 레지스터 (1클럭 딜레이)
    logic signed [WIDTH-1:0] shift_data_re_reg[0:15];
    logic signed [WIDTH-1:0] shift_data_im_reg[0:15];

    // bfly_valid 생성용 카운터
    logic [$clog2(PHASE_LENGTH)+1-1:0] phase_count;

    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            phase_count <= 0;
            bfly_valid  <= 0;
        end else if (valid) begin
            if (phase_count == 0) begin
                phase_count <= 1;
            end else if (phase_count == PHASE_LENGTH) begin
                phase_count <= 1;
                bfly_valid  <= ~bfly_valid;
            end else begin
                phase_count <= phase_count + 1;
            end
        end else begin
            // valid 떨어지면 자동으로 bfly_valid 비활성화 + 카운터 초기화
            phase_count <= 0;
            bfly_valid  <= 0;
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
                shift_mem_re[i] <= shift_mem_re[i-16];
                shift_mem_im[i] <= shift_mem_im[i-16];
            end
            for (int j = 0; j < 16; j++) begin
                shift_mem_re[j] <= din_re[j];
                shift_mem_im[j] <= din_im[j];
            end
        end
    end

    // 출력 지연 (레지스터에 저장 후 다음 클럭에 출력)
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            for (int i = 0; i < 16; i++) begin
                shift_data_re_reg[i] <= '0;
                shift_data_im_reg[i] <= '0;
            end
        end else begin
            for (int i = 0; i < 16; i++) begin
                shift_data_re_reg[i] <= shift_mem_re[MEM_DEPTH-16+i];
                shift_data_im_reg[i] <= shift_mem_im[MEM_DEPTH-16+i];
            end
        end
    end

    // assign 출력 연결
    generate
        genvar k;
        for (k = 0; k < 16; k++) begin
            assign shift_data_re[k] = shift_data_re_reg[k];
            assign shift_data_im[k] = shift_data_im_reg[k];
        end
    endgenerate

endmodule
