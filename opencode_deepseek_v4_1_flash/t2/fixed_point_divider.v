module divider (
    input  signed [15:0] dividend,
    input  signed [15:0] divisor,
    output signed [15:0] quotient
);

    reg signed [15:0] quotient_reg;
    wire signed [22:0] dividend_shifted;

    assign dividend_shifted = {dividend, 7'b0};

    always @* begin
        if (divisor == 16'sd0)
            quotient_reg = 16'hFFFF;
        else
            quotient_reg = dividend_shifted / divisor;
    end

    assign quotient = quotient_reg;

endmodule
