module add_low_power (
    input  wire [15:0] a,
    input  wire [15:0] b,
    output wire [16:0] result
);

    wire [16:0] carry;
    wire [15:0] propagate;

    assign carry[0] = 1'b0;

    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : gen_ripple
            assign propagate[i] = a[i] ^ b[i];
            assign result[i] = propagate[i] ^ carry[i];
            assign carry[i+1] = (a[i] & b[i]) |
                                (propagate[i] & carry[i]);
        end
    endgenerate

    assign result[16] = carry[16];

endmodule
