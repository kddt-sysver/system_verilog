`timescale 1ns / 1ps

module counter_v3 (
    input  logic clk,
    input  logic rstn,
    input  logic en,       // 트리거 신호 (1클럭 펄스)

    output logic out_pulse      // 32클럭 동안 1 유지
);

    logic [4:0] cnt;            // 6비트 카운터 (0~31)
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
                if (cnt == 6'd31) begin
                    counting <= 0;
                    cnt      <= 0;
                end else begin
                    cnt <= cnt + 1;
                end
            end
        end
    end

    assign out_pulse = counting;

endmodule
