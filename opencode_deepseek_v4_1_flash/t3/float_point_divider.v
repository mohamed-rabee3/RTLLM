module fp_divider(
    input [31:0] a,
    input [31:0] b,
    output [31:0] result
);

wire sign_a = a[31];
wire [7:0] exp_a = a[30:23];
wire [22:0] frac_a = a[22:0];
wire sign_b = b[31];
wire [7:0] exp_b = b[30:23];
wire [22:0] frac_b = b[22:0];

wire [23:0] man_a = {1'b1, frac_a};
wire [23:0] man_b = {1'b1, frac_b};

wire a_nan = (exp_a == 8'hFF) && (frac_a != 0);
wire b_nan = (exp_b == 8'hFF) && (frac_b != 0);
wire a_inf = (exp_a == 8'hFF) && (frac_a == 0);
wire b_inf = (exp_b == 8'hFF) && (frac_b == 0);
wire a_zero = (exp_a == 8'h00) && (frac_a == 0);
wire b_zero = (exp_b == 8'h00) && (frac_b == 0);

wire sign_res = sign_a ^ sign_b;

reg [31:0] special_result;
always @(*) begin
    if (a_nan || b_nan || (a_inf && b_inf)) begin
        special_result = 32'h7FC00000;
    end else if (a_inf) begin
        special_result = sign_res ? 32'hFF800000 : 32'h7F800000;
    end else if (b_inf) begin
        special_result = sign_res ? 32'h80000000 : 32'h00000000;
    end else if (b_zero) begin
        special_result = sign_res ? 32'hFF800000 : 32'h7F800000;
    end else if (a_zero) begin
        special_result = 32'h00000000;
    end else begin
        special_result = 32'h0;
    end
end

wire [47:0] num = {man_a, 23'b0};
wire [47:0] quot = num / man_b;

wire [7:0] exp_base = exp_a - exp_b + 8'd127;
wire [7:0] exp_norm;
wire [22:0] frac_norm;

always @(*) begin
    if (quot[23]) begin
        exp_norm = exp_base;
        frac_norm = quot[22:0];
    end else begin
        exp_norm = exp_base - 8'd1;
        frac_norm = (quot << 1) & 23'h7FFFFF;
    end
end

wire [31:0] normal_result = {sign_res, exp_norm, frac_norm};

wire is_special = a_nan || b_nan || (a_inf && b_inf) || a_inf || b_inf || b_zero || a_zero;
assign result = is_special ? special_result : normal_result;

endmodule
