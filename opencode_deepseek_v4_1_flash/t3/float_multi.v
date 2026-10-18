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

    reg [7:0] exp_a, exp_b;
    reg [22:0] frac_a, frac_b;
    reg is_nan_a, is_nan_b, is_inf_a, is_inf_b, is_zero_a, is_zero_b;
    reg [23:0] ma, mb;
    reg [9:0] ea, eb, sum_exp;
    reg [49:0] P;
    integer L, i;
    reg signed [11:0] Eout;
    reg [23:0] M, F;
    reg [31:0] result;
    integer shift;
    reg [49:0] quotient;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            counter <= 3'd0;
            z <= 32'd0;
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
            result = 32'd0;

            a_sign = a[31];
            b_sign = b[31];
            exp_a = a[30:23];
            exp_b = b[30:23];
            frac_a = a[22:0];
            frac_b = b[22:0];

            is_nan_a = (exp_a == 8'hFF) && (frac_a != 23'd0);
            is_nan_b = (exp_b == 8'hFF) && (frac_b != 23'd0);
            is_inf_a = (exp_a == 8'hFF) && (frac_a == 23'd0);
            is_inf_b = (exp_b == 8'hFF) && (frac_b == 23'd0);
            is_zero_a = (exp_a == 8'h00) && (frac_a == 23'd0);
            is_zero_b = (exp_b == 8'h00) && (frac_b == 23'd0);

            z_sign = a_sign ^ b_sign;

            if (is_nan_a || is_nan_b || (is_inf_a && is_zero_b) || (is_inf_b && is_zero_a)) begin
                result = 32'h7fc00000;
            end else if (is_inf_a || is_inf_b) begin
                result = {z_sign, 8'hFF, 23'd0};
            end else if (is_zero_a || is_zero_b) begin
                result = {z_sign, 8'h00, 23'd0};
            end else begin
                ma = (exp_a == 8'h00) ? {1'b0, frac_a} : {1'b1, frac_a};
                mb = (exp_b == 8'h00) ? {1'b0, frac_b} : {1'b1, frac_b};
                ea = (exp_a == 8'h00) ? 10'd1 : {2'b0, exp_a};
                eb = (exp_b == 8'h00) ? 10'd1 : {2'b0, exp_b};

                a_mantissa = ma;
                b_mantissa = mb;
                a_exponent = ea;
                b_exponent = eb;

                P = ma * mb;
                product = P;
                sum_exp = ea + eb;

                L = 0;
                for (i = 0; i < 50; i = i + 1) begin
                    if (P[i]) L = i;
                end

                Eout = $signed({1'b0, sum_exp}) + L - 173;

                if (Eout >= 255) begin
                    result = {z_sign, 8'hFF, 23'd0};
                end else if (Eout >= 1) begin
                    shift = L - 23;
                    M = P >> shift;
                    if (shift > 0) begin
                        guard_bit = P[shift-1];
                        if (shift > 1)
                            sticky = |(P & ((50'd1 << (shift-1)) - 1));
                        else
                            sticky = 1'b0;
                        round_bit = guard_bit;
                        if (guard_bit && (sticky || M[0])) begin
                            if (M == 24'hFFFFFF) begin
                                M = 24'h800000;
                                Eout = Eout + 1;
                            end else begin
                                M = M + 1'b1;
                            end
                        end
                    end
                    if (Eout >= 255) begin
                        result = {z_sign, 8'hFF, 23'd0};
                    end else begin
                        z_mantissa = M;
                        z_exponent = Eout[9:0];
                        result = {z_sign, Eout[7:0], M[22:0]};
                    end
                end else begin
                    if (sum_exp >= 151) begin
                        F = P << (sum_exp - 151);
                    end else begin
                        shift = 151 - sum_exp;
                        if (shift > 49) begin
                            F = 24'd0;
                        end else begin
                            quotient = P >> shift;
                            guard_bit = P[shift-1];
                            if (shift > 1)
                                sticky = |(P & ((50'd1 << (shift-1)) - 1));
                            else
                                sticky = 1'b0;
                            round_bit = guard_bit;
                            if (guard_bit && (sticky || quotient[0])) begin
                                quotient = quotient + 1'b1;
                            end
                            F = quotient[23:0];
                        end
                    end
                    if (F >= 24'h800000) begin
                        result = {z_sign, 8'h01, F[22:0]};
                    end else if (F == 24'd0) begin
                        result = {z_sign, 8'h00, 23'd0};
                    end else begin
                        result = {z_sign, 8'h00, F[22:0]};
                    end
                end
            end
            z <= result;
        end
    end

endmodule
