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

    wire is_nan_a = (exp_a == 8'hFF) && (frac_a != 0);
    wire is_nan_b = (exp_b == 8'hFF) && (frac_b != 0);
    wire is_inf_a = (exp_a == 8'hFF) && (frac_a == 0);
    wire is_inf_b = (exp_b == 8'hFF) && (frac_b == 0);
    wire is_zero_a = (exp_a == 0) && (frac_a == 0);
    wire is_zero_b = (exp_b == 0) && (frac_b == 0);

    wire [23:0] man_a = {1'b1, frac_a};
    wire [23:0] man_b = {1'b1, frac_b};

    wire [47:0] numerator = {24'b0, man_a} << 23;
    wire [47:0] quotient = numerator / man_b;
    wire [23:0] q = quotient[23:0];

    wire [7:0] exp_res;
    wire [22:0] frac_res;

    assign exp_res = (q[23]) ? (exp_a - exp_b + 8'd127) : (exp_a - exp_b + 8'd126);
    assign frac_res = (q[23]) ? q[22:0] : {q[21:0], 1'b0};

    always @(*) begin
        if (is_nan_a || is_nan_b || (is_inf_a && is_inf_b)) begin
            result = 32'h7FC00000;
        end else if (is_inf_a) begin
            result = {sign_a ^ sign_b, 8'hFF, 23'b0};
        end else if (is_inf_b) begin
            result = {sign_a ^ sign_b, 8'h00, 23'b0};
        end else if (is_zero_b) begin
            result = {sign_a ^ sign_b, 8'hFF, 23'b0};
        end else if (is_zero_a) begin
            result = 32'h00000000;
        end else begin
            result = {sign_a ^ sign_b, exp_res, frac_res};
        end
    end

endmodule
