module fixed_point_subtractor #(
    parameter Q = 8,
    parameter N = 16
)(
    input [N-1:0] a,
    input [N-1:0] b,
    output [N-1:0] c
);

    reg [N-1:0] res;
    wire sign_a = a[N-1];
    wire sign_b = b[N-1];
    wire [N-2:0] mag_a = a[N-2:0];
    wire [N-2:0] mag_b = b[N-2:0];
    reg [N-2:0] res_mag;
    reg res_sign;

    always @(*) begin
        if (sign_a == sign_b) begin
            if (mag_a >= mag_b) begin
                res_mag = mag_a - mag_b;
                res_sign = sign_a;
            end else begin
                res_mag = mag_b - mag_a;
                res_sign = ~sign_a;
            end
        end else begin
            res_mag = mag_a + mag_b;
            res_sign = sign_a;
        end

        if (res_mag == 0)
            res_sign = 1'b0;

        res = {res_sign, res_mag};
    end

    assign c = res;

endmodule
