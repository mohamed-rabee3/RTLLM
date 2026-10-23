module float_multi(
    input clk,
    input rst,
    input [31:0] a,
    input [31:0] b,
    output reg [31:0] z
);

    reg [2:0] counter;
    reg [23:0] a_mantissa, b_mantissa, z_mantissa;
    reg [9:0] a_exponent, b_exponent, z_exponent;
    reg a_sign, b_sign, z_sign;
    reg [49:0] product;
    reg guard_bit, round_bit, sticky;

    // Intermediate combinational signals
    reg [31:0] z_result;
    reg [47:0] P48;
    reg [5:0] L;
    reg signed [10:0] eA, eB;
    reg signed [11:0] e_sum;
    reg signed [11:0] exp_unb;
    reg [24:0] M;
    reg [23:0] F;
    reg [5:0] shift_norm;
    reg [7:0] final_exp;
    reg a_nan, b_nan, a_inf, b_inf, a_zero, b_zero;
    reg [47:0] mask48;

    function [5:0] leading_one_48;
        input [47:0] p;
        integer i;
        begin
            leading_one_48 = 0;
            for (i = 0; i < 48; i = i + 1) begin
                if (p[i]) leading_one_48 = i;
            end
        end
    endfunction

    always @* begin
        // Defaults
        z_sign = a_sign ^ b_sign;
        z_exponent = 10'd0;
        z_mantissa = 24'd0;
        P48 = product[47:0];
        L = 6'd0;
        eA = 11'sd0;
        eB = 11'sd0;
        e_sum = 12'sd0;
        exp_unb = 12'sd0;
        M = 25'd0;
        F = 24'd0;
        shift_norm = 6'd0;
        final_exp = 8'd0;
        mask48 = 48'd0;
        guard_bit = 1'b0;
        round_bit = 1'b0;
        sticky = 1'b0;

        a_nan = (a_exponent == 10'd255) && (a_mantissa[22:0] != 23'd0);
        b_nan = (b_exponent == 10'd255) && (b_mantissa[22:0] != 23'd0);
        a_inf = (a_exponent == 10'd255) && (a_mantissa[22:0] == 23'd0);
        b_inf = (b_exponent == 10'd255) && (b_mantissa[22:0] == 23'd0);
        a_zero = (a_exponent == 10'd0) && (a_mantissa[22:0] == 23'd0);
        b_zero = (b_exponent == 10'd0) && (b_mantissa[22:0] == 23'd0);

        if (a_nan || b_nan) begin
            z_sign = 1'b0;
            z_exponent = 10'd255;
            z_mantissa = 24'h400000;
        end else if ((a_inf && b_zero) || (a_zero && b_inf)) begin
            z_sign = 1'b0;
            z_exponent = 10'd255;
            z_mantissa = 24'h400000;
        end else if (a_inf || b_inf) begin
            z_sign = a_sign ^ b_sign;
            z_exponent = 10'd255;
            z_mantissa = 24'd0;
        end else if (a_zero || b_zero) begin
            z_sign = a_sign ^ b_sign;
            z_exponent = 10'd0;
            z_mantissa = 24'd0;
        end else begin
            L = leading_one_48(P48);
            eA = (a_exponent == 0) ? -11'sd126 : $signed({1'b0, a_exponent[7:0]}) - 11'sd127;
            eB = (b_exponent == 0) ? -11'sd126 : $signed({1'b0, b_exponent[7:0]}) - 11'sd127;
            e_sum = eA + eB;
            exp_unb = e_sum + $signed(L) - 12'sd46;

            if (exp_unb >= -126) begin
                // Normal result
                if (L >= 23) begin
                    shift_norm = L - 23;
                    M = P48 >> shift_norm;
                    guard_bit = (shift_norm >= 1) ? P48[shift_norm-1] : 1'b0;
                    round_bit = (shift_norm >= 2) ? P48[shift_norm-2] : 1'b0;
                    if (shift_norm >= 3) begin
                        mask48 = (48'd1 << (shift_norm-2)) - 1;
                        sticky = |(P48 & mask48);
                    end else begin
                        sticky = 1'b0;
                    end
                end else begin
                    M = P48 << (23 - L);
                    guard_bit = 1'b0;
                    round_bit = 1'b0;
                    sticky = 1'b0;
                end

                if (guard_bit && (round_bit || sticky || M[0])) begin
                    M = M + 1;
                end

                if (M[24]) begin
                    M = M >> 1;
                    exp_unb = exp_unb + 1;
                end

                final_exp = exp_unb + 127;
                if (final_exp >= 255) begin
                    z_exponent = 10'd255;
                    z_mantissa = 24'd0;
                end else begin
                    z_exponent = {2'b0, final_exp};
                    z_mantissa = {1'b1, M[22:0]};
                end
            end else begin
                // Subnormal result
                if ((e_sum + 12'sd103) >= 0) begin
                    F = P48 << (e_sum + 12'sd103);
                    guard_bit = 1'b0;
                    round_bit = 1'b0;
                    sticky = 1'b0;
                end else begin
                    if ((-(e_sum + 12'sd103)) > 48) begin
                        F = 24'd0;
                        guard_bit = 1'b0;
                        round_bit = 1'b0;
                        sticky = 1'b0;
                    end else begin
                        shift_norm = -(e_sum + 12'sd103);
                        F = P48 >> shift_norm;
                        guard_bit = (shift_norm >= 1) ? P48[shift_norm-1] : 1'b0;
                        round_bit = (shift_norm >= 2) ? P48[shift_norm-2] : 1'b0;
                        if (shift_norm >= 3) begin
                            mask48 = (48'd1 << (shift_norm-2)) - 1;
                            sticky = |(P48 & mask48);
                        end else begin
                            sticky = 1'b0;
                        end
                        if (guard_bit && (round_bit || sticky || F[0])) begin
                            F = F + 1;
                        end
                    end
                end

                if (F[23]) begin
                    z_exponent = 10'd1;
                    z_mantissa = {1'b1, 23'd0};
                end else begin
                    z_exponent = 10'd0;
                    z_mantissa = {1'b0, F[22:0]};
                end
            end
        end
        z_result = {z_sign, z_exponent[7:0], z_mantissa[22:0]};
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            counter <= 3'd0;
            z <= 32'h0;
            a_sign <= 1'b0;
            b_sign <= 1'b0;
            a_exponent <= 10'd0;
            b_exponent <= 10'd0;
            a_mantissa <= 24'd0;
            b_mantissa <= 24'd0;
            product <= 50'd0;
        end else begin
            case (counter)
                3'd0: begin
                    a_sign <= a[31];
                    b_sign <= b[31];
                    a_exponent <= {2'b0, a[30:23]};
                    b_exponent <= {2'b0, b[30:23]};
                    a_mantissa <= (a[30:23] == 8'd0) ? {1'b0, a[22:0]} : {1'b1, a[22:0]};
                    b_mantissa <= (b[30:23] == 8'd0) ? {1'b0, b[22:0]} : {1'b1, b[22:0]};
                    counter <= 3'd1;
                end
                3'd1: begin
                    product <= a_mantissa * b_mantissa;
                    counter <= 3'd2;
                end
                3'd2: begin
                    z <= z_result;
                    counter <= 3'd3;
                end
                3'd3: begin
                    counter <= 3'd0;
                end
                default: counter <= 3'd0;
            endcase
        end
    end

endmodule
