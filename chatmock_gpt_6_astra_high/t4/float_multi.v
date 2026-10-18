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

    wire a_is_nan;
    wire b_is_nan;
    wire a_is_inf;
    wire b_is_inf;
    wire a_is_zero;
    wire b_is_zero;

    wire        round_up;
    wire [24:0] rounded_mantissa;
    wire [9:0]  biased_exponent;

    assign a_is_nan  = (&a[30:23]) && (|a[22:0]);
    assign b_is_nan  = (&b[30:23]) && (|b[22:0]);
    assign a_is_inf  = (&a[30:23]) && !(|a[22:0]);
    assign b_is_inf  = (&b[30:23]) && !(|b[22:0]);
    assign a_is_zero = !(|a[30:0]);
    assign b_is_zero = !(|b[30:0]);

    // Round to nearest, with ties rounded to an even mantissa.
    assign round_up = guard_bit &&
                      (round_bit || sticky || z_mantissa[0]);

    assign rounded_mantissa = {1'b0, z_mantissa} +
                              (round_up ? 25'd1 : 25'd0);

    assign biased_exponent = z_exponent + 10'd127;

    // Exponents are stored as signed, two's-complement unbiased values.
    function [33:0] normalize_operand;
        input [23:0] mantissa_in;
        input [9:0]  exponent_in;
        reg   [23:0] mantissa_work;
        reg   [9:0]  exponent_work;
        integer i;
        begin
            mantissa_work = mantissa_in;
            exponent_work = exponent_in;

            for (i = 0; i < 23; i = i + 1) begin
                if ((mantissa_work != 24'd0) &&
                    !mantissa_work[23]) begin
                    mantissa_work = mantissa_work << 1;
                    exponent_work = exponent_work - 10'd1;
                end
            end

            normalize_operand = {exponent_work, mantissa_work};
        end
    endfunction

    // Preserve all discarded information in the least significant bit.
    function [49:0] shift_right_jam;
        input [49:0] value;
        input integer shift_amount;
        reg lost_bits;
        integer i;
        begin
            lost_bits = 1'b0;

            for (i = 0; i < 50; i = i + 1) begin
                if (i < shift_amount)
                    lost_bits = lost_bits | value[i];
            end

            if (shift_amount <= 0)
                shift_right_jam = value;
            else if (shift_amount >= 50)
                shift_right_jam = {49'd0, |value};
            else
                shift_right_jam = (value >> shift_amount) |
                                  {49'd0, lost_bits};
        end
    endfunction

    // Operands are sampled at counter == 0; the result is committed
    // at counter == 7. A new operation starts every eight clocks.
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

                    if (a_is_nan || b_is_nan ||
                        (a_is_inf && b_is_zero) ||
                        (b_is_inf && a_is_zero)) begin
                        special_case   <= 1'b1;
                        special_result <= 32'h7fc00000;
                    end else if (a_is_inf || b_is_inf) begin
                        special_case   <= 1'b1;
                        special_result <= {a[31] ^ b[31],
                                           8'hff, 23'd0};
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
                    product <= {26'd0, a_mantissa} *
                               {26'd0, b_mantissa};
                    z_exponent <= a_exponent + b_exponent;
                    z_sign     <= a_sign ^ b_sign;

                    counter <= 3'd3;
                end

                3'd3: begin
                    // Place the normalized leading bit at product[47].
                    if (product[47])
                        z_exponent <= z_exponent + 10'd1;
                    else
                        product <= product << 1;

                    counter <= 3'd4;
                end

                3'd4: begin
                    // Gradual underflow, retaining rounding information.
                    if ($signed(z_exponent) < -10'sd126) begin
                        product <= shift_right_jam(
                            product, -126 - $signed(z_exponent));
                        z_exponent <= -10'sd126;
                    end

                    counter <= 3'd5;
                end

                3'd5: begin
                    z_mantissa <= product[47:24];
                    guard_bit  <= product[23];
                    round_bit  <= product[22];
                    sticky     <= |product[21:0];

                    counter <= 3'd6;
                end

                3'd6: begin
                    if (rounded_mantissa[24]) begin
                        z_mantissa <= rounded_mantissa[24:1];
                        z_exponent <= z_exponent + 10'd1;
                    end else begin
                        z_mantissa <= rounded_mantissa[23:0];
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
