module add_low_area (
    input  [15:0] a,
    input  [15:0] b,
    output [16:0] result
);

    wire [16:0] carry;

    assign carry[0] = 1'b0;

    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : fa_chain
            wire sum_bit;
            assign sum_bit = a[i] ^ b[i] ^ carry[i];
            assign carry[i+1] = (a[i] & b[i]) | (a[i] & carry[i]) | (b[i] & carry[i]);
            assign result[i] = sum_bit;
        end
    endgenerate

    assign result[16] = carry[16];

endmodule
