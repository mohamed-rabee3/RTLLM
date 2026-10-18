module fp_divider (
    input  wire [31:0] a,
    input  wire [31:0] b,
    output reg  [31:0] result
);

    wire        sign_a;
    wire        sign_b;
    wire        sign_result;
    wire [7:0]  exp_a;
    wire [7:0]  exp_b;
    wire [22:0] frac_a;
    wire [22:0] frac_b;
    wire [23:0] man_a;
    wire [23:0] man_b;

    wire        a_is_nan;
    wire        b_is_nan;
    wire        a_is_inf;
    wire        b_is_inf;
    wire        a_is_zero;
    wire        b_is_zero;

    wire [47:0] scaled_man_a;
    wire [47:0] quotient;
    wire [7:0]  base_exp;
    wire [7:0]  normalized_exp;
    wire [22:0] normalized_frac;

    assign sign_a      = a[31];
    assign sign_b      = b[31];
    assign sign_result = sign_a ^ sign_b;

    assign exp_a  = a[30:23];
    assign exp_b  = b[30:23];
    assign frac_a = a[22:0];
    assign frac_b = b[22:0];

    assign man_a = {1'b1, frac_a};
    assign man_b = {1'b1, frac_b};

    assign a_is_nan  = (exp_a == 8'hFF) && (frac_a != 23'd0);
    assign b_is_nan  = (exp_b == 8'hFF) && (frac_b != 23'd0);
    assign a_is_inf  = (exp_a == 8'hFF) && (frac_a == 23'd0);
    assign b_is_inf  = (exp_b == 8'hFF) && (frac_b == 23'd0);
    assign a_is_zero = (exp_a == 8'd0)  && (frac_a == 23'd0);
    assign b_is_zero = (exp_b == 8'd0)  && (frac_b == 23'd0);

    assign scaled_man_a = {1'b0, man_a, 23'd0};
    assign quotient     = scaled_man_a / {24'd0, man_b};
    assign base_exp     = exp_a - exp_b + 8'd127;

    assign normalized_exp = quotient[47] ? (base_exp + 8'd1)
                                         : base_exp;
    assign normalized_frac = quotient[47] ? quotient[46:24]
                                          : quotient[45:23];

    always @* begin
        if (a_is_nan || b_is_nan || (a_is_inf && b_is_inf))
            result = 32'h7FC00000;
        else if (a_is_inf)
            result = {sign_result, 8'hFF, 23'd0};
        else if (b_is_inf)
            result = {sign_result, 31'd0};
        else if (b_is_zero)
            result = {sign_result, 8'hFF, 23'd0};
        else if (a_is_zero)
            result = 32'h00000000;
        else
            result = {sign_result, normalized_exp, normalized_frac};
    end

endmodule
