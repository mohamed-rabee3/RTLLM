module adder_32bit (
    input  wire [32:1] A,
    input  wire [32:1] B,
    output wire [32:1] S,
    output wire        C32
);

    wire C16;

    adder_cla16 u_low (
        .A    (A[16:1]),
        .B    (B[16:1]),
        .Cin  (1'b0),
        .S    (S[16:1]),
        .Cout (C16)
    );

    adder_cla16 u_high (
        .A    (A[32:17]),
        .B    (B[32:17]),
        .Cin  (C16),
        .S    (S[32:17]),
        .Cout (C32)
    );

endmodule


module adder_cla16 (
    input  wire [15:0] A,
    input  wire [15:0] B,
    input  wire        Cin,
    output wire [15:0] S,
    output wire        Cout
);

    wire [15:0] p;
    wire [15:0] g;
    wire [3:0]  group_p;
    wire [3:0]  group_g;
    wire [4:0]  group_c;

    assign p = A ^ B;
    assign g = A & B;

    assign group_c[0] = Cin;

    assign group_c[1] =
        group_g[0] |
        (group_p[0] & Cin);

    assign group_c[2] =
        group_g[1] |
        (group_p[1] & group_g[0]) |
        (group_p[1] & group_p[0] & Cin);

    assign group_c[3] =
        group_g[2] |
        (group_p[2] & group_g[1]) |
        (group_p[2] & group_p[1] & group_g[0]) |
        (group_p[2] & group_p[1] & group_p[0] & Cin);

    assign group_c[4] =
        group_g[3] |
        (group_p[3] & group_g[2]) |
        (group_p[3] & group_p[2] & group_g[1]) |
        (group_p[3] & group_p[2] & group_p[1] & group_g[0]) |
        (group_p[3] & group_p[2] & group_p[1] & group_p[0] & Cin);

    assign Cout = group_c[4];

    genvar k;
    generate
        for (k = 0; k < 4; k = k + 1) begin : gen_cla_group
            wire [3:0] bp;
            wire [3:0] bg;
            wire [3:0] carry;

            assign bp = p[4*k +: 4];
            assign bg = g[4*k +: 4];

            assign group_p[k] = &bp;

            assign group_g[k] =
                bg[3] |
                (bp[3] & bg[2]) |
                (bp[3] & bp[2] & bg[1]) |
                (bp[3] & bp[2] & bp[1] & bg[0]);

            assign carry[0] = group_c[k];

            assign carry[1] =
                bg[0] |
                (bp[0] & group_c[k]);

            assign carry[2] =
                bg[1] |
                (bp[1] & bg[0]) |
                (bp[1] & bp[0] & group_c[k]);

            assign carry[3] =
                bg[2] |
                (bp[2] & bg[1]) |
                (bp[2] & bp[1] & bg[0]) |
                (bp[2] & bp[1] & bp[0] & group_c[k]);

            assign S[4*k +: 4] = bp ^ carry;
        end
    endgenerate

endmodule
