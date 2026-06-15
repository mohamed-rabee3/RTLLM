module fixed_point_adder #(
    parameter Q = 0,   // Number of fractional bits (precision)
    parameter N = 8    // Total number of bits
) (
    input  [N-1:0] a,
    input  [N-1:0] b,
    output [N-1:0] c
);

    // Internal register to store the result
    reg [N-1:0] res;

    // Sign bits of the operands
    wire sign_a = a[N-1];
    wire sign_b = b[N-1];

    // Sign-extended versions (N+1 bits) for safe absolute value computation
    wire [N:0] a_ext = {a[N-1], a};
    wire [N:0] b_ext = {b[N-1], b};

    // Absolute values in N+1 bits
    wire [N:0] abs_a = sign_a ? (~a_ext + 1'b1) : a_ext;
    wire [N:0] abs_b = sign_b ? (~b_ext + 1'b1) : b_ext;

    // Saturation thresholds
    wire [N:0] max_pos    = {1'b0, {1'b0, {(N-1){1'b1}}}}; // maximum positive value (0_011...1)
    wire [N:0] neg_thresh = {1'b0, {1'b1, {(N-1){1'b0}}}}; // 2^(N-1), limit for negative magnitude

    // Temporary variables for the combinational logic
    reg [N:0] sum_abs;
    reg [N:0] magnitude;
    reg        sign_res;

    always @(*) begin
        if (sign_a == sign_b) begin
            // Same sign: add absolute values
            sum_abs = abs_a + abs_b;
            if (sign_a == 1'b0) begin
                // Both positive
                if (sum_abs > max_pos)
                    res = max_pos[N-1:0];          // saturate to max positive
                else
                    res = sum_abs[N-1:0];          // positive result
            end else begin
                // Both negative
                if (sum_abs > neg_thresh)
                    res = {1'b1, {(N-1){1'b0}}};   // saturate to most negative
                else
                    res = ~sum_abs[N-1:0] + 1'b1;  // two's complement of magnitude
            end
        end else begin
            // Different signs: subtract smaller absolute value from larger
            if (abs_a > abs_b) begin
                magnitude = abs_a - abs_b;
                sign_res  = sign_a;
            end else if (abs_b > abs_a) begin
                magnitude = abs_b - abs_a;
                sign_res  = sign_b;
            end else begin
                magnitude = 0;
                sign_res  = 1'b0;
            end
            // Convert magnitude to signed N-bit value
            if (sign_res == 1'b0)
                res = magnitude[N-1:0];            // positive result
            else
                res = ~magnitude[N-1:0] + 1'b1;    // negative result (two's complement)
        end
    end

    assign c = res;

endmodule