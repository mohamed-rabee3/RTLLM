module fixed_point_subtractor #(
    parameter Q = 8,
    parameter N = 16
) (
    input  [N-1:0] a,
    input  [N-1:0] b,
    output [N-1:0] c
);

    reg [N-1:0] res;

    always @(*) begin
        res = a - b;
    end

    assign c = res;

endmodule
