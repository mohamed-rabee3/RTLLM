module mul_fast(
    input [15:0] a,
    input [15:0] b,
    output [31:0] result
);

    wire [31:0] pp0, pp1, pp2, pp3, pp4, pp5, pp6, pp7;
    wire [31:0] pp8, pp9, pp10, pp11, pp12, pp13, pp14, pp15;

    assign pp0  = b[0]  ? {16'b0, a}        : 32'b0;
    assign pp1  = b[1]  ? ({16'b0, a} << 1) : 32'b0;
    assign pp2  = b[2]  ? ({16'b0, a} << 2) : 32'b0;
    assign pp3  = b[3]  ? ({16'b0, a} << 3) : 32'b0;
    assign pp4  = b[4]  ? ({16'b0, a} << 4) : 32'b0;
    assign pp5  = b[5]  ? ({16'b0, a} << 5) : 32'b0;
    assign pp6  = b[6]  ? ({16'b0, a} << 6) : 32'b0;
    assign pp7  = b[7]  ? ({16'b0, a} << 7) : 32'b0;
    assign pp8  = b[8]  ? ({16'b0, a} << 8) : 32'b0;
    assign pp9  = b[9]  ? ({16'b0, a} << 9) : 32'b0;
    assign pp10 = b[10] ? ({16'b0, a} << 10) : 32'b0;
    assign pp11 = b[11] ? ({16'b0, a} << 11) : 32'b0;
    assign pp12 = b[12] ? ({16'b0, a} << 12) : 32'b0;
    assign pp13 = b[13] ? ({16'b0, a} << 13) : 32'b0;
    assign pp14 = b[14] ? ({16'b0, a} << 14) : 32'b0;
    assign pp15 = b[15] ? ({16'b0, a} << 15) : 32'b0;

    // Level 1
    wire [31:0] l1_t0, l1_u0, l1_t1, l1_u1, l1_t2, l1_u2, l1_t3, l1_u3;
    wire [31:0] l1_sum0, l1_carry0, l1_sum1, l1_carry1;
    wire [31:0] l1_sum2, l1_carry2, l1_sum3, l1_carry3;

    mul_csa32 csa_1_0_0 (.x(pp0),  .y(pp1),  .z(pp2),  .sum(l1_t0), .carry(l1_u0));
    mul_csa32 csa_1_0_1 (.x(l1_t0), .y(l1_u0), .z(pp3),  .sum(l1_sum0), .carry(l1_carry0));

    mul_csa32 csa_1_1_0 (.x(pp4),  .y(pp5),  .z(pp6),  .sum(l1_t1), .carry(l1_u1));
    mul_csa32 csa_1_1_1 (.x(l1_t1), .y(l1_u1), .z(pp7),  .sum(l1_sum1), .carry(l1_carry1));

    mul_csa32 csa_1_2_0 (.x(pp8),  .y(pp9),  .z(pp10), .sum(l1_t2), .carry(l1_u2));
    mul_csa32 csa_1_2_1 (.x(l1_t2), .y(l1_u2), .z(pp11), .sum(l1_sum2), .carry(l1_carry2));

    mul_csa32 csa_1_3_0 (.x(pp12), .y(pp13), .z(pp14), .sum(l1_t3), .carry(l1_u3));
    mul_csa32 csa_1_3_1 (.x(l1_t3), .y(l1_u3), .z(pp15), .sum(l1_sum3), .carry(l1_carry3));

    // Level 2
    wire [31:0] l2_t0, l2_u0, l2_t1, l2_u1;
    wire [31:0] l2_sum0, l2_carry0, l2_sum1, l2_carry1;

    mul_csa32 csa_2_0_0 (.x(l1_sum0), .y(l1_carry0), .z(l1_sum1), .sum(l2_t0), .carry(l2_u0));
    mul_csa32 csa_2_0_1 (.x(l2_t0),   .y(l2_u0),     .z(l1_carry1), .sum(l2_sum0), .carry(l2_carry0));

    mul_csa32 csa_2_1_0 (.x(l1_sum2), .y(l1_carry2), .z(l1_sum3), .sum(l2_t1), .carry(l2_u1));
    mul_csa32 csa_2_1_1 (.x(l2_t1),   .y(l2_u1),     .z(l1_carry3), .sum(l2_sum1), .carry(l2_carry1));

    // Level 3
    wire [31:0] l3_t0, l3_u0;
    wire [31:0] l3_sum0, l3_carry0;

    mul_csa32 csa_3_0_0 (.x(l2_sum0), .y(l2_carry0), .z(l2_sum1), .sum(l3_t0), .carry(l3_u0));
    mul_csa32 csa_3_0_1 (.x(l3_t0),   .y(l3_u0),     .z(l2_carry1), .sum(l3_sum0), .carry(l3_carry0));

    assign result = l3_sum0 + l3_carry0;

endmodule

module mul_csa32(
    input [31:0] x,
    input [31:0] y,
    input [31:0] z,
    output [31:0] sum,
    output [31:0] carry
);
    assign sum = x ^ y ^ z;
    assign carry = ((x & y) | (y & z) | (x & z)) << 1;
endmodule
