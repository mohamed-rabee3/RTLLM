module adder_32bit (
    input  wire [32:1] A,
    input  wire [32:1] B,
    output wire [32:1] S,
    output wire        C32
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


module cla_16bit (
    input  wire [16:1] A,
    input  wire [16:1] B,
    input  wire        Cin,
    output wire [16:1] S,
    output wire        Cout
);

    // Parallel-prefix carry-lookahead network.
    wire [16:1] propagate [0:4];
    wire [16:1] generate_carry [0:4];
    wire [16:0] carry;

    assign propagate[0]      = A ^ B;
    assign generate_carry[0] = A & B;
    assign carry[0]         = Cin;

    genvar stage;
    genvar bit_index;
    generate
        for (stage = 1; stage <= 4; stage = stage + 1) begin : g_stage
            for (bit_index = 1; bit_index <= 16;
                 bit_index = bit_index + 1) begin : g_bit
                if (bit_index > (1 << (stage - 1))) begin : g_combine
                    assign generate_carry[stage][bit_index] =
                        generate_carry[stage-1][bit_index] |
                        (propagate[stage-1][bit_index] &
                         generate_carry[stage-1]
                                       [bit_index - (1 << (stage - 1))]);

                    assign propagate[stage][bit_index] =
                        propagate[stage-1][bit_index] &
                        propagate[stage-1]
                                 [bit_index - (1 << (stage - 1))];
                end else begin : g_pass
                    assign generate_carry[stage][bit_index] =
                        generate_carry[stage-1][bit_index];

                    assign propagate[stage][bit_index] =
                        propagate[stage-1][bit_index];
                end
            end
        end
    endgenerate

    genvar k;
    generate
        for (k = 1; k <= 16; k = k + 1) begin : g_sum
            assign carry[k] =
                generate_carry[4][k] | (propagate[4][k] & Cin);

            assign S[k] = propagate[0][k] ^ carry[k-1];
        end
    endgenerate

    assign Cout = carry[16];

endmodule
