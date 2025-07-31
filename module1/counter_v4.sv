`timescale 1ns / 1ps

module counter_v4 #(
    parameter int PULSE_CYCLES = 32  // 유지할 펄스 길이
)(
    input  logic clk,
    input  logic rstn,
    input  logic en,                // 트리거 신호

    output logic out_pulse          // PULSE_CYCLES 동안 1 유지
);

    // 필요한 비트 수 계산 (예: 32면 5비트)
    localparam int CNT_WIDTH = $clog2(PULSE_CYCLES);
    logic [CNT_WIDTH-1:0] cnt;
    logic counting;

    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            cnt      <= 0;
            counting <= 0;
        end else begin
            if (en && !counting) begin
                counting <= 1;
                cnt      <= 0;
            end else if (counting) begin
                if (cnt == PULSE_CYCLES - 1) begin
                    counting <= 0;
                    cnt      <= 0;
                end else begin
                    cnt <= cnt + 1;
                end
            end
        end
    end

    assign out_pulse = en || counting;

endmodule
