module divider (
    input  signed [15:0] dividend,
    input  signed [15:0] divisor,
    output reg signed [15:0] quotient
);

    reg [16:0] abs_dividend;
    reg [15:0] abs_divisor;
    reg [23:0] abs_numer;
    reg [23:0] remainder;
    reg [23:0] quotient_abs;
    reg sign;
    integer i;

    always @(*) begin
        // Default assignments
        abs_dividend = 17'd0;
        abs_divisor  = 16'd0;
        abs_numer    = 24'd0;
        remainder    = 24'd0;
        quotient_abs = 24'd0;
        sign         = 1'b0;
        quotient     = 16'hFFFF;

        if (divisor == 16'sd0) begin
            quotient = 16'hFFFF;
        end else begin
            // Absolute value of dividend (17-bit to handle -32768)
            if (dividend[15]) begin
                abs_dividend = (~{dividend[15], dividend}) + 17'd1;
            end else begin
                abs_dividend = {1'b0, dividend};
            end

            // Absolute value of divisor (16-bit, -32768 -> 32768)
            if (divisor[15]) begin
                abs_divisor = (~divisor) + 16'd1;
            end else begin
                abs_divisor = divisor;
            end

            // Shift dividend left by 7 bits (multiply by 128)
            abs_numer = {7'b0, abs_dividend} << 7;

            // Sign of quotient
            sign = dividend[15] ^ divisor[15];

            // Unsigned division: abs_numer / abs_divisor
            remainder = 24'd0;
            quotient_abs = 24'd0;
            for (i = 23; i >= 0; i = i - 1) begin
                remainder = {remainder[22:0], abs_numer[i]};
                if (remainder >= {8'b0, abs_divisor}) begin
                    remainder = remainder - {8'b0, abs_divisor};
                    quotient_abs[i] = 1'b1;
                end else begin
                    quotient_abs[i] = 1'b0;
                end
            end

            // Apply sign and truncate to 16 bits
            if (sign) begin
                quotient = -quotient_abs[15:0];
            end else begin
                quotient = quotient_abs[15:0];
            end
        end
    end

endmodule
