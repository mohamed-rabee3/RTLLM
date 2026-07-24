module verified_mul_fast(
    input  [15:0] a,
    input  [15:0] b,
    output [31:0] result
);
    wire [31:0] pp [0:15];
    genvar i;
    generate for (i = 0; i < 16; i = i + 1) begin : pgen
        assign pp[i] = b[i] ? ({16'd0, a} << i) : 32'd0;
    end endgenerate
    // balanced (tree) reduction of the 16 partial products
    wire [31:0] s0 = pp[0]  + pp[1];
    wire [31:0] s1 = pp[2]  + pp[3];
    wire [31:0] s2 = pp[4]  + pp[5];
    wire [31:0] s3 = pp[6]  + pp[7];
    wire [31:0] s4 = pp[8]  + pp[9];
    wire [31:0] s5 = pp[10] + pp[11];
    wire [31:0] s6 = pp[12] + pp[13];
    wire [31:0] s7 = pp[14] + pp[15];
    wire [31:0] t0 = s0 + s1;
    wire [31:0] t1 = s2 + s3;
    wire [31:0] t2 = s4 + s5;
    wire [31:0] t3 = s6 + s7;
    wire [31:0] u0 = t0 + t1;
    wire [31:0] u1 = t2 + t3;
    assign result = u0 + u1;
endmodule
