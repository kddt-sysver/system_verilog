`timescale 1ns / 1ps

module counter_v3 #(
    parameter int PULSE_CYCLES = 32
)(
    input  logic clk,
    input  logic rstn,
    input  logic en,                // 트리거 신호 (펄스 or 레벨)

    output logic out_pulse         // en 들어온 즉시 1, PULSE_CYCLES 동안 유지
);

    localparam int CNT_WIDTH = $clog2(PULSE_CYCLES);
    logic [CNT_WIDTH-1:0] cnt;
    logic counting;

    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            cnt      <= 0;
            counting <= 0;
        end else begin
            if (!counting && en) begin
                counting <= 1;
                cnt      <= 1;  // 바로 다음엔 cnt=1부터 시작
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

    assign out_pulse = (en && !counting) ? 1'b1 : counting;

endmodule
