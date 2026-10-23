module divider (
    input  wire signed [15:0] dividend,
    input  wire signed [15:0] divisor,
    output wire signed [15:0] quotient
);

    wire signed [31:0] scaled_dividend;
    wire signed [31:0] extended_divisor;
    wire signed [31:0] full_quotient;

    assign scaled_dividend = {{16{dividend[15]}}, dividend} << 7;
    assign extended_divisor = {{16{divisor[15]}}, divisor};

    assign full_quotient = (divisor == 16'sd0)
                         ? 32'sd0
                         : scaled_dividend / extended_divisor;

    assign quotient = (divisor == 16'sd0)
                    ? 16'hFFFF
                    : full_quotient[15:0];

endmodule
