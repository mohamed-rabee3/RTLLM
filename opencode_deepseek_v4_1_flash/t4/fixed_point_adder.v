module fixed_point_adder #(
    parameter Q = 8,
    parameter N = 16
)(
    input  [N-1:0] a,
    input  [N-1:0] b,
    output [N-1:0] c
);

    reg [N-1:0] res;

    wire sign_a = a[N-1];
    wire sign_b = b[N-1];
    wire [N-2:0] mag_a = a[N-2:0];
    wire [N-2:0] mag_b = b[N-2:0];

    wire [N-1:0] sum_mag = {1'b0, mag_a} + {1'b0, mag_b};
    wire [N-2:0] diff_ab = mag_a - mag_b;
    wire [N-2:0] diff_ba = mag_b - mag_a;

    always @(*) begin
        if (sign_a == sign_b) begin
            if (sum_mag[N-1]) begin
                // Overflow: saturate to maximum magnitude with the same sign
                res[N-1] = sign_a;
                res[N-2:0] = {N-1{1'b1}};
            end else begin
                res[N-1] = sign_a;
                res[N-2:0] = sum_mag[N-2:0];
            end
        end else begin
            if (mag_a > mag_b) begin
                res[N-1] = sign_a;
                res[N-2:0] = diff_ab;
            end else if (mag_b > mag_a) begin
                res[N-1] = sign_b;
                res[N-2:0] = diff_ba;
            end else begin
                res[N-1] = 1'b0;
                res[N-2:0] = {N-1{1'b0}};
            end
        end
    end

    assign c = res;

endmodule
