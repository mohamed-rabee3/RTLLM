module fp_divider(
    input [31:0] a,
    input [31:0] b,
    output reg [31:0] result
);

    wire sign_a = a[31];
    wire [7:0] exp_a = a[30:23];
    wire [22:0] frac_a = a[22:0];

    wire sign_b = b[31];
    wire [7:0] exp_b = b[30:23];
    wire [22:0] frac_b = b[22:0];

    wire a_nan = (exp_a == 8'hFF) && (frac_a != 0);
    wire b_nan = (exp_b == 8'hFF) && (frac_b != 0);
    wire a_inf = (exp_a == 8'hFF) && (frac_a == 0);
    wire b_inf = (exp_b == 8'hFF) && (frac_b == 0);
    wire a_zero = (exp_a == 8'h00) && (frac_a == 0);
    wire b_zero = (exp_b == 8'h00) && (frac_b == 0);

    wire sign = sign_a ^ sign_b;

    wire [23:0] man_a = {1'b1, frac_a};
    wire [23:0] man_b = {1'b1, frac_b};

    wire [23:0] q = (man_a << 23) / man_b;

    wire [7:0] exp_base = exp_a - exp_b + 8'd127;
    wire [7:0] exp_norm;
    wire [22:0] frac_norm;

    assign exp_norm = q[23] ? exp_base : (exp_base - 8'd1);
    assign frac_norm = q[23] ? q[22:0] : ((q << 1) & 23'h7FFFFF);

    always @(*) begin
        if (a_nan || b_nan || (a_inf && b_inf)) begin
            result = 32'h7FC00000;
        end else if (a_inf) begin
            result = {sign, 8'hFF, 23'b0};
        end else if (b_inf) begin
            result = {sign, 8'h00, 23'b0};
        end else if (b_zero) begin
            result = {sign, 8'hFF, 23'b0};
        end else if (a_zero) begin
            result = 32'h00000000;
        end else begin
            result = {sign, exp_norm, frac_norm};
        end
    end

endmodule
