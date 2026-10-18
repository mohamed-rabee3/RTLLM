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

    // Internal computation signals
    reg [31:0] next_z;
    reg sign;
    reg [7:0] exp_a, exp_b;
    reg [22:0] frac_a, frac_b;
    reg [23:0] M_a, M_b;
    reg signed [10:0] E_a, E_b, E_sum;
    reg [47:0] P;
    reg [5:0] L;
    reg signed [10:0] exp_field;
    reg [8:0] shift;
    reg [24:0] M_round;
    reg [7:0] exp_out;
    reg [22:0] frac_out;
    reg is_nan, is_inf, is_zero;

    // Loop variables
    integer i, i2;
    reg [4:0] shift_a, shift_b;

    // Rounding function
    function [24:0] round_product;
        input [47:0] P_in;
        input [8:0] shift_in;
        reg guard, round, sticky;
        reg [24:0] M;
        integer j;
        begin
            M = P_in >> shift_in;
            guard = 0;
            round = 0;
            sticky = 0;
            if (shift_in > 0 && shift_in <= 48) guard = P_in[shift_in-1];
            if (shift_in > 1 && shift_in <= 49) round = P_in[shift_in-2];
            for (j=0; j<48; j=j+1) begin
                if (j < shift_in - 2) sticky = sticky | P_in[j];
            end
            if (guard && (round || sticky || M[0])) M = M + 1'b1;
            round_product = M;
        end
    endfunction

    // Clocked output register
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            z <= 32'd0;
            counter <= 3'd0;
        end else begin
            z <= next_z;
            counter <= counter + 1'b1;
        end
    end

    // Combinational logic
    always @(*) begin
        // Defaults to avoid latches
        next_z = 32'd0;
        sign = a[31] ^ b[31];
        exp_a = a[30:23];
        exp_b = b[30:23];
        frac_a = a[22:0];
        frac_b = b[22:0];
        M_a = 0; M_b = 0;
        E_a = 0; E_b = 0;
        shift_a = 0; shift_b = 0;
        P = 0; E_sum = 0;
        L = 0; exp_field = 0;
        shift = 0; M_round = 0;
        exp_out = 0; frac_out = 0;
        is_nan = 0; is_inf = 0; is_zero = 0;

        // Special cases
        is_nan = ((exp_a == 8'hFF && frac_a != 0) || (exp_b == 8'hFF && frac_b != 0));
        is_inf = ((exp_a == 8'hFF && frac_a == 0) || (exp_b == 8'hFF && frac_b == 0));
        is_zero = (a[30:0] == 0) || (b[30:0] == 0);

        if (is_nan) begin
            next_z = 32'h7FC00000;
        end else if (is_inf) begin
            if ((a[30:0] == 0) || (b[30:0] == 0))
                next_z = 32'h7FC00000;
            else
                next_z = {sign, 8'hFF, 23'd0};
        end else if (is_zero) begin
            next_z = {sign, 31'd0};
        end else begin
            // Normalize a
            if (exp_a == 0) begin
                M_a = {1'b0, frac_a};
                for (i=23; i>=0; i=i-1) begin
                    if (M_a[i] && shift_a == 0) shift_a = 23 - i;
                end
                M_a = M_a << shift_a;
                E_a = -149 - shift_a;
            end else begin
                M_a = {1'b1, frac_a};
                E_a = exp_a - 150;
            end

            // Normalize b
            if (exp_b == 0) begin
                M_b = {1'b0, frac_b};
                for (i2=23; i2>=0; i2=i2-1) begin
                    if (M_b[i2] && shift_b == 0) shift_b = 23 - i2;
                end
                M_b = M_b << shift_b;
                E_b = -149 - shift_b;
            end else begin
                M_b = {1'b1, frac_b};
                E_b = exp_b - 150;
            end

            // Multiply
            P = M_a * M_b;
            E_sum = E_a + E_b;

            // Determine leading bit position
            if (P[47]) L = 47;
            else L = 46;

            // Compute exponent field
            exp_field = E_sum + L + 127;

            if (exp_field >= 255) begin
                // Overflow to infinity
                next_z = {sign, 8'hFF, 23'd0};
            end else if (exp_field > 0) begin
                // Normal result
                shift = L - 23;
                M_round = round_product(P, shift);
                if (M_round[24]) begin
                    M_round = M_round >> 1;
                    exp_field = exp_field + 1;
                end
                if (exp_field >= 255) begin
                    next_z = {sign, 8'hFF, 23'd0};
                end else begin
                    next_z = {sign, exp_field[7:0], M_round[22:0]};
                end
            end else begin
                // Subnormal result
                shift = -E_sum - 149;
                M_round = round_product(P, shift);
                if (M_round[23]) begin
                    // Rounded up to smallest normal
                    next_z = {sign, 8'd1, 23'd0};
                end else begin
                    next_z = {sign, 8'd0, M_round[22:0]};
                end
            end
        end
    end

endmodule
