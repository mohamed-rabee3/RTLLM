module csa32 (
    input  [31:0] x,
    input  [31:0] y,
    input  [31:0] z,
    output [31:0] s,
    output [31:0] c
);
    assign s = x ^ y ^ z;
    assign c = ((x & y) | (y & z) | (x & z)) << 1;
endmodule

module mul_fast (
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

    // Stage 1: reduce 16 to 11
    wire [31:0] a0, b0, a1, b1, a2, b2, a3, b3, a4, b4;
    csa32 c1_0 (.x(pp[0]),  .y(pp[1]),  .z(pp[2]),  .s(a0), .c(b0));
    csa32 c1_1 (.x(pp[3]),  .y(pp[4]),  .z(pp[5]),  .s(a1), .c(b1));
    csa32 c1_2 (.x(pp[6]),  .y(pp[7]),  .z(pp[8]),  .s(a2), .c(b2));
    csa32 c1_3 (.x(pp[9]),  .y(pp[10]), .z(pp[11]), .s(a3), .c(b3));
    csa32 c1_4 (.x(pp[12]), .y(pp[13]), .z(pp[14]), .s(a4), .c(b4));
    wire [31:0] left1 = pp[15];

    // Stage 2: reduce 11 to 8
    wire [31:0] a5, b5, a6, b6, a7, b7;
    csa32 c2_0 (.x(a0), .y(b0), .z(a1), .s(a5), .c(b5));
    csa32 c2_1 (.x(b1), .y(a2), .z(b2), .s(a6), .c(b6));
    csa32 c2_2 (.x(a3), .y(b3), .z(a4), .s(a7), .c(b7));

    // Stage 3: reduce 8 to 6
    wire [31:0] a8, b8, a9, b9;
    csa32 c3_0 (.x(a5), .y(b5), .z(a6), .s(a8), .c(b8));
    csa32 c3_1 (.x(b6), .y(a7), .z(b7), .s(a9), .c(b9));

    // Stage 4: reduce 6 to 4
    wire [31:0] a10, b10, a11, b11;
    csa32 c4_0 (.x(a8), .y(b8), .z(a9), .s(a10), .c(b10));
    csa32 c4_1 (.x(b9), .y(b4), .z(left1), .s(a11), .c(b11));

    // Stage 5: reduce 4 to 3
    wire [31:0] a12, b12;
    csa32 c5_0 (.x(a10), .y(b10), .z(a11), .s(a12), .c(b12));

    // Stage 6: reduce 3 to 2
    wire [31:0] s_final, c_final;
    csa32 c6_0 (.x(a12), .y(b12), .z(b11), .s(s_final), .c(c_final));

    // Final carry-propagate adder
    assign result = s_final + c_final;

endmodule
