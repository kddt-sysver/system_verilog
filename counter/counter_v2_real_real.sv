`timescale 1ns / 1ps

module counter_v2 #(
    parameter int COUNT_MAX_VAL = 16,
    parameter int DIV_RATIO = 4
) (
    input  logic clk,
    input  logic rstn,
    input  logic en,          // 1클럭 펄스 or 지속적 HIGH 모두 허용
    output logic out_pulse
);

    logic [$clog2(COUNT_MAX_VAL)-1:0] count;
    logic counting;  // 현재 카운트 동작 중인지 상태 플래그

    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            count    <= '0;
            counting <= 1'b0;
        end else begin
            if (en && !counting) begin
                // en이 처음 들어오면 카운트 시작
                counting <= 1'b1;
                count    <= '0;
            end else if (counting) begin
                // 카운팅 동작 중이면 계속 증가
                if (count == COUNT_MAX_VAL - 1) begin
                    counting <= 1'b0; // 카운트 완료 → 상태 종료
                    count    <= '0;
                end else begin
                    count <= count + 1;
                end
            end
        end
    end

    assign out_pulse = ((count / DIV_RATIO) % 2 == 1'b1) ? 1'b1 : 1'b0;

endmodule
