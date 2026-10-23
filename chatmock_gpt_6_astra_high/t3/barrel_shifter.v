module barrel_shifter (
    input  wire [7:0] in,
    input  wire [2:0] ctrl,
    output wire [7:0] out
);

    wire [7:0] stage4;
    wire [7:0] stage2;

    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : gen_rotate
            mux2X1 mux_stage4 (
                .a   (in[i]),
                .b   (in[(i + 4) % 8]),
                .sel (ctrl[2]),
                .y   (stage4[i])
            );

            mux2X1 mux_stage2 (
                .a   (stage4[i]),
                .b   (stage4[(i + 2) % 8]),
                .sel (ctrl[1]),
                .y   (stage2[i])
            );

            mux2X1 mux_stage1 (
                .a   (stage2[i]),
                .b   (stage2[(i + 1) % 8]),
                .sel (ctrl[0]),
                .y   (out[i])
            );
        end
    endgenerate

endmodule

module mux2X1 (
    input  wire a,
    input  wire b,
    input  wire sel,
    output wire y
);

    assign y = sel ? b : a;

endmodule
