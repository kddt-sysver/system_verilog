`timescale 1ns / 1ps

module shift_reg #(
    parameter int DATA_WIDTH = 9,     // 입력 데이터 포맷 예: <3.6>
    parameter int MEM_DEPTH  = 128    // 저장소 깊이: 256, 128, 64 등
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

    localparam int TOTAL_INPUTS = 512;

    // 내부 메모리
    logic signed [DATA_WIDTH-1:0] shift_mem_re[0:MEM_DEPTH-1];
    logic signed [DATA_WIDTH-1:0] shift_mem_im[0:MEM_DEPTH-1];

    // 입력 개수 카운트
    logic [$clog2(TOTAL_INPUTS + 1) - 1:0] input_count;

    // 저장/출력 phase 제어 (0: 저장만, 1: 출력+저장)
    logic phase_select;

    // 카운터 인스턴스
    counter #(
        .WIDTH($clog2(MEM_DEPTH + 1))
    ) u_counter (
        .clk(clk),
        .rstn(rstn),
        .en(valid),
        .count_out(count)
    );

    // phase_select 제어: MEM_DEPTH 클럭마다 toggle
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            input_count  <= 0;
            phase_select <= 1;
        end else if (valid && input_count < TOTAL_INPUTS) begin
            input_count <= input_count + 16;
            if (!(count % (MEM_DEPTH / 16)))
                phase_select <= ~phase_select;
        end
    end

    // butterfly valid: 출력 phase + valid 시점
    assign bfly_valid = (phase_select == 1) && valid;

    // 쉬프트 레지스터 동작
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

    // 출력: 가장 오래된 16개를 고정된 위치에서 뽑아줌
    generate
        genvar k;
        for (k = 0; k < 16; k++) begin
            assign shift_data_re[k] = shift_mem_re[MEM_DEPTH - 16 + k];
            assign shift_data_im[k] = shift_mem_im[MEM_DEPTH - 16 + k];
        end
    endgenerate

endmodule
