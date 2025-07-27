`timescale 1ns / 1ps

module counter_v2 #(
    // 새로운 파라미터 정의
    parameter int COUNT_MAX_VAL = 16, // 카운터가 0으로 래핑되기까지의 총 클럭 수 (예: 16클럭)
    parameter int DIV_RATIO = 4 // out_pulse가 0 또는 1로 유지되는 각 세그먼트의 클럭 수 (예: 4클럭)
) (
    input logic clk,
    input logic rstn,
    input  logic en,             // 카운트 인에이블 (en이 1일 때만 카운터 증가)
    output logic out_pulse  // 0 또는 1을 출력하는 펄스 신호
);

    // 내부 카운터 레지스터 선언
    // 카운터는 0부터 (TOTAL_CLOCKS - 1)까지 셉니다.
    // $clog2(X)는 X를 표현하는 데 필요한 최소 비트 수를 반환
    logic [$clog2(COUNT_MAX_VAL)-1:0] count;

    // 순차 논리: 클럭 에지 또는 리셋 신호에 반응하여 카운터 값 업데이트
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin  // 비동기 리셋 (rstn이 0일 때)
            count <= '0;  // 카운터를 0으로 초기화
        end else if (en) begin  // en이 1일 때만 카운터 증가
            if (count == COUNT_MAX_VAL - 1) begin
                count <= '0; // 카운터가 최대값에 도달하면 0으로 래핑
            end else begin
                count <= count + 1;  // 1씩 증가
            end
        end
    end

    // 조합 논리: 내부 카운터 값과 SEGMENT_CLOCKS에 따라 out_pulse 출력 결정
    // count를 SEGMENT_CLOCKS로 나눈 몫이 짝수이면 0, 홀수이면 1을 출력합니다.
    assign out_pulse = ((count / DIV_RATIO) % 2 == 1'b1) ? 1'b1 : 1'b0;

endmodule
