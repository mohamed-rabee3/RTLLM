module divider (
    input  signed [15:0] dividend,
    input  signed [15:0] divisor,
    output reg signed [15:0] quotient
);

    reg [15:0] abs_dividend;
    reg [15:0] abs_divisor;
    reg [22:0] numer;
    reg [22:0] quot_abs;
    reg [23:0] rem;
    reg [15:0] quot_abs_16;
    reg        sign;
    integer    i;

    always @(*) begin
        if (divisor == 16'sd0) begin
            quotient = 16'hFFFF;
        end else begin
            // Absolute values
            abs_dividend = (dividend[15]) ? -dividend : dividend;
            abs_divisor  = (divisor[15])  ? -divisor  : divisor;

            // Shift dividend left by 7 bits (multiply by 128) for Q8.7 alignment
            numer = {abs_dividend, 7'b0};

            // Unsigned restoring division
            rem = 24'd0;
            quot_abs = 23'd0;
            for (i = 22; i >= 0; i = i - 1) begin
                rem = {rem[22:0], numer[i]};
                if (rem >= abs_divisor) begin
                    rem = rem - abs_divisor;
                    quot_abs[i] = 1'b1;
                end else begin
                    quot_abs[i] = 1'b0;
                end
            end

            // Determine sign of the result
            sign = dividend[15] ^ divisor[15];

            // Truncate to 16 bits and apply sign (truncation toward zero)
            quot_abs_16 = quot_abs[15:0];
            if (sign)
                quotient = -quot_abs_16;
            else
                quotient = quot_abs_16;
        end
    end

endmodule
