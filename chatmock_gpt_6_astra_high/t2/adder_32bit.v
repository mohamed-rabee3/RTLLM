module adder_32bit (
    input  wire [32:1] A,
    input  wire [32:1] B,
    output wire [32:1] S,
    output wire        C32
);
    wire C16;

    cla_16bit u_lower (
        .A    (A[16:1]),
        .B    (B[16:1]),
        .Cin  (1'b0),
        .S    (S[16:1]),
        .Cout (C16)
    );

    cla_16bit u_upper (
        .A    (A[32:17]),
        .B    (B[32:17]),
        .Cin  (C16),
        .S    (S[32:17]),
        .Cout (C32)
    );
endmodule


module cla_16bit (
    input  wire [16:1] A,
    input  wire [16:1] B,
    input  wire        Cin,
    output wire [16:1] S,
    output wire        Cout
);
    wire [3:0] P;
    wire [3:0] G;
    wire [4:0] C;

    assign C[0] = Cin;

    assign C[1] = G[0]
                | (P[0] & Cin);

    assign C[2] = G[1]
                | (P[1] & G[0])
                | (P[1] & P[0] & Cin);

    assign C[3] = G[2]
                | (P[2] & G[1])
                | (P[2] & P[1] & G[0])
                | (P[2] & P[1] & P[0] & Cin);

    assign C[4] = G[3]
                | (P[3] & G[2])
                | (P[3] & P[2] & G[1])
                | (P[3] & P[2] & P[1] & G[0])
                | (P[3] & P[2] & P[1] & P[0] & Cin);

    assign Cout = C[4];

    cla_4bit u_group0 (
        .A   (A[4:1]),
        .B   (B[4:1]),
        .Cin (C[0]),
        .S   (S[4:1]),
        .P   (P[0]),
        .G   (G[0])
    );

    cla_4bit u_group1 (
        .A   (A[8:5]),
        .B   (B[8:5]),
        .Cin (C[1]),
        .S   (S[8:5]),
        .P   (P[1]),
        .G   (G[1])
    );

    cla_4bit u_group2 (
        .A   (A[12:9]),
        .B   (B[12:9]),
        .Cin (C[2]),
        .S   (S[12:9]),
        .P   (P[2]),
        .G   (G[2])
    );

    cla_4bit u_group3 (
        .A   (A[16:13]),
        .B   (B[16:13]),
        .Cin (C[3]),
        .S   (S[16:13]),
        .P   (P[3]),
        .G   (G[3])
    );
endmodule


module cla_4bit (
    input  wire [4:1] A,
    input  wire [4:1] B,
    input  wire       Cin,
    output wire [4:1] S,
    output wire       P,
    output wire       G
);
    wire [4:1] p;
    wire [4:1] g;
    wire [3:0] c;

    assign p = A ^ B;
    assign g = A & B;

    assign c[0] = Cin;

    assign c[1] = g[1]
                | (p[1] & Cin);

    assign c[2] = g[2]
                | (p[2] & g[1])
                | (p[2] & p[1] & Cin);

    assign c[3] = g[3]
                | (p[3] & g[2])
                | (p[3] & p[2] & g[1])
                | (p[3] & p[2] & p[1] & Cin);

    assign S = p ^ c;

    assign P = p[4] & p[3] & p[2] & p[1];

    assign G = g[4]
             | (p[4] & g[3])
             | (p[4] & p[3] & g[2])
             | (p[4] & p[3] & p[2] & g[1]);
endmodule
