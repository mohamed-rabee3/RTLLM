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

    // Function to compute IEEE-754 single precision multiplication
    function [31:0] fp_mul;
        input [31:0] a;
        input [31:0] b;
        reg sign;
        reg [7:0] exp_a, exp_b;
        reg [22:0] frac_a, frac_b;
        reg [23:0] sig_a, sig_b;
        integer e_a, e_b, exp_prod;
        reg [49:0] P;
        integer msb, shift, i;
        reg [23:0] truncated;
        reg [24:0] M_round;
        reg guard, sticky_bit, round_up;
        integer exp_out_int;
        reg [31:0] result;
        reg is_nan_a, is_nan_b, is_inf_a, is_inf_b, is_zero_a, is_zero_b;
        begin
            result = 32'h0;
            sign = a[31] ^ b[31];
            exp_a = a[30:23];
            exp_b = b[30:23];
            frac_a = a[22:0];
            frac_b = b[22:0];

            is_nan_a = (exp_a == 8'hFF) && (frac_a != 0);
            is_nan_b = (exp_b == 8'hFF) && (frac_b != 0);
            is_inf_a = (exp_a == 8'hFF) && (frac_a == 0);
            is_inf_b = (exp_b == 8'hFF) && (frac_b == 0);
            is_zero_a = (exp_a == 0) && (frac_a == 0);
            is_zero_b = (exp_b == 0) && (frac_b == 0);

            if (is_nan_a || is_nan_b) begin
                result = 32'h7FC00000;
            end else if (is_inf_a || is_inf_b) begin
                if ((is_inf_a && is_zero_b) || (is_inf_b && is_zero_a)) begin
                    result = 32'h7FC00000;
                end else begin
                    result = {sign, 8'hFF, 23'h0};
                end
            end else if (is_zero_a || is_zero_b) begin
                result = {sign, 31'h0};
            end else begin
                sig_a = (exp_a == 0) ? {1'b0, frac_a} : {1'b1, frac_a};
                sig_b = (exp_b == 0) ? {1'b0, frac_b} : {1'b1, frac_b};
                e_a = (exp_a == 0) ? 1 : exp_a;
                e_b = (exp_b == 0) ? 1 : exp_b;
                P = sig_a * sig_b;

                if (P == 0) begin
                    result = {sign, 31'h0};
                end else begin
                    msb = 0;
                    for (i = 0; i < 50; i = i + 1) begin
                        if (P[i]) msb = i;
                    end

                    exp_prod = e_a + e_b - 300;
                    exp_out_int = exp_prod + msb + 127;

                    if (exp_out_int >= 255) begin
                        result = {sign, 8'hFF, 23'h0};
                    end else if (exp_out_int > 0) begin
                        shift = msb - 23;
                        if (shift <= 0) begin
                            truncated = P << (-shift);
                            guard = 0;
                            sticky_bit = 0;
                        end else begin
                            truncated = P >> shift;
                            guard = (shift <= 50) ? P[shift-1] : 0;
                            sticky_bit = 0;
                            for (i = 0; i < 50; i = i + 1) begin
                                if (i < shift - 1) sticky_bit = sticky_bit | P[i];
                            end
                        end
                        round_up = guard && (sticky_bit || truncated[0]);
                        M_round = {1'b0, truncated} + round_up;
                        if (M_round[24]) begin
                            M_round = 25'h800000;
                            exp_out_int = exp_out_int + 1;
                        end
                        if (exp_out_int >= 255) begin
                            result = {sign, 8'hFF, 23'h0};
                        end else begin
                            result = {sign, exp_out_int[7:0], M_round[22:0]};
                        end
                    end else begin
                        shift = -exp_prod - 149;
                        if (shift > 0) begin
                            truncated = P >> shift;
                            guard = (shift <= 50) ? P[shift-1] : 0;
                            sticky_bit = 0;
                            for (i = 0; i < 50; i = i + 1) begin
                                if (i < shift - 1) sticky_bit = sticky_bit | P[i];
                            end
                            round_up = guard && (sticky_bit || truncated[0]);
                            M_round = {1'b0, truncated} + round_up;
                        end else if (shift == 0) begin
                            M_round = {1'b0, P[23:0]};
                        end else begin
                            M_round = P << (-shift);
                        end
                        if (M_round >= 25'h800000) begin
                            result = {sign, 8'h01, 23'h0};
                        end else if (M_round == 0) begin
                            result = {sign, 31'h0};
                        end else begin
                            result = {sign, 8'h00, M_round[22:0]};
                        end
                    end
                end
            end
            fp_mul = result;
        end
    endfunction

    // Sequential logic with counter for operation sequencing
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            counter <= 3'd0;
            z <= 32'h0;
            a_mantissa <= 24'h0;
            b_mantissa <= 24'h0;
            z_mantissa <= 24'h0;
            a_exponent <= 10'h0;
            b_exponent <= 10'h0;
            z_exponent <= 10'h0;
            a_sign <= 1'b0;
            b_sign <= 1'b0;
            z_sign <= 1'b0;
            product <= 50'h0;
            guard_bit <= 1'b0;
            round_bit <= 1'b0;
            sticky <= 1'b0;
        end else begin
            case (counter)
                3'd0: begin
                    a_sign <= a[31];
                    b_sign <= b[31];
                    a_exponent <= {2'b0, a[30:23]};
                    b_exponent <= {2'b0, b[30:23]};
                    a_mantissa <= (a[30:23] == 0) ? {1'b0, a[22:0]} : {1'b1, a[22:0]};
                    b_mantissa <= (b[30:23] == 0) ? {1'b0, b[22:0]} : {1'b1, b[22:0]};
                    z <= fp_mul(a, b);
                    counter <= 3'd1;
                end
                3'd1: begin
                    product <= a_mantissa * b_mantissa;
                    counter <= 3'd2;
                end
                3'd2: begin
                    z_mantissa <= {1'b0, z[22:0]};
                    z_exponent <= {2'b0, z[30:23]};
                    z_sign <= z[31];
                    guard_bit <= 1'b0;
                    round_bit <= 1'b0;
                    sticky <= 1'b0;
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
