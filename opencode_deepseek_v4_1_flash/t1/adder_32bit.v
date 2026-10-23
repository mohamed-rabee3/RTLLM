module adder_32bit(
    input  [32:1] A,
    input  [32:1] B,
    output [32:1] S,
    output        C32
);

    wire c16;

    cla_16bit u_cla_low (
        .A(A[16:1]),
        .B(B[16:1]),
        .Cin(1'b0),
        .S(S[16:1]),
        .Cout(c16)
    );

    cla_16bit u_cla_high (
        .A(A[32:17]),
        .B(B[32:17]),
        .Cin(c16),
        .S(S[32:17]),
        .Cout(C32)
    );

endmodule

module cla_16bit(
    input  [15:0] A,
    input  [15:0] B,
    input         Cin,
    output [15:0] S,
    output        Cout
);

    wire [3:0] Pg;
    wire [3:0] Gg;
    wire C4, C8, C12;

    cla_4bit u0 (
        .A(A[3:0]),
        .B(B[3:0]),
        .Cin(Cin),
        .S(S[3:0]),
        .Pg(Pg[0]),
        .Gg(Gg[0])
    );

    cla_4bit u1 (
        .A(A[7:4]),
        .B(B[7:4]),
        .Cin(C4),
        .S(S[7:4]),
        .Pg(Pg[1]),
        .Gg(Gg[1])
    );

    cla_4bit u2 (
        .A(A[11:8]),
        .B(B[11:8]),
        .Cin(C8),
        .S(S[11:8]),
        .Pg(Pg[2]),
        .Gg(Gg[2])
    );

    cla_4bit u3 (
        .A(A[15:12]),
        .B(B[15:12]),
        .Cin(C12),
        .S(S[15:12]),
        .Pg(Pg[3]),
        .Gg(Gg[3])
    );

    assign C4  = Gg[0] | (Pg[0] & Cin);
    assign C8  = Gg[1] | (Pg[1] & Gg[0]) | (Pg[1] & Pg[0] & Cin);
    assign C12 = Gg[2] | (Pg[2] & Gg[1]) | (Pg[2] & Pg[1] & Gg[0]) | (Pg[2] & Pg[1] & Pg[0] & Cin);
    assign Cout = Gg[3] | (Pg[3] & Gg[2]) | (Pg[3] & Pg[2] & Gg[1]) | (Pg[3] & Pg[2] & Pg[1] & Gg[0]) | (Pg[3] & Pg[2] & Pg[1] & Pg[0] & Cin);

endmodule

module cla_4bit(
    input  [3:0] A,
    input  [3:0] B,
    input        Cin,
    output [3:0] S,
    output       Pg,
    output       Gg
);

    wire [3:0] P;
    wire [3:0] G;
    wire C1, C2, C3;

    assign P = A ^ B;
    assign G = A & B;

    assign C1 = G[0] | (P[0] & Cin);
    assign C2 = G[1] | (P[1] & G[0]) | (P[1] & P[0] & Cin);
    assign C3 = G[2] | (P[2] & G[1]) | (P[2] & P[1] & G[0]) | (P[2] & P[1] & P[0] & Cin);

    assign S[0] = P[0] ^ Cin;
    assign S[1] = P[1] ^ C1;
    assign S[2] = P[2] ^ C2;
    assign S[3] = P[3] ^ C3;

    assign Pg = P[3] & P[2] & P[1] & P[0];
    assign Gg = G[3] | (P[3] & G[2]) | (P[3] & P[2] & G[1]) | (P[3] & P[2] & P[1] & G[0]);

endmodule
