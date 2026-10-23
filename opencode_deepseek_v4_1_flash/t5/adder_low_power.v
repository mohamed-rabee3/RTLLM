module add_low_power (
    input  [15:0] a,
    input  [15:0] b,
    output [16:0] result
);

    wire [16:0] a_ext;
    wire [16:0] b_ext;

    assign a_ext = {1'b0, a};
    assign b_ext = {1'b0, b};

    assign result = a_ext + b_ext;

endmodule
