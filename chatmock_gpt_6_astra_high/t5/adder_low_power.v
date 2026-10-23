module add_low_power (
    input  wire [15:0] a,
    input  wire [15:0] b,
    output wire [16:0] result
);
    wire [16:0] carry;

    assign carry[0] = 1'b0;

    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : gen_adder
            wire propagate;
            assign propagate = a[i] ^ b[i];
            assign result[i] = propagate ^ carry[i];
            assign carry[i+1] = (a[i] & b[i]) | (propagate & carry[i]);
        end
    endgenerate

    assign result[16] = carry[16];
endmodule
