module cla_16 (
    input  [15:0] A,
    input  [15:0] B,
    input         Cin,
    output [15:0] S,
    output        Cout
);

    wire [15:0] P;
    wire [15:0] G;

    assign P = A ^ B;
    assign G = A & B;

    wire [3:0] GP;
    wire [3:0] GG;

    assign GP[0] = P[3] & P[2] & P[1] & P[0];
    assign GG[0] = G[3] | (P[3] & G[2]) | (P[3] & P[2] & G[1]) | (P[3] & P[2] & P[1] & G[0]);

    assign GP[1] = P[7] & P[6] & P[5] & P[4];
    assign GG[1] = G[7] | (P[7] & G[6]) | (P[7] & P[6] & G[5]) | (P[7] & P[6] & P[5] & G[4]);

    assign GP[2] = P[11] & P[10] & P[9] & P[8];
    assign GG[2] = G[11] | (P[11] & G[10]) | (P[11] & P[10] & G[9]) | (P[11] & P[10] & P[9] & G[8]);

    assign GP[3] = P[15] & P[14] & P[13] & P[12];
    assign GG[3] = G[15] | (P[15] & G[14]) | (P[15] & P[14] & G[13]) | (P[15] & P[14] & P[13] & G[12]);

    wire C0, C4, C8, C12, C16;

    assign C0 = Cin;
    assign C4 = GG[0] | (GP[0] & C0);
    assign C8 = GG[1] | (GP[1] & GG[0]) | (GP[1] & GP[0] & C0);
    assign C12 = GG[2] | (GP[2] & GG[1]) | (GP[2] & GP[1] & GG[0]) | (GP[2] & GP[1] & GP[0] & C0);
    assign C16 = GG[3] | (GP[3] & GG[2]) | (GP[3] & GP[2] & GG[1]) | (GP[3] & GP[2] & GP[1] & GG[0]) | (GP[3] & GP[2] & GP[1] & GP[0] & C0);

    wire C1, C2, C3, C5, C6, C7, C9, C10, C11, C13, C14, C15;

    assign C1 = G[0] | (P[0] & C0);
    assign C2 = G[1] | (P[1] & G[0]) | (P[1] & P[0] & C0);
    assign C3 = G[2] | (P[2] & G[1]) | (P[2] & P[1] & G[0]) | (P[2] & P[1] & P[0] & C0);

    assign C5 = G[4] | (P[4] & C4);
    assign C6 = G[5] | (P[5] & G[4]) | (P[5] & P[4] & C4);
    assign C7 = G[6] | (P[6] & G[5]) | (P[6] & P[5] & G[4]) | (P[6] & P[5] & P[4] & C4);

    assign C9 = G[8] | (P[8] & C8);
    assign C10 = G[9] | (P[9] & G[8]) | (P[9] & P[8] & C8);
    assign C11 = G[10] | (P[10] & G[9]) | (P[10] & P[9] & G[8]) | (P[10] & P[9] & P[8] & C8);

    assign C13 = G[12] | (P[12] & C12);
    assign C14 = G[13] | (P[13] & G[12]) | (P[13] & P[12] & C12);
    assign C15 = G[14] | (P[14] & G[13]) | (P[14] & P[13] & G[12]) | (P[14] & P[13] & P[12] & C12);

    assign S[0]  = P[0]  ^ C0;
    assign S[1]  = P[1]  ^ C1;
    assign S[2]  = P[2]  ^ C2;
    assign S[3]  = P[3]  ^ C3;
    assign S[4]  = P[4]  ^ C4;
    assign S[5]  = P[5]  ^ C5;
    assign S[6]  = P[6]  ^ C6;
    assign S[7]  = P[7]  ^ C7;
    assign S[8]  = P[8]  ^ C8;
    assign S[9]  = P[9]  ^ C9;
    assign S[10] = P[10] ^ C10;
    assign S[11] = P[11] ^ C11;
    assign S[12] = P[12] ^ C12;
    assign S[13] = P[13] ^ C13;
    assign S[14] = P[14] ^ C14;
    assign S[15] = P[15] ^ C15;

    assign Cout = C16;

endmodule

module adder_32 (
    input  [31:0] A,
    input  [31:0] B,
    output [31:0] S,
    output        Carry_out
);

    wire c16;

    cla_16 u_lower (
        .A(A[15:0]),
        .B(B[15:0]),
        .Cin(1'b0),
        .S(S[15:0]),
        .Cout(c16)
    );

    cla_16 u_upper (
        .A(A[31:16]),
        .B(B[31:16]),
        .Cin(c16),
        .S(S[31:16]),
        .Cout(Carry_out)
    );

endmodule
