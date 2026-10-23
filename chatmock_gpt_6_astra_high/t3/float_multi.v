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

    reg        special_case;
    reg [31:0] special_result;

    reg [23:0] normalized_a_mantissa;
    reg [23:0] normalized_b_mantissa;
    reg [9:0]  normalized_a_exponent;
    reg [9:0]  normalized_b_exponent;

    reg [23:0] shifted_mantissa;
    reg        next_guard_bit;
    reg        next_round_bit;
    reg        next_sticky;

    wire [9:0] biased_exponent;

    integer normalize_index;
    integer sticky_index;
    integer shift_amount;

    assign biased_exponent = z_exponent + 10'd127;

    // Normalize finite nonzero operands, including subnormal inputs.
    always @* begin
        normalized_a_mantissa = a_mantissa;
        normalized_b_mantissa = b_mantissa;
        normalized_a_exponent = a_exponent;
        normalized_b_exponent = b_exponent;

        for (normalize_index = 0;
             normalize_index < 23;
             normalize_index = normalize_index + 1) begin

            if ((normalized_a_mantissa != 24'd0) &&
                !normalized_a_mantissa[23]) begin
                normalized_a_mantissa = normalized_a_mantissa << 1;
                normalized_a_exponent = normalized_a_exponent - 10'd1;
            end

            if ((normalized_b_mantissa != 24'd0) &&
                !normalized_b_mantissa[23]) begin
                normalized_b_mantissa = normalized_b_mantissa << 1;
                normalized_b_exponent = normalized_b_exponent - 10'd1;
            end
        end
    end

    // Extract the retained significand and rounding information.
    // Subnormal results are shifted before rounding to avoid double rounding.
    always @* begin
        shift_amount = 24;
        if ($signed(z_exponent) < -10'sd126)
            shift_amount = 24 + (-126 - $signed(z_exponent));

        shifted_mantissa = product >> shift_amount;
        next_guard_bit = 1'b0;
        next_round_bit = 1'b0;
        next_sticky = 1'b0;

        if ((shift_amount >= 1) && (shift_amount <= 50))
            next_guard_bit = product[shift_amount - 1];

        if ((shift_amount >= 2) && (shift_amount <= 51))
            next_round_bit = product[shift_amount - 2];

        for (sticky_index = 0;
             sticky_index < 50;
             sticky_index = sticky_index + 1) begin
            if (sticky_index < (shift_amount - 2))
                next_sticky = next_sticky | product[sticky_index];
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            counter        <= 3'd0;
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
            special_case   <= 1'b0;
            special_result <= 32'd0;
            z              <= 32'd0;
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

                    special_case   <= 1'b0;
                    special_result <= 32'd0;
                    counter        <= 3'd1;
                end

                3'd1: begin
                    // Exponent 128 denotes an original exponent field of 255.
                    if (((a_exponent == 10'd128) &&
                         (a_mantissa[22:0] != 23'd0)) ||
                        ((b_exponent == 10'd128) &&
                         (b_mantissa[22:0] != 23'd0))) begin
                        special_case   <= 1'b1;
                        special_result <= 32'h7fc00000;
                    end else if (((a_exponent == 10'd128) &&
                                  (b_mantissa == 24'd0)) ||
                                 ((b_exponent == 10'd128) &&
                                  (a_mantissa == 24'd0))) begin
                        // Infinity multiplied by zero is invalid.
                        special_case   <= 1'b1;
                        special_result <= 32'h7fc00000;
                    end else if ((a_exponent == 10'd128) ||
                                 (b_exponent == 10'd128)) begin
                        special_case   <= 1'b1;
                        special_result <= {a_sign ^ b_sign, 8'hff, 23'd0};
                    end else if ((a_mantissa == 24'd0) ||
                                 (b_mantissa == 24'd0)) begin
                        special_case   <= 1'b1;
                        special_result <= {a_sign ^ b_sign, 31'd0};
                    end
                    counter <= 3'd2;
                end

                3'd2: begin
                    a_mantissa <= normalized_a_mantissa;
                    b_mantissa <= normalized_b_mantissa;
                    a_exponent <= normalized_a_exponent;
                    b_exponent <= normalized_b_exponent;
                    counter    <= 3'd3;
                end

                3'd3: begin
                    product    <= a_mantissa * b_mantissa;
                    z_exponent <= a_exponent + b_exponent;
                    z_sign     <= a_sign ^ b_sign;
                    counter    <= 3'd4;
                end

                3'd4: begin
                    // Place the leading product bit at bit 47.
                    if (product[47]) begin
                        z_exponent <= z_exponent + 10'd1;
                    end else begin
                        product <= product << 1;
                    end
                    counter <= 3'd5;
                end

                3'd5: begin
                    z_mantissa <= shifted_mantissa;
                    guard_bit  <= next_guard_bit;
                    round_bit  <= next_round_bit;
                    sticky     <= next_sticky;

                    if ($signed(z_exponent) < -10'sd126)
                        z_exponent <= -10'sd126;

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
                    if (special_case) begin
                        z <= special_result;
                    end else if ($signed(z_exponent) > 10'sd127) begin
                        z <= {z_sign, 8'hff, 23'd0};
                    end else if (z_mantissa == 24'd0) begin
                        z <= {z_sign, 31'd0};
                    end else if (($signed(z_exponent) == -10'sd126) &&
                                 !z_mantissa[23]) begin
                        z <= {z_sign, 8'd0, z_mantissa[22:0]};
                    end else begin
                        z <= {z_sign, biased_exponent[7:0],
                              z_mantissa[22:0]};
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
