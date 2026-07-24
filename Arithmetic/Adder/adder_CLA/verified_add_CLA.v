module verified_add_CLA(
    input  [15:0] a,
    input  [15:0] b,
    output [16:0] result
);
    wire [15:0] g = a & b;   // generate
    wire [15:0] p = a ^ b;   // propagate
    wire [16:0] c;
    assign c[0] = 1'b0;
    genvar i;
    generate for (i = 0; i < 16; i = i + 1) begin : cla
        assign c[i+1] = g[i] | (p[i] & c[i]);
    end endgenerate
    assign result[15:0] = p ^ c[15:0];
    assign result[16]   = c[16];
endmodule
