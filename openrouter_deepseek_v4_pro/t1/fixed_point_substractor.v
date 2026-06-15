module fixed_point_subtractor #(
    parameter Q = 12,   // number of fractional bits
    parameter N = 16    // total bits (sign + integer + fractional)
) (
    input  wire [N-1:0] a,
    input  wire [N-1:0] b,
    output reg  [N-1:0] c
);
    // Internal register to hold the subtraction result
    reg [N-1:0] res;

    // Decompose inputs into sign and magnitude
    wire        sign_a, sign_b;
    wire [N-2:0] mag_a, mag_b;

    assign sign_a = a[N-1];
    assign sign_b = b[N-1];
    assign mag_a  = a[N-2:0];
    assign mag_b  = b[N-2:0];

    always @(*) begin
        reg [N-2:0] mag_res;
        reg         sign_res;

        if (sign_a == sign_b) begin
            // Same sign: subtract magnitudes, result sign depends on which is larger
            if (mag_a >= mag_b) begin
                mag_res  = mag_a - mag_b;
                sign_res = sign_a;
            end else begin
                mag_res  = mag_b - mag_a;
                sign_res = ~sign_a;   // opposite sign of the inputs
            end
        end else begin
            // Different signs: add magnitudes, result sign equals sign of a
            sign_res = sign_a;
            // Add with one extra bit for overflow detection
            reg [N-1:0] sum_full;
            sum_full = {1'b0, mag_a} + {1'b0, mag_b};
            if (sum_full[N-1]) begin               // overflow occurred
                mag_res = {N-1{1'b1}};             // saturate to maximum magnitude
            end else begin
                mag_res = sum_full[N-2:0];
            end
        end

        // Handle zero result: force sign to 0 and magnitude to 0
        if (mag_res == 0) begin
            sign_res = 1'b0;
            mag_res  = {N-1{1'b0}};
        end

        res = {sign_res, mag_res};
    end

    // Drive the output from the internal register
    assign c = res;

endmodule