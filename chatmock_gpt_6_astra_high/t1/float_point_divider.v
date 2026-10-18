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

    wire a_is_nan;
    wire b_is_nan;
    wire a_is_inf;
    wire b_is_inf;
    wire a_is_zero;
    wire b_is_zero;

    wire [7:0]  exp_result;
    wire [7:0]  exp_incremented;
    wire [47:0] mantissa_quotient;

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

    assign exp_result      = exp_a - exp_b + 8'd127;
    assign exp_incremented = exp_result + 8'd1;

    assign mantissa_quotient =
        ({24'd0, man_a} << 23) / {24'd0, man_b};

    always @* begin
        if (a_is_nan || b_is_nan || (a_is_inf && b_is_inf)) begin
            result = 32'h7FC00000;
        end else if (a_is_inf) begin
            result = {sign_result, 8'hFF, 23'd0};
        end else if (b_is_inf) begin
            result = {sign_result, 31'd0};
        end else if (b_is_zero) begin
            result = {sign_result, 8'hFF, 23'd0};
        end else if (a_is_zero) begin
            result = 32'h00000000;
        end else if (mantissa_quotient[47]) begin
            result = {
                sign_result,
                exp_incremented,
                mantissa_quotient[46:24]
            };
        end else begin
            result = {
                sign_result,
                exp_result,
                mantissa_quotient[45:23]
            };
        end
    end

endmodule
