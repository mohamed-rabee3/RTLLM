module verified_divider(
    input  signed [15:0] dividend,
    input  signed [15:0] divisor,
    output signed [15:0] quotient
);
    wire signed [31:0] div_ext = dividend;       // sign-extend 16 -> 32
    wire signed [31:0] temp    = div_ext <<< 7;   // Q8.7 alignment (x128)
    wire signed [15:0] q       = temp / divisor;  // signed division, trunc toward zero
    assign quotient = (divisor == 16'sd0) ? -16'sd1 : q;   // div-by-zero -> 0xFFFF
endmodule
