module cla_16bit(
    input  [16:1] A,
    input  [16:1] B,
    input         Cin,
    output [16:1] S,
    output        Cout
);

    wire [16:1] P;
    wire [16:1] G;
    wire [16:0] C;
    wire GG0, GG1, GG2, GG3;
    wire GP0, GP1, GP2, GP3;

    assign P = A ^ B;
    assign G = A & B;

    // Group 0: bits 1-4
    assign GG0 = G[4] | (P[4] & G[3]) | (P[4] & P[3] & G[2]) | (P[4] & P[3] & P[2] & G[1]);
    assign GP0 = P[4] & P[3] & P[2] & P[1];

    // Group 1: bits 5-8
    assign GG1 = G[8] | (P[8] & G[7]) | (P[8] & P[7] & G[6]) | (P[8] & P[7] & P[6] & G[5]);
    assign GP1 = P[8] & P[7] & P[6] & P[5];

    // Group 2: bits 9-12
    assign GG2 = G[12] | (P[12] & G[11]) | (P[12] & P[11] & G[10]) | (P[12] & P[11] & P[10] & G[9]);
    assign GP2 = P[12] & P[11] & P[10] & P[9];

    // Group 3: bits 13-16
    assign GG3 = G[16] | (P[16] & G[15]) | (P[16] & P[15] & G[14]) | (P[16] & P[15] & P[14] & G[13]);
    assign GP3 = P[16] & P[15] & P[14] & P[13];

    // Group carries with lookahead across 4-bit groups
    assign C[0] = Cin;
    assign C[4]  = GG0 | (GP0 & C[0]);
    assign C[8]  = GG1 | (GP1 & GG0) | (GP1 & GP0 & C[0]);
    assign C[12] = GG2 | (GP2 & GG1) | (GP2 & GP1 & GG0) | (GP2 & GP1 & GP0 & C[0]);
    assign C[16] = GG3 | (GP3 & GG2) | (GP3 & GP2 & GG1) | (GP3 & GP2 & GP1 & GG0) | (GP3 & GP2 & GP1 & GP0 & C[0]);

    // Carries within group 0
    assign C[1] = G[1] | (P[1] & C[0]);
    assign C[2] = G[2] | (P[2] & G[1]) | (P[2] & P[1] & C[0]);
    assign C[3] = G[3] | (P[3] & G[2]) | (P[3] & P[2] & G[1]) | (P[3] & P[2] & P[1] & C[0]);

    // Carries within group 1
    assign C[5] = G[5] | (P[5] & C[4]);
    assign C[6] = G[6] | (P[6] & G[5]) | (P[6] & P[5] & C[4]);
    assign C[7] = G[7] | (P[7] & G[6]) | (P[7] & P[6] & G[5]) | (P[7] & P[6] & P[5] & C[4]);

    // Carries within group 2
    assign C[9]  = G[9] | (P[9] & C[8]);
    assign C[10] = G[10] | (P[10] & G[9]) | (P[10] & P[9] & C[8]);
    assign C[11] = G[11] | (P[11] & G[10]) | (P[11] & P[10] & G[9]) | (P[11] & P[10] & P[9] & C[8]);

    // Carries within group 3
    assign C[13] = G[13] | (P[13] & C[12]);
    assign C[14] = G[14] | (P[14] & G[13]) | (P[14] & P[13] & C[12]);
    assign C[15] = G[15] | (P[15] & G[14]) | (P[15] & P[14] & G[13]) | (P[15] & P[14] & P[13] & C[12]);

    // Sum bits
    assign S[1]  = P[1]  ^ C[0];
    assign S[2]  = P[2]  ^ C[1];
    assign S[3]  = P[3]  ^ C[2];
    assign S[4]  = P[4]  ^ C[3];
    assign S[5]  = P[5]  ^ C[4];
    assign S[6]  = P[6]  ^ C[5];
    assign S[7]  = P[7]  ^ C[6];
    assign S[8]  = P[8]  ^ C[7];
    assign S[9]  = P[9]  ^ C[8];
    assign S[10] = P[10] ^ C[9];
    assign S[11] = P[11] ^ C[10];
    assign S[12] = P[12] ^ C[11];
    assign S[13] = P[13] ^ C[12];
    assign S[14] = P[14] ^ C[13];
    assign S[15] = P[15] ^ C[14];
    assign S[16] = P[16] ^ C[15];

    assign Cout = C[16];

endmodule


module adder_32bit(
    input  [32:1] A,
    input  [32:1] B,
    output [32:1] S,
    output        C32
);

    wire C16;

    cla_16bit u_cla_low (
        .A    (A[16:1]),
        .B    (B[16:1]),
        .Cin  (1'b0),
        .S    (S[16:1]),
        .Cout (C16)
    );

    cla_16bit u_cla_high (
        .A    (A[32:17]),
        .B    (B[32:17]),
        .Cin  (C16),
        .S    (S[32:17]),
        .Cout (C32)
    );

endmodule
