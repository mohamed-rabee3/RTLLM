module adder_32bit (
    input  wire [32:1] A,
    input  wire [32:1] B,
    output wire [32:1] S,
    output wire        C32
);
    wire p_low, g_low;
    wire p_high, g_high;

    cla16_adder32 u_low (
        .A   (A[16:1]),
        .B   (B[16:1]),
        .Cin (1'b0),
        .S   (S[16:1]),
        .P   (p_low),
        .G   (g_low)
    );

    cla16_adder32 u_high (
        .A   (A[32:17]),
        .B   (B[32:17]),
        .Cin (g_low),
        .S   (S[32:17]),
        .P   (p_high),
        .G   (g_high)
    );

    assign C32 = g_high | (p_high & g_low);
endmodule


module cla16_adder32 (
    input  wire [16:1] A,
    input  wire [16:1] B,
    input  wire        Cin,
    output wire [16:1] S,
    output wire        P,
    output wire        G
);
    wire [3:0] group_p;
    wire [3:0] group_g;
    wire [3:0] carry;

    assign carry[0] = Cin;

    assign carry[1] = group_g[0]
                    | (group_p[0] & Cin);

    assign carry[2] = group_g[1]
                    | (group_p[1] & group_g[0])
                    | (group_p[1] & group_p[0] & Cin);

    assign carry[3] = group_g[2]
                    | (group_p[2] & group_g[1])
                    | (group_p[2] & group_p[1] & group_g[0])
                    | (group_p[2] & group_p[1] & group_p[0] & Cin);

    assign P = group_p[3] & group_p[2] & group_p[1] & group_p[0];

    assign G = group_g[3]
             | (group_p[3] & group_g[2])
             | (group_p[3] & group_p[2] & group_g[1])
             | (group_p[3] & group_p[2] & group_p[1] & group_g[0]);

    cla4_adder32 u_group0 (
        .A(A[4:1]), .B(B[4:1]), .Cin(carry[0]),
        .S(S[4:1]), .P(group_p[0]), .G(group_g[0])
    );

    cla4_adder32 u_group1 (
        .A(A[8:5]), .B(B[8:5]), .Cin(carry[1]),
        .S(S[8:5]), .P(group_p[1]), .G(group_g[1])
    );

    cla4_adder32 u_group2 (
        .A(A[12:9]), .B(B[12:9]), .Cin(carry[2]),
        .S(S[12:9]), .P(group_p[2]), .G(group_g[2])
    );

    cla4_adder32 u_group3 (
        .A(A[16:13]), .B(B[16:13]), .Cin(carry[3]),
        .S(S[16:13]), .P(group_p[3]), .G(group_g[3])
    );
endmodule


module cla4_adder32 (
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

    assign S = p ^ {c[3], c[2], c[1], c[0]};

    assign P = p[4] & p[3] & p[2] & p[1];

    assign G = g[4]
             | (p[4] & g[3])
             | (p[4] & p[3] & g[2])
             | (p[4] & p[3] & p[2] & g[1]);
endmodule
