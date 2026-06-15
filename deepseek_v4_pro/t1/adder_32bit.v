// 4-bit Carry-Lookahead Adder (CLA) block
// Generates sum bits, group propagate (P_out) and group generate (G_out)
module cla_4bit (
    input [4:1] A, B,
    input Cin,
    output [4:1] S,
    output P_out,
    output G_out
);
    wire [4:1] P, G;
    wire C1, C2, C3; // internal carries: C1 out of bit 1, C2 out of bit 2, C3 out of bit 3

    // Bit 1 (LSB)
    assign P[1] = A[1] ^ B[1];
    assign G[1] = A[1] & B[1];
    assign S[1] = P[1] ^ Cin;
    assign C1   = G[1] | (P[1] & Cin);

    // Bit 2
    assign P[2] = A[2] ^ B[2];
    assign G[2] = A[2] & B[2];
    assign S[2] = P[2] ^ C1;
    assign C2   = G[2] | (P[2] & G[1]) | (P[2] & P[1] & Cin);

    // Bit 3
    assign P[3] = A[3] ^ B[3];
    assign G[3] = A[3] & B[3];
    assign S[3] = P[3] ^ C2;
    assign C3   = G[3] | (P[3] & G[2]) | (P[3] & P[2] & G[1]) | (P[3] & P[2] & P[1] & Cin);

    // Bit 4 (MSB)
    assign P[4] = A[4] ^ B[4];
    assign G[4] = A[4] & B[4];
    assign S[4] = P[4] ^ C3;

    // Group propagate and generate for the 4-bit block
    assign P_out = &P; // P[4] & P[3] & P[2] & P[1]
    assign G_out = G[4] | (P[4] & G[3]) | (P[4] & P[3] & G[2]) | (P[4] & P[3] & P[2] & G[1]);

endmodule

// Carry Lookahead Generator for four 4-bit CLA blocks
module clg_4 (
    input [4:1] P, G,
    input Cin,
    output C4, C8, C12, C16
);
    // P[1], G[1] -> lowest 4-bit block (bits 1-4)
    // P[4], G[4] -> highest 4-bit block (bits 13-16)
    assign C4  = G[1] | (P[1] & Cin);
    assign C8  = G[2] | (P[2] & G[1]) | (P[2] & P[1] & Cin);
    assign C12 = G[3] | (P[3] & G[2]) | (P[3] & P[2] & G[1]) | (P[3] & P[2] & P[1] & Cin);
    assign C16 = G[4] | (P[4] & G[3]) | (P[4] & P[3] & G[2]) | (P[4] & P[3] & P[2] & G[1]) | (P[4] & P[3] & P[2] & P[1] & Cin);
endmodule

// 16-bit Carry-Lookahead Adder built from four 4-bit CLA blocks
module cla_16bit (
    input [16:1] A, B,
    input Cin,
    output [16:1] S,
    output Cout
);
    wire [4:1] P_block, G_block;
    wire C4, C8, C12, C16;
    wire [4:1] S1, S2, S3, S4; // sum outputs of the four 4-bit blocks

    // Block 1: bits 1-4
    cla_4bit blk1 (
        .A(A[4:1]),
        .B(B[4:1]),
        .Cin(Cin),
        .S(S1),
        .P_out(P_block[1]),
        .G_out(G_block[1])
    );

    // Block 2: bits 5-8
    cla_4bit blk2 (
        .A(A[8:5]),
        .B(B[8:5]),
        .Cin(C4),
        .S(S2),
        .P_out(P_block[2]),
        .G_out(G_block[2])
    );

    // Block 3: bits 9-12
    cla_4bit blk3 (
        .A(A[12:9]),
        .B(B[12:9]),
        .Cin(C8),
        .S(S3),
        .P_out(P_block[3]),
        .G_out(G_block[3])
    );

    // Block 4: bits 13-16
    cla_4bit blk4 (
        .A(A[16:13]),
        .B(B[16:13]),
        .Cin(C12),
        .S(S4),
        .P_out(P_block[4]),
        .G_out(G_block[4])
    );

    // Carry Lookahead Generator for the four blocks
    clg_4 clg (
        .P(P_block),
        .G(G_block),
        .Cin(Cin),
        .C4(C4),
        .C8(C8),
        .C12(C12),
        .C16(C16)
    );

    // Concatenate sum outputs
    assign S[4:1]   = S1;
    assign S[8:5]   = S2;
    assign S[12:9]  = S3;
    assign S[16:13] = S4;

    assign Cout = C16;

endmodule

// Top-level 32-bit Adder using two 16-bit CLA blocks
module adder_32bit (
    input [32:1] A, B,
    output [32:1] S,
    output C32
);
    wire C16;
    wire [16:1] S_lo, S_hi;

    // Low 16-bit adder (bits 1-16)
    cla_16bit lo (
        .A(A[16:1]),
        .B(B[16:1]),
        .Cin(1'b0),
        .S(S_lo),
        .Cout(C16)
    );

    // High 16-bit adder (bits 17-32)
    cla_16bit hi (
        .A(A[32:17]),
        .B(B[32:17]),
        .Cin(C16),
        .S(S_hi),
        .Cout(C32)
    );

    assign S[16:1]  = S_lo;
    assign S[32:17] = S_hi;

endmodule