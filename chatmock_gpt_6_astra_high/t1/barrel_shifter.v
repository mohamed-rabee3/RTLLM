module barrel_shifter (
    input  wire [7:0] in,
    input  wire [2:0] ctrl,
    output wire [7:0] out
);

    wire [7:0] stage4;
    wire [7:0] stage2;

    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : shift_stages
            // Rotate right by 4 positions when ctrl[2] is asserted.
            mux2X1 mux_shift4 (
                .in0 (in[i]),
                .in1 (in[(i + 4) % 8]),
                .sel (ctrl[2]),
                .out (stage4[i])
            );

            // Rotate right by 2 positions when ctrl[1] is asserted.
            mux2X1 mux_shift2 (
                .in0 (stage4[i]),
                .in1 (stage4[(i + 2) % 8]),
                .sel (ctrl[1]),
                .out (stage2[i])
            );

            // Rotate right by 1 position when ctrl[0] is asserted.
            mux2X1 mux_shift1 (
                .in0 (stage2[i]),
                .in1 (stage2[(i + 1) % 8]),
                .sel (ctrl[0]),
                .out (out[i])
            );
        end
    endgenerate

endmodule

module mux2X1 (
    input  wire in0,
    input  wire in1,
    input  wire sel,
    output wire out
);

    assign out = sel ? in1 : in0;

endmodule
