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

    integer E_a, E_b, Esum, exp, shift, k;
    reg [23:0] M_a, M_b;
    reg [47:0] P48;
    reg [24:0] S, F;
    reg [23:0] S0, F0;
    reg [7:0] e_out;
    reg [22:0] frac_out;
    reg sign_z;
    reg [31:0] result;
    reg round_up;

    function [4:0] find_lead;
        input [22:0] frac;
        integer j;
        begin
            find_lead = 5'd0;
            for (j = 0; j < 23; j = j + 1) begin
                if (frac[j]) find_lead = j;
            end
        end
    endfunction

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            z <= 32'd0;
            counter <= 3'd0;
            a_mantissa <= 24'd0;
            b_mantissa <= 24'd0;
            z_mantissa <= 24'd0;
            a_exponent <= 10'd0;
            b_exponent <= 10'd0;
            z_exponent <= 10'd0;
            a_sign <= 1'b0;
            b_sign <= 1'b0;
            z_sign <= 1'b0;
            product <= 50'd0;
            guard_bit <= 1'b0;
            round_bit <= 1'b0;
            sticky <= 1'b0;
        end else begin
            counter <= counter + 1'b1;

            sign_z = a[31] ^ b[31];

            if ((a[30:23] == 8'hFF && a[22:0] != 0) ||
                (b[30:23] == 8'hFF && b[22:0] != 0)) begin
                result = 32'h7fc00000;
            end else if ((a[30:23] == 8'hFF && a[22:0] == 0 && b[30:23] == 0 && b[22:0] == 0) ||
                         (b[30:23] == 8'hFF && b[22:0] == 0 && a[30:23] == 0 && a[22:0] == 0)) begin
                result = 32'h7fc00000;
            end else if ((a[30:23] == 8'hFF && a[22:0] == 0) ||
                         (b[30:23] == 8'hFF && b[22:0] == 0)) begin
                result = {sign_z, 8'hFF, 23'd0};
            end else if ((a[30:23] == 8'h00 && a[22:0] == 0) ||
                         (b[30:23] == 8'h00 && b[22:0] == 0)) begin
                result = {sign_z, 31'd0};
            end else begin
                if (a[30:23] == 8'h00) begin
                    k = find_lead(a[22:0]);
                    M_a = (24'd0 | a[22:0]) << (23 - k);
                    E_a = k - 172;
                end else begin
                    M_a = {1'b1, a[22:0]};
                    E_a = a[30:23];
                    E_a = E_a - 150;
                end

                if (b[30:23] == 8'h00) begin
                    k = find_lead(b[22:0]);
                    M_b = (24'd0 | b[22:0]) << (23 - k);
                    E_b = k - 172;
                end else begin
                    M_b = {1'b1, b[22:0]};
                    E_b = b[30:23];
                    E_b = E_b - 150;
                end

                a_mantissa <= M_a;
                b_mantissa <= M_b;
                a_exponent <= E_a;
                b_exponent <= E_b;
                a_sign <= a[31];
                b_sign <= b[31];

                P48 = M_a * M_b;
                product <= P48;
                Esum = E_a + E_b;

                if (P48[47]) exp = Esum + 47;
                else exp = Esum + 46;

                if (exp > 127) begin
                    result = {sign_z, 8'hFF, 23'd0};
                end else if (exp < -126) begin
                    shift = -(Esum + 149);
                    if (shift > 48) begin
                        F0 = 24'd0;
                        guard_bit = 1'b0;
                        round_bit = 1'b0;
                        sticky = |P48;
                    end else if (shift == 48) begin
                        F0 = 24'd0;
                        guard_bit = P48[47];
                        round_bit = P48[46];
                        sticky = |P48[45:0];
                    end else if (shift > 0) begin
                        F0 = P48 >> shift;
                        guard_bit = P48[shift-1];
                        if (shift >= 2) round_bit = P48[shift-2]; else round_bit = 1'b0;
                        if (shift >= 3) sticky = |(P48 & ((48'd1 << (shift-2)) - 48'd1)); else sticky = 1'b0;
                    end else begin
                        F0 = P48 << (-shift);
                        guard_bit = 1'b0;
                        round_bit = 1'b0;
                        sticky = 1'b0;
                    end
                    round_up = guard_bit && (round_bit || sticky || F0[0]);
                    F = {1'b0, F0} + round_up;
                    if (F[23]) begin
                        result = {sign_z, 8'd1, 23'd0};
                    end else if (F == 0) begin
                        result = {sign_z, 31'd0};
                    end else begin
                        result = {sign_z, 8'd0, F[22:0]};
                    end
                end else begin
                    if (P48[47]) shift = 24;
                    else shift = 23;
                    S0 = P48 >> shift;
                    guard_bit = P48[shift-1];
                    round_bit = P48[shift-2];
                    sticky = |(P48 & ((48'd1 << (shift-2)) - 48'd1));
                    round_up = guard_bit && (round_bit || sticky || S0[0]);
                    S = {1'b0, S0} + round_up;
                    if (S[24]) begin
                        S[23:0] = 24'h800000;
                        exp = exp + 1;
                    end
                    if (exp > 127) begin
                        result = {sign_z, 8'hFF, 23'd0};
                    end else begin
                        e_out = exp + 127;
                        frac_out = S[22:0];
                        result = {sign_z, e_out, frac_out};
                    end
                end
            end

            z <= result;
            z_mantissa <= result[22:0];
            z_exponent <= {2'b0, result[30:23]};
            z_sign <= result[31];
        end
    end

endmodule
