module mul_fast(
    input  [15:0] a,
    input  [15:0] b,
    output [31:0] result
);

    wire [31:0] pp [0:15];

    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : gen_pp
            assign pp[i] = b[i] ? ({16'b0, a} << i) : 32'b0;
        end
    endgenerate

    wire [31:0] a0, b0, a1, b1, a2, b2, a3, b3, a4, b4;
    wire [31:0] s0, c0, s1, c1, s2, c2;
    wire [31:0] t0, u0, t1, u1;
    wire [31:0] v0, w0, v1, w1;
    wire [31:0] x0, y0;
    wire [31:0] ysum, ycarry;

    csa32 g1_0 (.x(pp[0]),  .y(pp[1]),  .z(pp[2]),  .s(a0), .c(b0));
    csa32 g1_1 (.x(pp[3]),  .y(pp[4]),  .z(pp[5]),  .s(a1), .c(b1));
    csa32 g1_2 (.x(pp[6]),  .y(pp[7]),  .z(pp[8]),  .s(a2), .c(b2));
    csa32 g1_3 (.x(pp[9]),  .y(pp[10]), .z(pp[11]), .s(a3), .c(b3));
    csa32 g1_4 (.x(pp[12]), .y(pp[13]), .z(pp[14]), .s(a4), .c(b4));

    csa32 g2_0 (.x(a0), .y(b0), .z(a1), .s(s0), .c(c0));
    csa32 g2_1 (.x(b1), .y(a2), .z(b2), .s(s1), .c(c1));
    csa32 g2_2 (.x(a3), .y(b3), .z(a4), .s(s2), .c(c2));

    csa32 g3_0 (.x(s0), .y(c0), .z(s1), .s(t0), .c(u0));
    csa32 g3_1 (.x(c1), .y(s2), .z(c2), .s(t1), .c(u1));

    csa32 g4_0 (.x(t0), .y(u0), .z(t1), .s(v0), .c(w0));
    csa32 g4_1 (.x(u1), .y(b4), .z(pp[15]), .s(v1), .c(w1));

    csa32 g5_0 (.x(v0), .y(w0), .z(v1), .s(x0), .c(y0));

    csa32 g6_0 (.x(x0), .y(y0), .z(w1), .s(ysum), .c(ycarry));

    assign result = ysum + ycarry;

endmodule

module csa32(
    input  [31:0] x,
    input  [31:0] y,
    input  [31:0] z,
    output [31:0] s,
    output [31:0] c
);

    wire [31:0] carry_raw;

    assign s = x ^ y ^ z;
    assign carry_raw = (x & y) | (x & z) | (y & z);
    assign c = {carry_raw[30:0], 1'b0};

endmodule
