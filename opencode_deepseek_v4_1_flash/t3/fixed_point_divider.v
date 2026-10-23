module divider(
    input  signed [15:0] dividend,
    input  signed [15:0] divisor,
    output reg signed [15:0] quotient
);

    reg signed [31:0] dividend_ext;
    reg signed [31:0] divisor_ext;
    reg signed [31:0] result;

    always @(*) begin
        dividend_ext = dividend;
        divisor_ext  = divisor;
        result       = 32'sd0;

        if (divisor == 16'sd0) begin
            quotient = 16'hFFFF;
        end else begin
            result = (dividend_ext <<< 7) / divisor_ext;
            quotient = result[15:0];
        end
    end

endmodule
