module float_multi (
    input             clk,
    input             rst,
    input      [31:0] a,
    input      [31:0] b,
    output reg [31:0] z
);

    reg [2:0]  counter;
    reg [23:0] a_mantissa, b_mantissa, z_mantissa;
    reg [9:0]  a_exponent, b_exponent, z_exponent;
    reg        a_sign, b_sign, z_sign;
    reg [49:0] product;
    reg        guard_bit, round_bit, sticky;

    reg        special_valid;
    reg [31:0] special_result;

    wire [4:0]  a_normalize_shift;
    wire [4:0]  b_normalize_shift;
    wire [26:0] denormalized_mantissa;
    wire [7:0]  biased_exponent;

    // Exponents are stored as signed two's-complement values in 10 bits.
    function [4:0] leading_zero_count;
        input [23:0] value;
        integer i;
        reg found;
        begin
            leading_zero_count = 5'd24;
            found = 1'b0;
            for (i = 23; i >= 0; i = i - 1) begin
                if (!found && value[i]) begin
                    leading_zero_count = 23 - i;
                    found = 1'b1;
                end
            end
        end
    endfunction

    // Preserve all discarded information in the least-significant bit.
    function [26:0] shift_right_jam;
        input [26:0] value;
        input integer amount;
        integer i;
        reg discarded;
        reg [26:0] shifted;
        begin
            discarded = 1'b0;
            shifted = value;

            if (amount >= 27) begin
                shifted = {26'd0, |value};
            end else if (amount > 0) begin
                shifted = value >> amount;
                for (i = 0; i < 27; i = i + 1) begin
                    if (i < amount)
                        discarded = discarded | value[i];
                end
                shifted[0] = shifted[0] | discarded;
            end

            shift_right_jam = shifted;
        end
    endfunction

    assign a_normalize_shift = leading_zero_count(a_mantissa);
    assign b_normalize_shift = leading_zero_count(b_mantissa);

    assign denormalized_mantissa =
        shift_right_jam(
            {z_mantissa, guard_bit, round_bit, sticky},
            -126 - $signed(z_exponent)
        );

    assign biased_exponent = z_exponent + 10'd127;

    // One operand pair is accepted at counter == 0.
    // Its result is registered at counter == 7.
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            counter        <= 3'd0;
            z              <= 32'd0;
            a_mantissa     <= 24'd0;
            b_mantissa     <= 24'd0;
            z_mantissa     <= 24'd0;
            a_exponent     <= 10'd0;
            b_exponent     <= 10'd0;
            z_exponent     <= 10'd0;
            a_sign         <= 1'b0;
            b_sign         <= 1'b0;
            z_sign         <= 1'b0;
            product        <= 50'd0;
            guard_bit      <= 1'b0;
            round_bit      <= 1'b0;
            sticky         <= 1'b0;
            special_valid  <= 1'b0;
            special_result <= 32'd0;
        end else begin
            case (counter)
                3'd0: begin
                    a_sign <= a[31];
                    b_sign <= b[31];

                    a_mantissa <= {(a[30:23] != 8'd0), a[22:0]};
                    b_mantissa <= {(b[30:23] != 8'd0), b[22:0]};

                    if (a[30:23] == 8'd0)
                        a_exponent <= -10'sd126;
                    else
                        a_exponent <= {2'b00, a[30:23]} - 10'd127;

                    if (b[30:23] == 8'd0)
                        b_exponent <= -10'sd126;
                    else
                        b_exponent <= {2'b00, b[30:23]} - 10'd127;

                    special_valid  <= 1'b0;
                    special_result <= 32'd0;
                    counter        <= 3'd1;
                end

                3'd1: begin
                    // An unbiased exponent of 128 denotes infinity or NaN.
                    if (((a_exponent == 10'd128) &&
                         (a_mantissa[22:0] != 23'd0)) ||
                        ((b_exponent == 10'd128) &&
                         (b_mantissa[22:0] != 23'd0))) begin
                        special_valid  <= 1'b1;
                        special_result <= 32'h7fc00000;
                    end else if (((a_exponent == 10'd128) &&
                                  (b_mantissa == 24'd0)) ||
                                 ((b_exponent == 10'd128) &&
                                  (a_mantissa == 24'd0))) begin
                        // Infinity multiplied by zero is invalid.
                        special_valid  <= 1'b1;
                        special_result <= 32'h7fc00000;
                    end else if ((a_exponent == 10'd128) ||
                                 (b_exponent == 10'd128)) begin
                        special_valid  <= 1'b1;
                        special_result <= {
                            a_sign ^ b_sign, 8'hff, 23'd0
                        };
                    end else if ((a_mantissa == 24'd0) ||
                                 (b_mantissa == 24'd0)) begin
                        special_valid  <= 1'b1;
                        special_result <= {
                            a_sign ^ b_sign, 31'd0
                        };
                    end else begin
                        special_valid <= 1'b0;
                    end

                    counter <= 3'd2;
                end

                3'd2: begin
                    // Normalize finite subnormal operands.
                    a_mantissa <= a_mantissa << a_normalize_shift;
                    b_mantissa <= b_mantissa << b_normalize_shift;

                    a_exponent <= a_exponent -
                                  {5'd0, a_normalize_shift};
                    b_exponent <= b_exponent -
                                  {5'd0, b_normalize_shift};

                    counter <= 3'd3;
                end

                3'd3: begin
                    product    <= a_mantissa * b_mantissa;
                    z_exponent <= a_exponent + b_exponent;
                    z_sign     <= a_sign ^ b_sign;
                    counter    <= 3'd4;
                end

                3'd4: begin
                    // Normalize the exact 48-bit significand product.
                    if (product[47]) begin
                        z_mantissa <= product[47:24];
                        guard_bit  <= product[23];
                        round_bit  <= product[22];
                        sticky     <= |product[21:0];
                        z_exponent <= z_exponent + 10'd1;
                    end else begin
                        z_mantissa <= product[46:23];
                        guard_bit  <= product[22];
                        round_bit  <= product[21];
                        sticky     <= |product[20:0];
                    end

                    counter <= 3'd5;
                end

                3'd5: begin
                    // Apply gradual underflow before rounding.
                    if ($signed(z_exponent) < -10'sd126) begin
                        z_mantissa <= denormalized_mantissa[26:3];
                        guard_bit  <= denormalized_mantissa[2];
                        round_bit  <= denormalized_mantissa[1];
                        sticky     <= denormalized_mantissa[0];
                        z_exponent <= -10'sd126;
                    end

                    counter <= 3'd6;
                end

                3'd6: begin
                    // IEEE-754 round to nearest, ties to even.
                    if (guard_bit &&
                        (round_bit || sticky || z_mantissa[0])) begin
                        if (z_mantissa == 24'hffffff) begin
                            z_mantissa <= 24'h800000;
                            z_exponent <= z_exponent + 10'd1;
                        end else begin
                            z_mantissa <= z_mantissa + 24'd1;
                        end
                    end

                    counter <= 3'd7;
                end

                3'd7: begin
                    if (special_valid) begin
                        z <= special_result;
                    end else if ($signed(z_exponent) > 10'sd127) begin
                        z <= {z_sign, 8'hff, 23'd0};
                    end else if (z_mantissa == 24'd0) begin
                        z <= {z_sign, 31'd0};
                    end else if (($signed(z_exponent) == -10'sd126) &&
                                 !z_mantissa[23]) begin
                        z <= {z_sign, 8'd0, z_mantissa[22:0]};
                    end else begin
                        z <= {
                            z_sign, biased_exponent, z_mantissa[22:0]
                        };
                    end

                    counter <= 3'd0;
                end

                default: begin
                    counter <= 3'd0;
                end
            endcase
        end
    end

endmodule
