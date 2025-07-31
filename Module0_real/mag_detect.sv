`timescale 1ns / 1ps

module mag_detect #(
    parameter int WIDTH = 23  // Input bit width
) (
    input  logic signed [WIDTH-1:0] in,     // Signed input data
    output logic [$clog2(WIDTH)-1:0] index // MSB index (0 to WIDTH-1)
);

    logic signed [WIDTH-1:0] di_val;
    assign di_val = in;

    // This logic is a priority encoder to find the MSB position.
    // For positive numbers (~di_val[WIDTH-1]), it checks for leading zeros in the magnitude part.
    // For negative numbers (di_val[WIDTH-1]), it checks for leading ones in the magnitude part (after sign extension, effectively MSB of absolute value).
    // The returned index is the 0-indexed bit position of the most significant '1' (for positive)
    // or most significant '0' (for negative) in the magnitude portion.
    // For value 0, it returns WIDTH-1 (22 for 23-bit).
    assign index =
        // Handle special case for 0 (all bits are 0 for a positive 0)
        (in == '0) ? 0 : 
        // Handle special case for -1 (all bits are 1 for a negative -1)
        (in == -1) ? 0 : 

        // For positive numbers (sign bit is 0), find the MSB '1' starting from WIDTH-2 down to 0
        // Check from MSB (excluding sign bit) down to LSB (bit 0)
        !di_val[WIDTH-1] ? (  // if positive number
        (di_val[WIDTH-2]) ? (WIDTH - 2) :  // Check bit 21
        (WIDTH - 2 >= 1 && di_val[WIDTH-3]) ? (WIDTH - 3) :  // Check bit 20
        (WIDTH - 2 >= 2 && di_val[WIDTH-4]) ? (WIDTH - 4) :  // Check bit 19
        (WIDTH - 2 >= 3 && di_val[WIDTH-5]) ? (WIDTH - 5) :  // Check bit 18
        (WIDTH - 2 >= 4 && di_val[WIDTH-6]) ? (WIDTH - 6) :  // Check bit 17
        (WIDTH - 2 >= 5 && di_val[WIDTH-7]) ? (WIDTH - 7) :  // Check bit 16
        (WIDTH - 2 >= 6 && di_val[WIDTH-8]) ? (WIDTH - 8) :  // Check bit 15
        (WIDTH - 2 >= 7 && di_val[WIDTH-9]) ? (WIDTH - 9) :  // Check bit 14
        (WIDTH - 2 >= 8 && di_val[WIDTH-10]) ? (WIDTH - 10) :  // Check bit 13
        (WIDTH - 2 >= 9 && di_val[WIDTH-11]) ? (WIDTH - 11) :  // Check bit 12
        (WIDTH - 2 >= 10 && di_val[WIDTH-12]) ? (WIDTH - 12) :  // Check bit 11
        (WIDTH - 2 >= 11 && di_val[WIDTH-13]) ? (WIDTH - 13) :  // Check bit 10
        (WIDTH - 2 >= 12 && di_val[WIDTH-14]) ? (WIDTH - 14) :  // Check bit 9
        (WIDTH - 2 >= 13 && di_val[WIDTH-15]) ? (WIDTH - 15) :  // Check bit 8
        (WIDTH - 2 >= 14 && di_val[WIDTH-16]) ? (WIDTH - 16) :  // Check bit 7
        (WIDTH - 2 >= 15 && di_val[WIDTH-17]) ? (WIDTH - 17) :  // Check bit 6
        (WIDTH - 2 >= 16 && di_val[WIDTH-18]) ? (WIDTH - 18) :  // Check bit 5
        (WIDTH - 2 >= 17 && di_val[WIDTH-19]) ? (WIDTH - 19) :  // Check bit 4
        (WIDTH - 2 >= 18 && di_val[WIDTH-20]) ? (WIDTH - 20) :  // Check bit 3
        (WIDTH - 2 >= 19 && di_val[WIDTH-21]) ? (WIDTH - 21) :  // Check bit 2
        (WIDTH - 2 >= 20 && di_val[WIDTH-22]) ? (WIDTH - 22) :  // Check bit 1
        (WIDTH - 2 >= 21 && di_val[WIDTH-23]) ? (WIDTH - 23) :  // Check bit 0
        0  // Should not be reached for non-zero positive numbers
        ) :
        // For negative numbers (sign bit is 1), find the MSB '0' starting from WIDTH-2 down to 0
        (  // if negative number (except -1 handled above)
        (di_val[WIDTH-2] == 1'b0) ? (WIDTH - 2) :  // Check bit 21 for 0
        (WIDTH-2 >= 1 && di_val[WIDTH-3] == 1'b0) ? (WIDTH-3) : // Check bit 20 for 0
        (WIDTH-2 >= 2 && di_val[WIDTH-4] == 1'b0) ? (WIDTH-4) : // Check bit 19 for 0
        (WIDTH-2 >= 3 && di_val[WIDTH-5] == 1'b0) ? (WIDTH-5) : // Check bit 18 for 0
        (WIDTH-2 >= 4 && di_val[WIDTH-6] == 1'b0) ? (WIDTH-6) : // Check bit 17 for 0
        (WIDTH-2 >= 5 && di_val[WIDTH-7] == 1'b0) ? (WIDTH-7) : // Check bit 16 for 0
        (WIDTH-2 >= 6 && di_val[WIDTH-8] == 1'b0) ? (WIDTH-8) : // Check bit 15 for 0
        (WIDTH-2 >= 7 && di_val[WIDTH-9] == 1'b0) ? (WIDTH-9) : // Check bit 14 for 0
        (WIDTH-2 >= 8 && di_val[WIDTH-10] == 1'b0) ? (WIDTH-10) : // Check bit 13 for 0
        (WIDTH-2 >= 9 && di_val[WIDTH-11] == 1'b0) ? (WIDTH-11) : // Check bit 12 for 0
        (WIDTH-2 >= 10 && di_val[WIDTH-12] == 1'b0) ? (WIDTH-12) : // Check bit 11 for 0
        (WIDTH-2 >= 11 && di_val[WIDTH-13] == 1'b0) ? (WIDTH-13) : // Check bit 10 for 0
        (WIDTH-2 >= 12 && di_val[WIDTH-14] == 1'b0) ? (WIDTH-14) : // Check bit 9 for 0
        (WIDTH-2 >= 13 && di_val[WIDTH-15] == 1'b0) ? (WIDTH-15) : // Check bit 8 for 0
        (WIDTH-2 >= 14 && di_val[WIDTH-16] == 1'b0) ? (WIDTH-16) : // Check bit 7 for 0
        (WIDTH-2 >= 15 && di_val[WIDTH-17] == 1'b0) ? (WIDTH-17) : // Check bit 6 for 0
        (WIDTH-2 >= 16 && di_val[WIDTH-18] == 1'b0) ? (WIDTH-18) : // Check bit 5 for 0
        (WIDTH-2 >= 17 && di_val[WIDTH-19] == 1'b0) ? (WIDTH-19) : // Check bit 4 for 0
        (WIDTH-2 >= 18 && di_val[WIDTH-20] == 1'b0) ? (WIDTH-20) : // Check bit 3 for 0
        (WIDTH-2 >= 19 && di_val[WIDTH-21] == 1'b0) ? (WIDTH-21) : // Check bit 2 for 0
        (WIDTH-2 >= 20 && di_val[WIDTH-22] == 1'b0) ? (WIDTH-22) : // Check bit 1 for 0
        (WIDTH-2 >= 21 && di_val[WIDTH-23] == 1'b0) ? (WIDTH-23) : // Check bit 0 for 0
        0  // Should not be reached for non-negative -1 numbers
        );

endmodule
