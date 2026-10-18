module float_multi (
    input  wire        clk,
    input  wire        rst,
    input  wire [31:0] a,
    input  wire [31:0] b,
    output reg  [31:0] z
);

    reg [2:0]  counter;
    reg [23:0] a_mantissa, b_mantissa, z_mantissa;
    reg [9:0]  a_exponent, b_exponent, z_exponent;
    reg        a_sign, b_sign, z_sign;
    reg [49:0] product;
    reg        guard_bit, round_bit, sticky;

    reg        special_case;
    reg [31:0] special_result;

    reg [23:0] normalized_a, normalized_b;
    reg [9:0]  normalized_a_exp, normalized_b_exp;

    reg [26:0] extended_mantissa;
    reg [26:0] shifted_mantissa;
    reg        discarded_bits;
    integer    shift_amount;
    integer    i;
    integer    j;

    // Normalize finite, nonzero operands, including subnormal inputs.
    always @* begin
        normalized_a     = a_mantissa;
        normalized_b     = b_mantissa;
        normalized_a_exp = a_exponent;
        normalized_b_exp = b_exponent;

        for (i = 0; i < 23; i = i + 1) begin
            if ((normalized_a != 24'b0) && !normalized_a[23]) begin
                normalized_a     = normalized_a << 1;
                normalized_a_exp = normalized_a_exp - 10'd1;
            end
            if ((normalized_b != 24'b0) && !normalized_b[23]) begin
                normalized_b     = normalized_b << 1;
                normalized_b_exp = normalized_b_exp - 10'd1;
            end
        end
    end

    // Right-shift with jamming for gradual underflow.
    always @* begin
        extended_mantissa = {z_mantissa, guard_bit, round_bit, sticky};
        shifted_mantissa  = extended_mantissa;
        discarded_bits   = 1'b0;
        shift_amount     = 0;

        if ($signed(z_exponent) < -126) begin
            shift_amount = -126 - $signed(z_exponent);

            if (shift_amount >= 27) begin
                shifted_mantissa    = 27'b0;
                shifted_mantissa[0] = |extended_mantissa;
            end else begin
                shifted_mantissa = extended_mantissa >> shift_amount;
                for (j = 0; j < 27; j = j + 1) begin
                    if (j < shift_amount)
                        discarded_bits = discarded_bits |
                                         extended_mantissa[j];
                end
                shifted_mantissa[0] = shifted_mantissa[0] |
                                      discarded_bits;
            end
        end
    end

    // Operands are sampled at counter zero; the result is committed
    // at counter seven. Rounding mode is round-to-nearest, ties-to-even.
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            counter        <= 3'd0;
            z              <= 32'b0;
            a_mantissa     <= 24'b0;
            b_mantissa     <= 24'b0;
            z_mantissa     <= 24'b0;
            a_exponent     <= 10'b0;
            b_exponent     <= 10'b0;
            z_exponent     <= 10'b0;
            a_sign         <= 1'b0;
            b_sign         <= 1'b0;
            z_sign         <= 1'b0;
            product        <= 50'b0;
            guard_bit      <= 1'b0;
            round_bit      <= 1'b0;
            sticky         <= 1'b0;
            special_case   <= 1'b0;
            special_result <= 32'b0;
        end else begin
            case (counter)
                3'd0: begin
                    a_sign <= a[31];
                    b_sign <= b[31];

                    a_mantissa <= {(a[30:23] != 8'b0), a[22:0]};
                    b_mantissa <= {(b[30:23] != 8'b0), b[22:0]};

                    if (a[30:23] == 8'b0)
                        a_exponent <= -10'sd126;
                    else
                        a_exponent <= {2'b00, a[30:23]} - 10'd127;

                    if (b[30:23] == 8'b0)
                        b_exponent <= -10'sd126;
                    else
                        b_exponent <= {2'b00, b[30:23]} - 10'd127;

                    special_case <= 1'b0;
                    counter      <= 3'd1;
                end

                3'd1: begin
                    z_sign <= a_sign ^ b_sign;

                    if (((a_exponent == 10'd128) &&
                         (a_mantissa[22:0] != 23'b0)) ||
                        ((b_exponent == 10'd128) &&
                         (b_mantissa[22:0] != 23'b0))) begin
                        special_case   <= 1'b1;
                        special_result <= 32'h7fc00000;
                    end else if (((a_exponent == 10'd128) &&
                                  (b_mantissa == 24'b0)) ||
                                 ((b_exponent == 10'd128) &&
                                  (a_mantissa == 24'b0))) begin
                        special_case   <= 1'b1;
                        special_result <= 32'h7fc00000;
                    end else if ((a_exponent == 10'd128) ||
                                 (b_exponent == 10'd128)) begin
                        special_case   <= 1'b1;
                        special_result <= {a_sign ^ b_sign, 8'hff, 23'b0};
                    end else if ((a_mantissa == 24'b0) ||
                                 (b_mantissa == 24'b0)) begin
                        special_case   <= 1'b1;
                        special_result <= {a_sign ^ b_sign, 31'b0};
                    end

                    counter <= 3'd2;
                end

                3'd2: begin
                    a_mantissa <= normalized_a;
                    b_mantissa <= normalized_b;
                    a_exponent <= normalized_a_exp;
                    b_exponent <= normalized_b_exp;
                    counter    <= 3'd3;
                end

                3'd3: begin
                    product    <= {26'b0, a_mantissa} *
                                  {26'b0, b_mantissa};
                    z_exponent <= a_exponent + b_exponent;
                    counter    <= 3'd4;
                end

                3'd4: begin
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
                    if ($signed(z_exponent) < -126) begin
                        z_mantissa <= shifted_mantissa[26:3];
                        guard_bit  <= shifted_mantissa[2];
                        round_bit  <= shifted_mantissa[1];
                        sticky     <= shifted_mantissa[0];
                        z_exponent <= -10'sd126;
                    end
                    counter <= 3'd6;
                end

                3'd6: begin
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
                    end else if ($signed(z_exponent) > 127) begin
                        z <= {z_sign, 8'hff, 23'b0};
                    end else if (z_mantissa == 24'b0) begin
                        z <= {z_sign, 31'b0};
                    end else if (($signed(z_exponent) == -126) &&
                                 !z_mantissa[23]) begin
                        z <= {z_sign, 8'b0, z_mantissa[22:0]};
                    end else begin
                        z[31]    <= z_sign;
                        z[30:23] <= z_exponent + 10'd127;
                        z[22:0]  <= z_mantissa[22:0];
                    end
                    counter <= 3'd0;
                end

                default: counter <= 3'd0;
            endcase
        end
    end

endmodule
