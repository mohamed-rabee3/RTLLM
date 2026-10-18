module add (
    input  [15:0] a,
    input  [15:0] b,
    output [16:0] result
);

    assign result = {1'b0, a} + {1'b0, b};

endmodule
