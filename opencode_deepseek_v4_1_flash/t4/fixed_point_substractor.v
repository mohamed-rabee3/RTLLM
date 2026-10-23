module fixed_point_subtractor #(
    parameter Q = 8,
    parameter N = 16
)(
    input [N-1:0] a,
    input [N-1:0] b,
    output [N-1:0] c
);

    reg [N-1:0] res;
    reg sign_a, sign_b;
    reg [N-2:0] mag_a, mag_b;
    reg [N-2:0] mag_res;
    reg sign_res;

    always @(*) begin
        sign_a = a[N-1];
        sign_b = b[N-1];
        mag_a = a[N-2:0];
        mag_b = b[N-2:0];

        if (sign_a == sign_b) begin
            if (mag_a >= mag_b) begin
                mag_res = mag_a - mag_b;
                sign_res = sign_a;
            end else begin
                mag_res = mag_b - mag_a;
                sign_res = ~sign_a;
            end
        end else begin
            mag_res = mag_a + mag_b;
            sign_res = sign_a;
        end

        if (mag_res == 0) begin
            sign_res = 1'b0;
        end

        res = {sign_res, mag_res};
    end

    assign c = res;

endmodule
