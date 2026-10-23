module mul_low_power (
    input  [15:0] a,
    input  [15:0] b,
    output [31:0] result
);

    wire [31:0] a_ext;
    wire [31:0] sum [0:16];

    assign a_ext = {16'b0, a};
    assign sum[0] = 32'b0;

    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : gen_partial_products
            wire [31:0] pp;
            assign pp = (a_ext << i) & {32{b[i]}};
            assign sum[i + 1] = sum[i] + pp;
        end
    endgenerate

    assign result = sum[16];

endmodule
