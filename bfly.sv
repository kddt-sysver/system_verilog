`timescale 1ns/1ps

module bfly #(
    parameter WIDTH = 12,
    parameter NUM_PAIR = 16 // 16, 8, 4, 2
)(
    input  logic clk,
    input  logic rstn,

    input  logic bfly_valid,

    input  logic signed [WIDTH-1:0] din_re [0:NUM_PAIR-1],
    input  logic signed [WIDTH-1:0] din_im [0:NUM_PAIR-1],
    input  logic signed [WIDTH-1:0] shift_data_re [0:NUM_PAIR-1],
    input  logic signed [WIDTH-1:0] shift_data_im [0:NUM_PAIR-1],

    output logic signed [WIDTH:0] bfly_sum_re [0:NUM_PAIR-1],
    output logic signed [WIDTH:0] bfly_sum_im [0:NUM_PAIR-1],
    output logic signed [WIDTH:0] bfly_diff_re [0:NUM_PAIR-1],
    output logic signed [WIDTH:0] bfly_diff_im [0:NUM_PAIR-1],

    output logic twiddle_valid
);

    typedef enum logic [2:0] {IDLE, SUM, IDLE2, DIFF} state_t;
    state_t state, next_state;

    logic [$clog2(NUM_PAIR)-1:0] count;

    // FSM 상태 전이
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn)
            state <= IDLE;
        else
            state <= next_state;
    end

    always_comb begin
        case (state)
            IDLE:     next_state = (count == NUM_PAIR-1) ? SUM : IDLE;
            SUM:      next_state = (count == NUM_PAIR-1) ? IDLE2 : SUM;
            IDLE2:    next_state = (count == NUM_PAIR-1) ? DIFF : IDLE2;
            DIFF:     next_state = (count == NUM_PAIR-1) ? IDLE : DIFF;
            default:  next_state = IDLE;
        endcase
    end

    // 카운터
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn)
            count <= 0;
        else if (count == NUM_PAIR-1)
            count <= 0;
        else if (state == IDLE || state == IDLE2)
            count <= count + 1;
        else if ((state == SUM || state == DIFF) && bfly_valid)
            count <= count + 1;
    end

    // 출력 계산 (SUM / DIFF) - signed로 부호 확장
    // SUM 연산 결과
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            for (int i = 0; i < NUM_PAIR; i++) begin
                bfly_sum_re[i] <= 0;
                bfly_sum_im[i] <= 0;
            end
        end else if (state == SUM && bfly_valid) begin
            for (int i = 0; i < NUM_PAIR; i++) begin
                bfly_sum_re[i] <= $signed(shift_data_re[i]) + $signed(din_re[i]);
                bfly_sum_im[i] <= $signed(shift_data_im[i]) + $signed(din_im[i]);
            end
        end else begin
            for (int i = 0; i < NUM_PAIR; i++) begin
                bfly_sum_re[i] <= 0;
                bfly_sum_im[i] <= 0;
            end
        end
    end
    
    // DIFF 연산 결과
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            for (int i = 0; i < NUM_PAIR; i++) begin
                bfly_diff_re[i] <= 0;
                bfly_diff_im[i] <= 0;
            end
        end else if (state == DIFF && bfly_valid) begin
            for (int i = 0; i < NUM_PAIR; i++) begin
                bfly_diff_re[i] <= $signed(shift_data_re[i]) - $signed(din_re[i]);
                bfly_diff_im[i] <= $signed(shift_data_im[i]) - $signed(din_im[i]);
            end
        end else begin
            for (int i = 0; i < NUM_PAIR; i++) begin
                bfly_diff_re[i] <= 0;
                bfly_diff_im[i] <= 0;
            end
        end
    end

    // twiddle_valid (DIFF 완료 후 1클럭 지연 출력)
    logic twiddle_valid_d;

    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            twiddle_valid_d <= 1'b0;
            twiddle_valid   <= 1'b0;
        end else begin
            twiddle_valid_d <= (state == DIFF && count == NUM_PAIR-1);
            twiddle_valid   <= twiddle_valid_d;
        end
    end

endmodule

