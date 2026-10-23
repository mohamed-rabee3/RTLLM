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
    reg [31:0] final_result;

    wire a_is_nan;
    wire b_is_nan;
    wire a_is_inf;
    wire b_is_inf;
    wire a_is_zero;
    wire b_is_zero;
    wire [9:0] biased_exponent;

    assign a_is_nan  = (&a[30:23]) && (|a[22:0]);
    assign b_is_nan  = (&b[30:23]) && (|b[22:0]);
    assign a_is_inf  = (&a[30:23]) && !(|a[22:0]);
    assign b_is_inf  = (&b[30:23]) && !(|b[22:0]);
    assign a_is_zero = !(|a[30:0]);
    assign b_is_zero = !(|b[30:0]);

    assign biased_exponent = z_exponent + 10'd127;

    // Exponents use signed two's-complement encoding in 10-bit registers.
    function [33:0] normalize_operand;
        input [23:0] mantissa_in;
        input [9:0]  exponent_in;
        reg [23:0]   mantissa_tmp;
        reg [9:0]    exponent_tmp;
        integer      i;
        begin
            mantissa_tmp = mantissa_in;
            exponent_tmp = exponent_in;

            for (i = 0; i < 23; i = i + 1) begin
                if ((mantissa_tmp != 24'd0) && !mantissa_tmp[23]) begin
                    mantissa_tmp = mantissa_tmp << 1;
                    exponent_tmp = exponent_tmp - 10'd1;
                end
            end

            normalize_operand = {exponent_tmp, mantissa_tmp};
        end
    endfunction

    // Shift right while folding every discarded bit into the sticky bit.
    function [26:0] shift_right_jam;
        input [26:0] value;
        input integer amount;
        reg [26:0] shifted;
        reg discarded;
        integer i;
        begin
            shifted   = value;
            discarded = 1'b0;

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

    // One operation occupies eight clocks. Inputs are sampled at counter 0,
    // and the corresponding result is committed at counter 7.
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
            final_result   <= 32'd0;
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

                    if (a_is_nan || b_is_nan ||
                        (a_is_inf && b_is_zero) ||
                        (b_is_inf && a_is_zero)) begin
                        special_case   <= 1'b1;
                        special_result <= 32'h7fc00000;
                    end else if (a_is_inf || b_is_inf) begin
                        special_case   <= 1'b1;
                        special_result <= {a[31] ^ b[31], 8'hff, 23'd0};
                    end else if (a_is_zero || b_is_zero) begin
                        special_case   <= 1'b1;
                        special_result <= {a[31] ^ b[31], 31'd0};
                    end

                    counter <= 3'd1;
                end

                3'd1: begin
                    {a_exponent, a_mantissa} <=
                        normalize_operand(a_mantissa, a_exponent);
                    {b_exponent, b_mantissa} <=
                        normalize_operand(b_mantissa, b_exponent);
                    counter <= 3'd2;
                end

                3'd2: begin
                    product    <= a_mantissa * b_mantissa;
                    z_exponent <= a_exponent + b_exponent;
                    z_sign     <= a_sign ^ b_sign;
                    counter    <= 3'd3;
                end

                3'd3: begin
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
                    counter <= 3'd4;
                end

                3'd4: begin
                    // Gradual underflow, performed before the single rounding.
                    if ($signed(z_exponent) < -10'sd126) begin
                        {z_mantissa, guard_bit, round_bit, sticky} <=
                            shift_right_jam(
                                {z_mantissa, guard_bit, round_bit, sticky},
                                -126 - $signed(z_exponent)
                            );
                        z_exponent <= -10'sd126;
                    end
                    counter <= 3'd5;
                end

                3'd5: begin
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
                    counter <= 3'd6;
                end

                3'd6: begin
                    if (special_case) begin
                        final_result <= special_result;
                    end else if ($signed(z_exponent) > 10'sd127) begin
                        final_result <= {z_sign, 8'hff, 23'd0};
                    end else if (z_mantissa == 24'd0) begin
                        final_result <= {z_sign, 31'd0};
                    end else if (($signed(z_exponent) == -10'sd126) &&
                                 !z_mantissa[23]) begin
                        final_result <= {z_sign, 8'd0, z_mantissa[22:0]};
                    end else begin
                        final_result <= {
                            z_sign, biased_exponent[7:0], z_mantissa[22:0]
                        };
                    end
                    counter <= 3'd7;
                end

                3'd7: begin
                    z       <= final_result;
                    counter <= 3'd0;
                end

                default: begin
                    counter <= 3'd0;
                end
            endcase
        end
    end

endmodule
