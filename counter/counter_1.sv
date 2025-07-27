`timescale 1ns / 1ps

module counter #(
  parameter int COUNT_MAX_VAL = 4      // 카운트 폭을 직접 지정 (예: 4비트 → 0..15 순환)
)(
  input  logic           clk,
  input  logic           rstn,
  input  logic           en,            // 카운트 인에이블
  output logic [COUNT_MAX_VAL-1:0] count_out     // 현재 카운트 값
);

  // 내부 카운터 레지스터
  logic [COUNT_MAX_VAL-1:0] count;

  // 순차 카운터: en이 1일 때만 1씩 증가, 자동 래핑(modulo 2^WIDTH)
  always_ff @(posedge clk or negedge rstn) begin
    if (!rstn)
      count <= '0;
    else if (en)
      count <= count + 1;  // overflow 시 자동으로 0으로 돌아갑니다.
  end

  // 외부로 값 노출
  assign count_out = count;

endmodule
