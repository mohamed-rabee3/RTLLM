module add_low_power(
    input  [15:0] a,
    input  [15:0] b,
    output [16:0] result
);

    wire [16:0] aa;
    wire [16:0] bb;
    wire [17:0] carry;

    assign aa = {1'b0, a};
    assign bb = {1'b0, b};

    assign carry[0] = 1'b0;

    genvar i;
    generate
        for (i = 0; i < 17; i = i + 1) begin : rca
            assign result[i] = aa[i] ^ bb[i] ^ carry[i];
            assign carry[i+1] = (aa[i] & bb[i]) |
                                (aa[i] & carry[i]) |
                                (bb[i] & carry[i]);
        end
    endgenerate

endmodule
