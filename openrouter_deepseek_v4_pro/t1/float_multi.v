module float_multi(
    input clk,
    input rst,
    input [31:0] a,
    input [31:0] b,
    output reg [31:0] z
);
    // Internal signals as specified
    reg [2:0] counter;
    reg [23:0] a_mantissa, b_mantissa, z_mantissa;
    reg [9:0] a_exponent, b_exponent, z_exponent;
    reg a_sign, b_sign, z_sign;
    reg [49:0] product;
    reg guard_bit, round_bit, sticky;

    // Additional internal registers and wires for control
    reg a_nan, a_inf, a_zero;
    reg b_nan, b_inf, b_zero;
    reg out_nan, out_inf, out_zero;
    reg [9:0] exponent_sum;  // biased sum

    // Combinational normalization signals
    reg [5:0] pos_detect;
    reg [23:0] mantissa_pre_comb;
    reg guard_comb, round_comb, sticky_comb;
    reg round_up_comb;
    reg [24:0] mantissa_rounded_comb;
    reg [9:0] exponent_unrounded_comb;
    reg [9:0] exponent_final_comb;

    // Leading-one detector (priority encoder)
    always @(*) begin
        if (product[47]) pos_detect = 6'd47;
        else if (product[46]) pos_detect = 6'd46;
        else if (product[45]) pos_detect = 6'd45;
        else if (product[44]) pos_detect = 6'd44;
        else if (product[43]) pos_detect = 6'd43;
        else if (product[42]) pos_detect = 6'd42;
        else if (product[41]) pos_detect = 6'd41;
        else if (product[40]) pos_detect = 6'd40;
        else if (product[39]) pos_detect = 6'd39;
        else if (product[38]) pos_detect = 6'd38;
        else if (product[37]) pos_detect = 6'd37;
        else if (product[36]) pos_detect = 6'd36;
        else if (product[35]) pos_detect = 6'd35;
        else if (product[34]) pos_detect = 6'd34;
        else if (product[33]) pos_detect = 6'd33;
        else if (product[32]) pos_detect = 6'd32;
        else if (product[31]) pos_detect = 6'd31;
        else if (product[30]) pos_detect = 6'd30;
        else if (product[29]) pos_detect = 6'd29;
        else if (product[28]) pos_detect = 6'd28;
        else if (product[27]) pos_detect = 6'd27;
        else if (product[26]) pos_detect = 6'd26;
        else if (product[25]) pos_detect = 6'd25;
        else if (product[24]) pos_detect = 6'd24;
        else if (product[23]) pos_detect = 6'd23;
        else if (product[22]) pos_detect = 6'd22;
        else if (product[21]) pos_detect = 6'd21;
        else if (product[20]) pos_detect = 6'd20;
        else if (product[19]) pos_detect = 6'd19;
        else if (product[18]) pos_detect = 6'd18;
        else if (product[17]) pos_detect = 6'd17;
        else if (product[16]) pos_detect = 6'd16;
        else if (product[15]) pos_detect = 6'd15;
        else if (product[14]) pos_detect = 6'd14;
        else if (product[13]) pos_detect = 6'd13;
        else if (product[12]) pos_detect = 6'd12;
        else if (product[11]) pos_detect = 6'd11;
        else if (product[10]) pos_detect = 6'd10;
        else if (product[9]) pos_detect = 6'd9;
        else if (product[8]) pos_detect = 6'd8;
        else if (product[7]) pos_detect = 6'd7;
        else if (product[6]) pos_detect = 6'd6;
        else if (product[5]) pos_detect = 6'd5;
        else if (product[4]) pos_detect = 6'd4;
        else if (product[3]) pos_detect = 6'd3;
        else if (product[2]) pos_detect = 6'd2;
        else if (product[1]) pos_detect = 6'd1;
        else if (product[0]) pos_detect = 6'd0;
        else pos_detect = 6'd46; // unused (product=0, handled by out_zero)
    end

    // Combinational mantissa extraction and rounding
    always @(*) begin
        // defaults
        mantissa_pre_comb = 24'd0;
        guard_comb = 1'b0;
        round_comb = 1'b0;
        sticky_comb = 1'b0;
        if (pos_detect >= 23) begin
            mantissa_pre_comb = product[pos_detect -: 24];
            guard_comb = (pos_detect >= 24) ? product[pos_detect-24] : 1'b0;
            round_comb = (pos_detect >= 25) ? product[pos_detect-25] : 1'b0;
            sticky_comb = (pos_detect >= 26) ? |product[pos_detect-26 : 0] : 1'b0;
        end else begin
            mantissa_pre_comb = {product[pos_detect:0], {(23-pos_detect){1'b0}}};
            guard_comb = 1'b0;
            round_comb = 1'b0;
            sticky_comb = 1'b0;
        end
        round_up_comb = guard_comb & (round_comb | sticky_comb | mantissa_pre_comb[0]);
        mantissa_rounded_comb = {1'b0, mantissa_pre_comb} + {24'd0, round_up_comb};

        exponent_unrounded_comb = exponent_sum + $signed({1'b0, pos_detect}) - 10'd46;
        if (mantissa_rounded_comb[24])
            exponent_final_comb = exponent_unrounded_comb + 1;
        else
            exponent_final_comb = exponent_unrounded_comb;
    end

    // Sequential state machine
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            counter <= 3'd0;
            a_mantissa <= 24'd0;
            b_mantissa <= 24'd0;
            a_exponent <= 10'd0;
            b_exponent <= 10'd0;
            a_sign <= 1'b0;
            b_sign <= 1'b0;
            z_mantissa <= 24'd0;
            z_exponent <= 10'd0;
            z_sign <= 1'b0;
            product <= 50'd0;
            guard_bit <= 1'b0;
            round_bit <= 1'b0;
            sticky <= 1'b0;
            a_nan <= 1'b0; a_inf <= 1'b0; a_zero <= 1'b0;
            b_nan <= 1'b0; b_inf <= 1'b0; b_zero <= 1'b0;
            out_nan <= 1'b0; out_inf <= 1'b0; out_zero <= 1'b0;
            exponent_sum <= 10'd0;
            z <= 32'd0;
        end else begin
            // counter update with wrap-around
            if (counter == 3'd3) counter <= 3'd0;
            else counter <= counter + 1;

            case (counter)
                3'd0: begin
                    // ---------- Input Processing ----------
                    a_sign <= a[31];
                    b_sign <= b[31];
                    // Extract exponents (extended to 10 bits)
                    a_exponent <= {2'b00, a[30:23]};
                    b_exponent <= {2'b00, b[30:23]};
                    // Special case flags
                    a_nan  <= (a[30:23] == 8'd255) && (a[22:0] != 23'd0);
                    a_inf  <= (a[30:23] == 8'd255) && (a[22:0] == 23'd0);
                    a_zero <= (a[30:23] == 8'd0)   && (a[22:0] == 23'd0);
                    b_nan  <= (b[30:23] == 8'd255) && (b[22:0] != 23'd0);
                    b_inf  <= (b[30:23] == 8'd255) && (b[22:0] == 23'd0);
                    b_zero <= (b[30:23] == 8'd0)   && (b[22:0] == 23'd0);
                    // Mantissa with hidden bit (handle subnormal)
                    if (a[30:23] == 8'd0) begin
                        a_mantissa <= {1'b0, a[22:0]};
                        a_exponent <= 10'd1;  // biased 1 represents actual -126
                    end else begin
                        a_mantissa <= {1'b1, a[22:0]};
                        a_exponent <= {2'b00, a[30:23]};
                    end
                    if (b[30:23] == 8'd0) begin
                        b_mantissa <= {1'b0, b[22:0]};
                        b_exponent <= 10'd1;
                    end else begin
                        b_mantissa <= {1'b1, b[22:0]};
                        b_exponent <= {2'b00, b[30:23]};
                    end
                end

                3'd1: begin
                    // ---------- Multiply and Special Case Decision ----------
                    z_sign <= a_sign ^ b_sign;
                    if (a_nan || b_nan || (a_inf && b_zero) || (b_inf && a_zero)) begin
                        out_nan  <= 1'b1;
                        out_inf  <= 1'b0;
                        out_zero <= 1'b0;
                    end else if ((a_inf || b_inf) && !(a_zero || b_zero)) begin
                        out_inf  <= 1'b1;
                        out_nan  <= 1'b0;
                        out_zero <= 1'b0;
                    end else if (a_zero || b_zero) begin
                        out_zero <= 1'b1;
                        out_nan  <= 1'b0;
                        out_inf  <= 1'b0;
                    end else begin
                        out_nan  <= 1'b0;
                        out_inf  <= 1'b0;
                        out_zero <= 1'b0;
                        product <= a_mantissa * b_mantissa;   // 48-bit result
                        exponent_sum <= a_exponent + b_exponent - 10'd127;
                    end
                end

                3'd2: begin
                    // ---------- Normalization and Rounding ----------
                    if (!out_nan && !out_inf && !out_zero) begin
                        if (exponent_final_comb >= 10'd255) begin
                            // Overflow to infinity
                            out_inf <= 1'b1;
                            guard_bit <= 1'b0; round_bit <= 1'b0; sticky <= 1'b0;
                        end else if (exponent_final_comb <= 10'd0) begin
                            // Underflow to subnormal / zero
                            integer shift_under;
                            reg [23:0] mant_shifted;
                            shift_under = 1 - exponent_final_comb;
                            if (shift_under >= 24)
                                mant_shifted = 24'd0;
                            else
                                mant_shifted = mantissa_rounded_comb[23:0] >> shift_under;
                            z_mantissa   <= {1'b0, mant_shifted[22:0]};
                            z_exponent   <= 10'd0;
                            guard_bit <= 1'b0; round_bit <= 1'b0; sticky <= 1'b0;
                        end else begin
                            // Normal result
                            z_mantissa   <= mantissa_rounded_comb[23:0];
                            z_exponent   <= exponent_final_comb;
                            guard_bit <= guard_comb;
                            round_bit <= round_comb;
                            sticky    <= sticky_comb;
                        end
                    end else begin
                        guard_bit <= 1'b0; round_bit <= 1'b0; sticky <= 1'b0;
                    end
                end

                3'd3: begin
                    // ---------- Output Assembly ----------
                    if (out_nan)
                        z <= 32'h7FC00000;     // quiet NaN (positive)
                    else if (out_inf)
                        z <= {z_sign, 8'hFF, 23'd0};
                    else if (out_zero)
                        z <= {z_sign, 31'd0};
                    else
                        z <= {z_sign, z_exponent[7:0], z_mantissa[22:0]};
                end
            endcase
        end
    end
endmodule