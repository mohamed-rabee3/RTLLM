module fixed_point_adder #(
    parameter Q = 15,
    parameter N = 32
) (
    input  wire [N-1:0] a,
    input  wire [N-1:0] b,
    output wire [N-1:0] c
);

    reg [N-1:0] res;

    always @* begin
        res = {N{1'b0}};

        if (a[N-1] == b[N-1]) begin
            // Sign-magnitude addition; excess magnitude carry is discarded.
            res[N-2:0] = a[N-2:0] + b[N-2:0];
            res[N-1]   = a[N-1];
        end else begin
            // Opposite signs: subtract magnitudes and retain the larger's sign.
            if (a[N-2:0] > b[N-2:0]) begin
                res[N-2:0] = a[N-2:0] - b[N-2:0];
                res[N-1]   = a[N-1];
            end else if (b[N-2:0] > a[N-2:0]) begin
                res[N-2:0] = b[N-2:0] - a[N-2:0];
                res[N-1]   = b[N-1];
            end else begin
                // Equal, opposite magnitudes produce positive zero.
                res = {N{1'b0}};
            end
        end
    end

    assign c = res;

endmodule
