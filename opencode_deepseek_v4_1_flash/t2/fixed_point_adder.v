module fixed_point_adder #(
    parameter Q = 8,
    parameter N = 16
)(
    input  [N-1:0] a,
    input  [N-1:0] b,
    output [N-1:0] c
);

    reg  [N-1:0] res;
    wire [N-2:0] mag_a = a[N-2:0];
    wire [N-2:0] mag_b = b[N-2:0];

    always @(*) begin
        if (a[N-1] == b[N-1]) begin
            res = {a[N-1], (mag_a + mag_b)};
        end else begin
            if (mag_a >= mag_b) begin
                res = {1'b0, (mag_a - mag_b)};
            end else begin
                res = {1'b1, (mag_b - mag_a)};
            end
        end
    end

    assign c = res;

endmodule
