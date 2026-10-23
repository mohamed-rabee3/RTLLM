module cla_4(
    input [4:1] A,
    input [4:1] B,
    input Cin,
    output [4:1] S,
    output Cout
);
    wire [4:1] P, G, C;
    assign P = A ^ B;
    assign G = A & B;
    assign C[1] = Cin;
    assign S[1] = P[1] ^ C[1];
    assign C[2] = G[1] | (P[1] & C[1]);
    assign S[2] = P[2] ^ C[2];
    assign C[3] = G[2] | (P[2] & G[1]) | (P[2] & P[1] & C[1]);
    assign S[3] = P[3] ^ C[3];
    assign C[4] = G[3] | (P[3] & G[2]) | (P[3] & P[2] & G[1]) | (P[3] & P[2] & P[1] & C[1]);
    assign S[4] = P[4] ^ C[4];
    assign Cout = G[4] | (P[4] & G[3]) | (P[4] & P[3] & G[2]) | (P[4] & P[3] & P[2] & G[1]) | (P[4] & P[3] & P[2] & P[1] & C[1]);
endmodule

module cla_16(
    input [16:1] A,
    input [16:1] B,
    input Cin,
    output [16:1] S,
    output Cout
);
    wire [16:1] P, G;
    assign P = A ^ B;
    assign G = A & B;

    wire p0, g0, p1, g1, p2, g2, p3, g3;
    assign p0 = P[4] & P[3] & P[2] & P[1];
    assign g0 = G[4] | (P[4] & G[3]) | (P[4] & P[3] & G[2]) | (P[4] & P[3] & P[2] & G[1]);
    assign p1 = P[8] & P[7] & P[6] & P[5];
    assign g1 = G[8] | (P[8] & G[7]) | (P[8] & P[7] & G[6]) | (P[8] & P[7] & P[6] & G[5]);
    assign p2 = P[12] & P[11] & P[10] & P[9];
    assign g2 = G[12] | (P[12] & G[11]) | (P[12] & P[11] & G[10]) | (P[12] & P[11] & P[10] & G[9]);
    assign p3 = P[16] & P[15] & P[14] & P[13];
    assign g3 = G[16] | (P[16] & G[15]) | (P[16] & P[15] & G[14]) | (P[16] & P[15] & P[14] & G[13]);

    wire C1, C5, C9, C13;
    assign C1 = Cin;
    assign C5 = g0 | (p0 & C1);
    assign C9 = g1 | (p1 & g0) | (p1 & p0 & C1);
    assign C13 = g2 | (p2 & g1) | (p2 & p1 & g0) | (p2 & p1 & p0 & C1);
    assign Cout = g3 | (p3 & g2) | (p3 & p2 & g1) | (p3 & p2 & p1 & g0) | (p3 & p2 & p1 & p0 & C1);

    cla_4 u0(.A(A[4:1]), .B(B[4:1]), .Cin(C1), .S(S[4:1]));
    cla_4 u1(.A(A[8:5]), .B(B[8:5]), .Cin(C5), .S(S[8:5]));
    cla_4 u2(.A(A[12:9]), .B(B[12:9]), .Cin(C9), .S(S[12:9]));
    cla_4 u3(.A(A[16:13]), .B(B[16:13]), .Cin(C13), .S(S[16:13]));
endmodule

module adder_32bit(
    input [32:1] A,
    input [32:1] B,
    output [32:1] S,
    output C32
);
    wire C16;
    cla_16 u_low(
        .A(A[16:1]),
        .B(B[16:1]),
        .Cin(1'b0),
        .S(S[16:1]),
        .Cout(C16)
    );
    cla_16 u_high(
        .A(A[32:17]),
        .B(B[32:17]),
        .Cin(C16),
        .S(S[32:17]),
        .Cout(C32)
    );
endmodule
