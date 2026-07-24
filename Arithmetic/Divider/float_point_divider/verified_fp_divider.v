module verified_fp_divider(
    input      [31:0] a,
    input      [31:0] b,
    output reg [31:0] result
);
    reg sign_a, sign_b, sign_r;
    reg [7:0]  exp_a, exp_b, exp_r;
    reg [23:0] man_a, man_b;
    reg [47:0] man_div;
    reg [22:0] mantissa;
    reg a_zero, b_zero, a_inf, b_inf, a_nan, b_nan;

    always @* begin
        sign_a = a[31];
        sign_b = b[31];
        exp_a  = a[30:23];
        exp_b  = b[30:23];
        man_a  = {1'b1, a[22:0]};
        man_b  = {1'b1, b[22:0]};

        a_zero = (exp_a == 0   && a[22:0] == 0);
        b_zero = (exp_b == 0   && b[22:0] == 0);
        a_inf  = (exp_a == 255 && a[22:0] == 0);
        b_inf  = (exp_b == 255 && b[22:0] == 0);
        a_nan  = (exp_a == 255 && a[22:0] != 0);
        b_nan  = (exp_b == 255 && b[22:0] != 0);

        if (a_nan || b_nan)        result = 32'h7FC00000;
        else if (a_inf && b_inf)   result = 32'h7FC00000;
        else if (a_inf)            result = {sign_a ^ sign_b, 8'hFF, 23'b0};
        else if (b_inf)            result = {sign_a ^ sign_b, 8'h00, 23'b0};
        else if (b_zero)           result = {sign_a ^ sign_b, 8'hFF, 23'b0};
        else if (a_zero)           result = 32'h00000000;
        else begin
            sign_r  = sign_a ^ sign_b;
            exp_r   = exp_a - exp_b + 127;
            man_div = (man_a << 23) / man_b;
            if (man_div[47]) begin
                mantissa = man_div[46:24];
                exp_r    = exp_r + 1;
            end else begin
                mantissa = man_div[45:23];
            end
            result = {sign_r, exp_r, mantissa};
        end
    end
endmodule
