module divider(
    input signed [15:0] dividend,
    input signed [15:0] divisor,
    output signed [15:0] quotient
);

    wire signed [31:0] dividend_shifted;
    wire signed [31:0] divisor_ext;
    wire signed [31:0] divisor_safe;
    wire signed [31:0] quotient_full;

    assign dividend_shifted = {{16{dividend[15]}}, dividend} <<< 7;
    assign divisor_ext = {{16{divisor[15]}}, divisor};
    assign divisor_safe = (divisor == 0) ? 32'sd1 : divisor_ext;
    assign quotient_full = dividend_shifted / divisor_safe;
    assign quotient = (divisor == 0) ? 16'hFFFF : quotient_full[15:0];

endmodule
