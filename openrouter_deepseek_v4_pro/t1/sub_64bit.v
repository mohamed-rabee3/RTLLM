module sub_64bit (
    input  [63:0] A,
    input  [63:0] B,
    output [63:0] result,
    output        overflow
);

    // Perform 64-bit subtraction
    assign result = A - B;

    // Overflow detection based on sign bits:
    // Overflow occurs only when A and B have different signs,
    // and the sign of the result differs from the sign of A.
    // Positive overflow: A positive, B negative, result negative.
    // Negative overflow: A negative, B positive, result positive.
    assign overflow = (A[63] != B[63]) && (result[63] != A[63]);

endmodule