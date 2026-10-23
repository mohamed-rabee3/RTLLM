module divider (
    input  wire signed [15:0] dividend,
    input  wire signed [15:0] divisor,
    output wire signed [15:0] quotient
);

    wire signed [22:0] scaled_dividend;
    wire signed [22:0] division_result;

    assign scaled_dividend = {dividend, 7'b0000000};
    assign division_result = scaled_dividend / divisor;

    assign quotient = (divisor == 16'sd0)
                    ? 16'hFFFF
                    : division_result[15:0];

endmodule
