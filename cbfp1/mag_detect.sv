`timescale 1ns / 1ps

module mag_detect #(
    parameter int WIDTH = 25  // Input bit width
) (
    input  logic signed [WIDTH-1:0] in,     // Signed input data
    output logic [$clog2(WIDTH)-1:0] index // MSB index (0 to WIDTH-1)
);

    logic signed [WIDTH-1:0] di_val;
    assign di_val = in;

    // Priority encoder to find MSB index
    assign index =
        // Special case: 0
        (in == '0)  ? 0 :
        // Special case: -1
        (in == -1)  ? 0 :
        
        // Positive number (sign=0)
        !di_val[WIDTH-1] ? (
            (di_val[WIDTH-2]) ? (WIDTH - 2) :
            (di_val[WIDTH-3]) ? (WIDTH - 3) :
            (di_val[WIDTH-4]) ? (WIDTH - 4) :
            (di_val[WIDTH-5]) ? (WIDTH - 5) :
            (di_val[WIDTH-6]) ? (WIDTH - 6) :
            (di_val[WIDTH-7]) ? (WIDTH - 7) :
            (di_val[WIDTH-8]) ? (WIDTH - 8) :
            (di_val[WIDTH-9]) ? (WIDTH - 9) :
            (di_val[WIDTH-10]) ? (WIDTH - 10) :
            (di_val[WIDTH-11]) ? (WIDTH - 11) :
            (di_val[WIDTH-12]) ? (WIDTH - 12) :
            (di_val[WIDTH-13]) ? (WIDTH - 13) :
            (di_val[WIDTH-14]) ? (WIDTH - 14) :
            (di_val[WIDTH-15]) ? (WIDTH - 15) :
            (di_val[WIDTH-16]) ? (WIDTH - 16) :
            (di_val[WIDTH-17]) ? (WIDTH - 17) :
            (di_val[WIDTH-18]) ? (WIDTH - 18) :
            (di_val[WIDTH-19]) ? (WIDTH - 19) :
            (di_val[WIDTH-20]) ? (WIDTH - 20) :
            (di_val[WIDTH-21]) ? (WIDTH - 21) :
            (di_val[WIDTH-22]) ? (WIDTH - 22) :
            (di_val[WIDTH-23]) ? (WIDTH - 23) :
            (di_val[WIDTH-24]) ? (WIDTH - 24) :
            0
        ) :
        
        // Negative number (sign=1)
        (
            (di_val[WIDTH-2] == 1'b0) ? (WIDTH - 2) :
            (di_val[WIDTH-3] == 1'b0) ? (WIDTH - 3) :
            (di_val[WIDTH-4] == 1'b0) ? (WIDTH - 4) :
            (di_val[WIDTH-5] == 1'b0) ? (WIDTH - 5) :
            (di_val[WIDTH-6] == 1'b0) ? (WIDTH - 6) :
            (di_val[WIDTH-7] == 1'b0) ? (WIDTH - 7) :
            (di_val[WIDTH-8] == 1'b0) ? (WIDTH - 8) :
            (di_val[WIDTH-9] == 1'b0) ? (WIDTH - 9) :
            (di_val[WIDTH-10] == 1'b0) ? (WIDTH - 10) :
            (di_val[WIDTH-11] == 1'b0) ? (WIDTH - 11) :
            (di_val[WIDTH-12] == 1'b0) ? (WIDTH - 12) :
            (di_val[WIDTH-13] == 1'b0) ? (WIDTH - 13) :
            (di_val[WIDTH-14] == 1'b0) ? (WIDTH - 14) :
            (di_val[WIDTH-15] == 1'b0) ? (WIDTH - 15) :
            (di_val[WIDTH-16] == 1'b0) ? (WIDTH - 16) :
            (di_val[WIDTH-17] == 1'b0) ? (WIDTH - 17) :
            (di_val[WIDTH-18] == 1'b0) ? (WIDTH - 18) :
            (di_val[WIDTH-19] == 1'b0) ? (WIDTH - 19) :
            (di_val[WIDTH-20] == 1'b0) ? (WIDTH - 20) :
            (di_val[WIDTH-21] == 1'b0) ? (WIDTH - 21) :
            (di_val[WIDTH-22] == 1'b0) ? (WIDTH - 22) :
            (di_val[WIDTH-23] == 1'b0) ? (WIDTH - 23) :
            (di_val[WIDTH-24] == 1'b0) ? (WIDTH - 24) :
            0
        );

endmodule

