module mul_fast (
    input  [15:0] a,
    input  [15:0] b,
    output [31:0] result
);

    wire [31:0] pp [0:15];
    genvar i;

    generate
        for (i = 0; i < 16; i = i + 1) begin : pp_gen
            assign pp[i] = b[i] ? ({16'd0, a} << i) : 32'd0;
        end
    endgenerate

    // Stage 1: 16 -> 11 operands
    wire [31:0] s1_0, c1_0, s1_1, c1_1, s1_2, c1_2, s1_3, c1_3, s1_4, c1_4;
    csa u1_0 (.x(pp[0]),  .y(pp[1]),  .z(pp[2]),  .s(s1_0), .c(c1_0));
    csa u1_1 (.x(pp[3]),  .y(pp[4]),  .z(pp[5]),  .s(s1_1), .c(c1_1));
    csa u1_2 (.x(pp[6]),  .y(pp[7]),  .z(pp[8]),  .s(s1_2), .c(c1_2));
    csa u1_3 (.x(pp[9]),  .y(pp[10]), .z(pp[11]), .s(s1_3), .c(c1_3));
    csa u1_4 (.x(pp[12]), .y(pp[13]), .z(pp[14]), .s(s1_4), .c(c1_4));

    // Stage 2: 11 -> 8 operands
    wire [31:0] s2_0, c2_0, s2_1, c2_1, s2_2, c2_2;
    csa u2_0 (.x(s1_0), .y(c1_0), .z(s1_1), .s(s2_0), .c(c2_0));
    csa u2_1 (.x(c1_1), .y(s1_2), .z(c1_2), .s(s2_1), .c(c2_1));
    csa u2_2 (.x(s1_3), .y(c1_3), .z(s1_4), .s(s2_2), .c(c2_2));

    // Stage 3: 8 -> 6 operands
    wire [31:0] s3_0, c3_0, s3_1, c3_1;
    csa u3_0 (.x(s2_0), .y(c2_0), .z(s2_1), .s(s3_0), .c(c3_0));
    csa u3_1 (.x(c2_1), .y(s2_2), .z(c2_2), .s(s3_1), .c(c3_1));

    // Stage 4: 6 -> 4 operands
    wire [31:0] s4_0, c4_0, s4_1, c4_1;
    csa u4_0 (.x(s3_0), .y(c3_0), .z(s3_1), .s(s4_0), .c(c4_0));
    csa u4_1 (.x(c3_1), .y(c1_4), .z(pp[15]), .s(s4_1), .c(c4_1));

    // Stage 5: 4 -> 3 operands
    wire [31:0] s5_0, c5_0;
    csa u5_0 (.x(s4_0), .y(c4_0), .z(s4_1), .s(s5_0), .c(c5_0));

    // Stage 6: 3 -> 2 operands
    wire [31:0] s6_0, c6_0;
    csa u6_0 (.x(s5_0), .y(c5_0), .z(c4_1), .s(s6_0), .c(c6_0));

    // Final carry-propagate addition
    assign result = s6_0 + c6_0;

endmodule

module csa (
    input  [31:0] x,
    input  [31:0] y,
    input  [31:0] z,
    output [31:0] s,
    output [31:0] c
);
    wire [31:0] carry_unshifted;
    assign s = x ^ y ^ z;
    assign carry_unshifted = (x & y) | (x & z) | (y & z);
    assign c = carry_unshifted << 1;
endmodule
