module div_16bit (
    input wire [15:0] A,       // 16-bit dividend
    input wire [7:0]  B,       // 8-bit divisor
    output reg [15:0] result,  // 16-bit quotient
    output reg [15:0] odd      // 16-bit remainder
);

    // Registers to hold the input values
    reg [15:0] a_reg;
    reg [7:0]  b_reg;

    // First always block: combinational, updates a_reg and b_reg with A and B
    always @(A, B) begin
        a_reg = A;
        b_reg = B;
    end

    // Second always block: combinational, performs the division using a_reg and b_reg
    always @(a_reg, b_reg) begin
        reg [7:0]  remainder;
        reg [15:0] quotient;
        integer    i;

        quotient  = 16'd0;
        remainder = 8'd0;

        if (b_reg == 8'd0) begin
            // Division by zero: set outputs to all-ones (safe default)
            result = 16'hFFFF;
            odd    = 16'hFFFF;
        end else begin
            // Restoring division algorithm (shift-and-subtract)
            for (i = 15; i >= 0; i = i - 1) begin
                // Shift left and bring down the next bit of the dividend
                remainder = {remainder[6:0], a_reg[i]};
                if (remainder >= b_reg) begin
                    remainder    = remainder - b_reg;
                    quotient[i] = 1'b1;
                end else begin
                    quotient[i] = 1'b0;
                end
            end
            result = quotient;
            odd    = {8'd0, remainder};  // Zero-extend remainder to 16 bits
        end
    end

endmodule