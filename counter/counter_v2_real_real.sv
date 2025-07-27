`timescale 1ns / 1ps

module counter_v2 #(
    parameter int COUNT_MAX_VAL = 16, // 전체 카운트 길이
    parameter int DIV_RATIO = 4       // out_pulse의 한 상태 유지 시간
)(
    input  logic clk,
    input  logic rstn,
    input  logic en,             // 1클럭 트리거 또는 지속 신호 모두 가능
    output logic out_pulse       // 0 또는 1을 출력하는 펄스
);

    // 카운트 동작을 제어하는 플래그
    logic counting;
    logic [$clog2(COUNT_MAX_VAL)-1:0] count;

    // 동작 제어 및 카운터 증가
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            count    <= '0;
            counting <= 1'b0;
        end else begin
            if (en && !counting) begin
                counting <= 1'b1;
                count    <= 1;  // 딜레이 없이 다음 클럭부터 count==1
            end else if (counting) begin
                if (count == COUNT_MAX_VAL - 1) begin
                    counting <= 1'b0;  // 완료 후 종료
                    count    <= '0;
                end else begin
                    count <= count + 1;
                end
            end
        end
    end

    // out_pulse 생성 (DIV_RATIO마다 상태 변경)
    assign out_pulse = ((count / DIV_RATIO) % 2 == 1) && counting;

endmodule
