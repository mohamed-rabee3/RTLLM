module add_CLA (
    input  [15:0] a,
    input  [15:0] b,
    output [16:0] result
);

    wire [15:0] g;
    wire [15:0] p;
    wire [16:0] c;

    assign c[0] = 1'b0;

    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : CLA_BITS
            assign g[i]      = a[i] & b[i];
            assign p[i]      = a[i] ^ b[i];
            assign c[i+1]    = g[i] | (p[i] & c[i]);
            assign result[i] = p[i] ^ c[i];
        end
    endgenerate

    assign result[16] = c[16];

endmodule
