`timescale 1ns / 1ps
module twd_mul20 #(
    parameter int WIDTH = 13
) (
    input  logic clk,
    input  logic rstn,
    input  logic twd20_valid,

    input  logic signed [WIDTH-1:0] i_20bfly_re[0:15],
    input  logic signed [WIDTH-1:0] i_20bfly_im[0:15],

    output logic signed [WIDTH-1:0] twd_20_re[0:15],
    output logic signed [WIDTH-1:0] twd_20_im[0:15]
);

    // 전체 데이터 위치 카운터 (0~511)
    integer base_idx;
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn)
            base_idx <= 0;
        else if (twd20_valid)
            base_idx <= base_idx + 16; // 한 클럭에 16개 처리
    end

    integer j;
    integer nn;
    integer tw_idx;

    always_comb begin
        for (j = 0; j < 16; j++) begin
            // 현재 데이터의 위치에서 nn(0~7) 계산
            nn = ( (base_idx + j) % 8 );
            // twiddle index (0~3)
            tw_idx = nn >> 1;

            // twiddle 곱 적용
            case (tw_idx)
                0, 1, 2: begin // ×1
                    twd_20_re[j] = i_20bfly_re[j];
                    twd_20_im[j] = i_20bfly_im[j];
                end
                3: begin // ×(-j)
                    twd_20_re[j] =  i_20bfly_im[j];
                    twd_20_im[j] = -i_20bfly_re[j];
                end
                default: begin
                    twd_20_re[j] = i_20bfly_re[j];
                    twd_20_im[j] = i_20bfly_im[j];
                end
            endcase
        end
    end

endmodule
