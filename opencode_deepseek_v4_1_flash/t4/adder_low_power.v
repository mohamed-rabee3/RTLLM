module add_low_power (
    input  [15:0] a,
    input  [15:0] b,
    output [16:0] result
);

    wire [16:0] sum;
    wire [16:0] carry;

    // Bit 0
    assign sum[0]   = a[0] ^ b[0];
    assign carry[1] = a[0] & b[0];

    // Bits 1 to 15
    genvar i;
    generate
        for (i = 1; i < 16; i = i + 1) begin : ripple_carry
            assign sum[i]     = a[i] ^ b[i] ^ carry[i];
            assign carry[i+1] = (a[i] & b[i]) | (a[i] & carry[i]) | (b[i] & carry[i]);
        end
    endgenerate

    // Bit 16: operands are zero-extended, so sum[16] is the final carry
    assign sum[16] = carry[16];

    assign result = sum;

endmodule
