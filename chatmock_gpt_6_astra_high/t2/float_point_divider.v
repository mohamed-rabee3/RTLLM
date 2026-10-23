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

    reg [7:0]  exp_result;
    reg [47:0] mantissa_quotient;

    assign sign_a      = a[31];
    assign sign_b      = b[31];
    assign sign_result = sign_a ^ sign_b;
    assign exp_a       = a[30:23];
    assign exp_b       = b[30:23];
    assign frac_a      = a[22:0];
    assign frac_b      = b[22:0];
    assign man_a       = {1'b1, frac_a};
    assign man_b       = {1'b1, frac_b};

    assign a_is_nan  = (exp_a == 8'hFF) && (frac_a != 23'b0);
    assign b_is_nan  = (exp_b == 8'hFF) && (frac_b != 23'b0);
    assign a_is_inf  = (exp_a == 8'hFF) && (frac_a == 23'b0);
    assign b_is_inf  = (exp_b == 8'hFF) && (frac_b == 23'b0);
    assign a_is_zero = (a[30:0] == 31'b0);
    assign b_is_zero = (b[30:0] == 31'b0);

    always @* begin
        result            = 32'b0;
        exp_result        = 8'b0;
        mantissa_quotient = 48'b0;

        if (a_is_nan || b_is_nan || (a_is_inf && b_is_inf)) begin
            result = 32'h7FC00000;
        end else if (a_is_inf) begin
            result = {sign_result, 8'hFF, 23'b0};
        end else if (b_is_inf) begin
            result = {sign_result, 31'b0};
        end else if (b_is_zero) begin
            result = {sign_result, 8'hFF, 23'b0};
        end else if (a_is_zero) begin
            result = 32'h00000000;
        end else begin
            exp_result = exp_a - exp_b + 8'd127;
            mantissa_quotient =
                ({24'b0, man_a} << 23) / {24'b0, man_b};

            if (mantissa_quotient[47]) begin
                exp_result = exp_result + 8'd1;
                result = {sign_result, exp_result,
                          mantissa_quotient[46:24]};
            end else begin
                result = {sign_result, exp_result,
                          mantissa_quotient[45:23]};
            end
        end
    end

endmodule
