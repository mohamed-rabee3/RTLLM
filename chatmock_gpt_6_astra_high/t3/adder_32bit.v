module adder_32bit (
    input  wire [32:1] A,
    input  wire [32:1] B,
    output wire [32:1] S,
    output wire        C32
);

    wire p_low, g_low;
    wire p_high, g_high;
    wire c16;

    assign c16 = g_low;
    assign C32 = g_high | (p_high & g_low);

    cla_16bit u_low (
        .A      (A[16:1]),
        .B      (B[16:1]),
        .Cin    (1'b0),
        .S      (S[16:1]),
        .Cout   (),
        .Pgroup (p_low),
        .Ggroup (g_low)
    );

    cla_16bit u_high (
        .A      (A[32:17]),
        .B      (B[32:17]),
        .Cin    (c16),
        .S      (S[32:17]),
        .Cout   (),
        .Pgroup (p_high),
        .Ggroup (g_high)
    );

endmodule


module cla_16bit (
    input  wire [16:1] A,
    input  wire [16:1] B,
    input  wire        Cin,
    output wire [16:1] S,
    output wire        Cout,
    output wire        Pgroup,
    output wire        Ggroup
);

    wire [3:0] group_p;
    wire [3:0] group_g;
    wire [4:0] group_c;

    assign Pgroup = group_p[3] & group_p[2]
                  & group_p[1] & group_p[0];

    assign Ggroup = group_g[3]
                  | (group_p[3] & group_g[2])
                  | (group_p[3] & group_p[2] & group_g[1])
                  | (group_p[3] & group_p[2]
                     & group_p[1] & group_g[0]);

    assign group_c[0] = Cin;

    assign group_c[1] = group_g[0]
                      | (group_p[0] & Cin);

    assign group_c[2] = group_g[1]
                      | (group_p[1] & group_g[0])
                      | (group_p[1] & group_p[0] & Cin);

    assign group_c[3] = group_g[2]
                      | (group_p[2] & group_g[1])
                      | (group_p[2] & group_p[1] & group_g[0])
                      | (group_p[2] & group_p[1]
                         & group_p[0] & Cin);

    assign group_c[4] = Ggroup | (Pgroup & Cin);
    assign Cout = group_c[4];

    genvar k;
    generate
        for (k = 0; k < 4; k = k + 1) begin : gen_cla_group
            wire [3:0] p;
            wire [3:0] g;
            wire [3:0] c;

            assign p = A[4*k+4:4*k+1] ^ B[4*k+4:4*k+1];
            assign g = A[4*k+4:4*k+1] & B[4*k+4:4*k+1];

            assign group_p[k] = p[3] & p[2] & p[1] & p[0];

            assign group_g[k] = g[3]
                              | (p[3] & g[2])
                              | (p[3] & p[2] & g[1])
                              | (p[3] & p[2] & p[1] & g[0]);

            assign c[0] = group_c[k];

            assign c[1] = g[0]
                        | (p[0] & group_c[k]);

            assign c[2] = g[1]
                        | (p[1] & g[0])
                        | (p[1] & p[0] & group_c[k]);

            assign c[3] = g[2]
                        | (p[2] & g[1])
                        | (p[2] & p[1] & g[0])
                        | (p[2] & p[1] & p[0] & group_c[k]);

            assign S[4*k+4:4*k+1] = p ^ c;
        end
    endgenerate

endmodule
