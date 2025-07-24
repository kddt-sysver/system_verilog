`timescale 1ns / 1ps

module shift_reg #(
    parameter int DATA_WIDTH = 9,
    parameter int DEPTH = 256
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

    localparam int FIRST_VALID_COUNT = DEPTH;
    localparam int STEP_VALID_COUNT  = DEPTH / 2;

    // 내부 저장소
    logic signed [DATA_WIDTH-1:0] shift_mem_re[0:DEPTH-1];
    logic signed [DATA_WIDTH-1:0] shift_mem_im[0:DEPTH-1];

    // valid 제어용 카운터
    logic [8:0] cnt;
    logic       first_done;

    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            cnt        <= 0;
            bfly_valid <= 0;
            first_done <= 0;
        end else if (valid) begin
            if (!first_done) begin
                if (cnt + 16 >= FIRST_VALID_COUNT) begin
                    bfly_valid <= 1;
                    cnt <= 0;
                    first_done <= 1;
                end else begin
                    cnt <= cnt + 16;
                    bfly_valid <= 0;
                end
            end else begin
                if (cnt + 16 >= STEP_VALID_COUNT) begin
                    bfly_valid <= 1;
                    cnt <= 0;
                end else begin
                    cnt <= cnt + 16;
                    bfly_valid <= 0;
                end
            end
        end else begin
            bfly_valid <= 0;
        end
    end

    // 쉬프트 동작
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            for (int i = 0; i < DEPTH; i++) begin
                shift_mem_re[i] <= '0;
                shift_mem_im[i] <= '0;
            end
        end else if (valid) begin
            for (int i = DEPTH - 1; i >= 16; i--) begin
                shift_mem_re[i] <= shift_mem_re[i - 16];
                shift_mem_im[i] <= shift_mem_im[i - 16];
            end
            for (int j = 0; j < 16; j++) begin
                shift_mem_re[j] <= din_re[j];
                shift_mem_im[j] <= din_im[j];
            end
        end
    end

    // 항상 마지막 16개를 출력
    generate
        genvar k;
        for (k = 0; k < 16; k++) begin
            assign shift_data_re[k] = shift_mem_re[DEPTH - 16 + k];
            assign shift_data_im[k] = shift_mem_im[DEPTH - 16 + k];
        end
    endgenerate

endmodule
