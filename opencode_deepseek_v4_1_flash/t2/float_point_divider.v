module fp_divider(
    input [31:0] a,
    input [31:0] b,
    output reg [31:0] result
);

    wire sign_a = a[31];
    wire sign_b = b[31];
    wire [7:0] exp_a = a[30:23];
    wire [7:0] exp_b = b[30:23];
    wire [22:0] frac_a = a[22:0];
    wire [22:0] frac_b = b[22:0];

    wire is_nan_a = (exp_a == 8'hFF) && (frac_a != 23'd0);
    wire is_nan_b = (exp_b == 8'hFF) && (frac_b != 23'd0);
    wire is_inf_a = (exp_a == 8'hFF) && (frac_a == 23'd0);
    wire is_inf_b = (exp_b == 8'hFF) && (frac_b == 23'd0);
    wire is_zero_a = (exp_a == 8'd0) && (frac_a == 23'd0);
    wire is_zero_b = (exp_b == 8'd0) && (frac_b == 23'd0);

    wire sign = sign_a ^ sign_b;

    wire [23:0] man_a = {1'b1, frac_a};
    wire [23:0] man_b = {1'b1, frac_b};

    wire [47:0] numerator = {1'b0, man_a, 23'b0};
    wire [47:0] quotient = numerator / man_b;

    wire [7:0] base_exp = exp_a - exp_b + 8'd127;
    wire q_msb = quotient[23];
    wire [7:0] exp_norm = q_msb ? base_exp : (base_exp - 8'd1);
    wire [23:0] q_shifted = quotient[23:0] << 1;
    wire [22:0] frac_norm = q_msb ? quotient[22:0] : q_shifted[22:0];

    always @(*) begin
        if (is_nan_a || is_nan_b || (is_inf_a && is_inf_b)) begin
            result = 32'h7FC00000;
        end else if (is_inf_a) begin
            result = {sign, 8'hFF, 23'b0};
        end else if (is_inf_b) begin
            result = {sign, 8'h00, 23'b0};
        end else if (is_zero_b) begin
            result = {sign, 8'hFF, 23'b0};
        end else if (is_zero_a) begin
            result = 32'h00000000;
        end else begin
            result = {sign, exp_norm, frac_norm};
        end
    end

endmodule
