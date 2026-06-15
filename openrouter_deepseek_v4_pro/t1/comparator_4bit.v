module comparator_4bit (
    input [3:0] A,
    input [3:0] B,
    output A_greater,
    output A_equal,
    output A_less
);

    // Internal wires for the 4-bit subtractor
    wire [3:0] diff;          // Difference bits (A - B)
    wire [4:0] borrow;        // Borrow chain: borrow[0] is initial borrow-in (0),
                              // borrow[4] is final borrow-out

    // Initial borrow-in is 0
    assign borrow[0] = 1'b0;

    // Generate 4 bit-level full subtractors
    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin : bit_sub
            // Difference output: A[i] - B[i] - borrow[i]
            assign diff[i] = A[i] ^ B[i] ^ borrow[i];
            // Borrow-out to next stage
            assign borrow[i+1] = (~A[i] & B[i]) | (~A[i] & borrow[i]) | (B[i] & borrow[i]);
        end
    endgenerate

    // Determine comparison outputs based on subtraction result
    assign A_less    = borrow[4];                     // Borrow-out = 1  => A < B
    assign A_equal   = (diff == 4'b0000) ? 1'b1 : 1'b0; // Difference = 0 => A == B
    assign A_greater = ~A_less & ~A_equal;             // Otherwise A > B

endmodule