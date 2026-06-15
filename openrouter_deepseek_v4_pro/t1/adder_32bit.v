// ============================================
// 4-bit Carry-Lookahead Adder Slice
// ============================================
module cla_4bit (
    input  [4:1] A,
    input  [4:1] B,
    input        Cin,
    output [4:1] S,
    output       Pg,   // group propagate
    output       Gg    // group generate
);
    wire [4:1] p, g;  // bit propagate and generate
    wire [4:1] c;     // internal carries (c[1] is carry into bit2, etc.)

    assign p = A ^ B;
    assign g = A & B;

    // carry lookahead equations for the 4-bit block
    assign c[1] = g[1] | (p[1] & Cin);
    assign c[2] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & Cin);
    assign c[3] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & Cin);
    // c[4] is the carry out, used for group generate
    wire c4;
    assign c4 = g[4] | (p[4] & g[3]) | (p[4] & p[3] & g[2]) |
                (p[4] & p[3] & p[2] & g[1]) |
                (p[4] & p[3] & p[2] & p[1] & Cin);

    // sum outputs
    assign S[1] = p[1] ^ Cin;
    assign S[2] = p[2] ^ c[1];
    assign S[3] = p[3] ^ c[2];
    assign S[4] = p[4] ^ c[3];

    // group propagate and generate
    assign Pg = p[4] & p[3] & p[2] & p[1];
    assign Gg = g[4] | (p[4] & g[3]) | (p[4] & p[3] & g[2]) |
                (p[4] & p[3] & p[2] & g[1]);
endmodule

// ============================================
// 16-bit Carry-Lookahead Adder
// ============================================
module cla_16bit (
    input  [16:1] A,
    input  [16:1] B,
    input         Cin,
    output [16:1] S,
    output        Cout
);
    // group propagate and generate from each 4-bit slice
    wire Pg0, Pg1, Pg2, Pg3;
    wire Gg0, Gg1, Gg2, Gg3;

    // carries between 4-bit blocks
    wire c4, c8, c12, c16;

    // four 4-bit CLA slices
    cla_4bit slice0 ( .A(A[4:1]),   .B(B[4:1]),   .Cin(Cin),  .S(S[4:1]),   .Pg(Pg0), .Gg(Gg0) );
    cla_4bit slice1 ( .A(A[8:5]),   .B(B[8:5]),   .Cin(c4),   .S(S[8:5]),   .Pg(Pg1), .Gg(Gg1) );
    cla_4bit slice2 ( .A(A[12:9]),  .B(B[12:9]),  .Cin(c8),   .S(S[12:9]),  .Pg(Pg2), .Gg(Gg2) );
    cla_4bit slice3 ( .A(A[16:13]), .B(B[16:13]), .Cin(c12),  .S(S[16:13]), .Pg(Pg3), .Gg(Gg3) );

    // Second-level carry lookahead for the four groups
    assign c4  = Gg0 | (Pg0 & Cin);
    assign c8  = Gg1 | (Pg1 & Gg0) | (Pg1 & Pg0 & Cin);
    assign c12 = Gg2 | (Pg2 & Gg1) | (Pg2 & Pg1 & Gg0) |
                 (Pg2 & Pg1 & Pg0 & Cin);
    assign c16 = Gg3 | (Pg3 & Gg2) | (Pg3 & Pg2 & Gg1) |
                 (Pg3 & Pg2 & Pg1 & Gg0) |
                 (Pg3 & Pg2 & Pg1 & Pg0 & Cin);

    assign Cout = c16;
endmodule

// ============================================
// 32-bit Carry-Lookahead Adder (Top Module)
// ============================================
module adder_32bit (
    input  [32:1] A,
    input  [32:1] B,
    output [32:1] S,
    output        C32
);
    wire C16;  // carry out from lower 16-bit block

    // lower 16-bit adder (bit1 .. bit16), carry-in = 0
    cla_16bit lower (
        .A   (A[16:1]),
        .B   (B[16:1]),
        .Cin (1'b0),
        .S   (S[16:1]),
        .Cout(C16)
    );

    // upper 16-bit adder (bit17 .. bit32)
    cla_16bit upper (
        .A   (A[32:17]),
        .B   (B[32:17]),
        .Cin (C16),
        .S   (S[32:17]),
        .Cout(C32)
    );
endmodule