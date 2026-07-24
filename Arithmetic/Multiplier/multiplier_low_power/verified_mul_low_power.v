module verified_mul_low_power(
    input  [15:0] a,
    input  [15:0] b,
    output [31:0] result
);
    assign result = a * b;
endmodule
