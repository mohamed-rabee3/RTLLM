module verified_add(
    input  [15:0] a,
    input  [15:0] b,
    output [16:0] result
);
    // 16-bit + 16-bit -> 17-bit sum, zero-extended so carry-out is kept.
    assign result = {1'b0, a} + {1'b0, b};
endmodule
