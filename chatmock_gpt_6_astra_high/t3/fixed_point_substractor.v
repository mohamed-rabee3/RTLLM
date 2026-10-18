module fixed_point_subtractor #(
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
            res[N-2:0] = a[N-2:0] - b[N-2:0];
            res[N-1]   = a[N-1];
        end else begin
            res[N-2:0] = a[N-2:0] + b[N-2:0];

            if (a[N-2:0] > b[N-2:0])
                res[N-1] = a[N-1];
            else
                res[N-1] = b[N-1];
        end

        if (res[N-2:0] == {(N-1){1'b0}})
            res[N-1] = 1'b0;
    end

    assign c = res;

endmodule
