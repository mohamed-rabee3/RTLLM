module barrel_shifter(
    input [7:0] in,
    input [2:0] ctrl,
    output [7:0] out
);

    wire [7:0] s4;
    wire [7:0] s2;
    wire [7:0] shift4;
    wire [7:0] shift2;
    wire [7:0] shift1;

    assign shift4 = {in[3:0], in[7:4]};
    assign shift2 = {s4[5:0], s4[7:6]};
    assign shift1 = {s2[6:0], s2[7]};

    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : stage4
            mux2X1 mux4 (
                .y(s4[i]),
                .a(in[i]),
                .b(shift4[i]),
                .sel(ctrl[2])
            );
        end
        for (i = 0; i < 8; i = i + 1) begin : stage2
            mux2X1 mux2 (
                .y(s2[i]),
                .a(s4[i]),
                .b(shift2[i]),
                .sel(ctrl[1])
            );
        end
        for (i = 0; i < 8; i = i + 1) begin : stage1
            mux2X1 mux1 (
                .y(out[i]),
                .a(s2[i]),
                .b(shift1[i]),
                .sel(ctrl[0])
            );
        end
    endgenerate

endmodule

module mux2X1(
    output y,
    input a,
    input b,
    input sel
);
    assign y = sel ? b : a;
endmodule
