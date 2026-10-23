module cla_4bit(
    input  [4:1] A,
    input  [4:1] B,
    input        Cin,
    output [4:1] S,
    output       Cout
);
    wire [4:1] p, g;
    wire c1, c2, c3, c4, c5;

    assign p = A ^ B;
    assign g = A & B;

    assign c1 = Cin;
    assign c2 = g[1] | (p[1] & c1);
    assign c3 = g[2] | (p[2] & g[1]) | (p[2] & p[1] & c1);
    assign c4 = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) |
                (p[3] & p[2] & p[1] & c1);
    assign c5 = g[4] | (p[4] & g[3]) | (p[4] & p[3] & g[2]) |
                (p[4] & p[3] & p[2] & g[1]) |
                (p[4] & p[3] & p[2] & p[1] & c1);

    assign S[1] = p[1] ^ c1;
    assign S[2] = p[2] ^ c2;
    assign S[3] = p[3] ^ c3;
    assign S[4] = p[4] ^ c4;
    assign Cout = c5;
endmodule

module cla_16bit(
    input  [16:1] A,
    input  [16:1] B,
    input         Cin,
    output [16:1] S,
    output        Cout
);
    wire [16:1] p, g;
    wire BP1, BG1, BP2, BG2, BP3, BG3, BP4, BG4;
    wire C1, C5, C9, C13, C17;

    assign p = A ^ B;
    assign g = A & B;

    assign BP1 = p[4] & p[3] & p[2] & p[1];
    assign BG1 = g[4] | (p[4] & g[3]) | (p[4] & p[3] & g[2]) |
                 (p[4] & p[3] & p[2] & g[1]);

    assign BP2 = p[8] & p[7] & p[6] & p[5];
    assign BG2 = g[8] | (p[8] & g[7]) | (p[8] & p[7] & g[6]) |
                 (p[8] & p[7] & p[6] & g[5]);

    assign BP3 = p[12] & p[11] & p[10] & p[9];
    assign BG3 = g[12] | (p[12] & g[11]) | (p[12] & p[11] & g[10]) |
                 (p[12] & p[11] & p[10] & g[9]);

    assign BP4 = p[16] & p[15] & p[14] & p[13];
    assign BG4 = g[16] | (p[16] & g[15]) | (p[16] & p[15] & g[14]) |
                 (p[16] & p[15] & p[14] & g[13]);

    assign C1  = Cin;
    assign C5  = BG1 | (BP1 & C1);
    assign C9  = BG2 | (BP2 & BG1) | (BP2 & BP1 & C1);
    assign C13 = BG3 | (BP3 & BG2) | (BP3 & BP2 & BG1) |
                 (BP3 & BP2 & BP1 & C1);
    assign C17 = BG4 | (BP4 & BG3) | (BP4 & BP3 & BG2) |
                 (BP4 & BP3 & BP2 & BG1) |
                 (BP4 & BP3 & BP2 & BP1 & C1);

    cla_4bit u0(
        .A(A[4:1]),
        .B(B[4:1]),
        .Cin(C1),
        .S(S[4:1])
    );

    cla_4bit u1(
        .A(A[8:5]),
        .B(B[8:5]),
        .Cin(C5),
        .S(S[8:5])
    );

    cla_4bit u2(
        .A(A[12:9]),
        .B(B[12:9]),
        .Cin(C9),
        .S(S[12:9])
    );

    cla_4bit u3(
        .A(A[16:13]),
        .B(B[16:13]),
        .Cin(C13),
        .S(S[16:13])
    );

    assign Cout = C17;
endmodule

module adder_32bit(
    input  [32:1] A,
    input  [32:1] B,
    output [32:1] S,
    output        C32
);
    wire carry_mid;

    cla_16bit u_lower(
        .A(A[16:1]),
        .B(B[16:1]),
        .Cin(1'b0),
        .S(S[16:1]),
        .Cout(carry_mid)
    );

    cla_16bit u_upper(
        .A(A[32:17]),
        .B(B[32:17]),
        .Cin(carry_mid),
        .S(S[32:17]),
        .Cout(C32)
    );
endmodule
