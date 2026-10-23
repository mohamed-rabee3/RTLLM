module mux2X1(
    input wire i0,
    input wire i1,
    input wire sel,
    output wire out
);
    assign out = sel ? i1 : i0;
endmodule

module barrel_shifter(
    input wire [7:0] in,
    input wire [2:0] ctrl,
    output wire [7:0] out
);

    wire [7:0] stage1;
    wire [7:0] stage2;

    // Stage 1: shift by 4 positions if ctrl[2] is high
    mux2X1 m0  (.i0(in[0]),      .i1(in[4]),      .sel(ctrl[2]), .out(stage1[0]));
    mux2X1 m1  (.i0(in[1]),      .i1(in[5]),      .sel(ctrl[2]), .out(stage1[1]));
    mux2X1 m2  (.i0(in[2]),      .i1(in[6]),      .sel(ctrl[2]), .out(stage1[2]));
    mux2X1 m3  (.i0(in[3]),      .i1(in[7]),      .sel(ctrl[2]), .out(stage1[3]));
    mux2X1 m4  (.i0(in[4]),      .i1(in[0]),      .sel(ctrl[2]), .out(stage1[4]));
    mux2X1 m5  (.i0(in[5]),      .i1(in[1]),      .sel(ctrl[2]), .out(stage1[5]));
    mux2X1 m6  (.i0(in[6]),      .i1(in[2]),      .sel(ctrl[2]), .out(stage1[6]));
    mux2X1 m7  (.i0(in[7]),      .i1(in[3]),      .sel(ctrl[2]), .out(stage1[7]));

    // Stage 2: shift by 2 positions if ctrl[1] is high
    mux2X1 m8  (.i0(stage1[0]),  .i1(stage1[2]),  .sel(ctrl[1]), .out(stage2[0]));
    mux2X1 m9  (.i0(stage1[1]),  .i1(stage1[3]),  .sel(ctrl[1]), .out(stage2[1]));
    mux2X1 m10 (.i0(stage1[2]),  .i1(stage1[4]),  .sel(ctrl[1]), .out(stage2[2]));
    mux2X1 m11 (.i0(stage1[3]),  .i1(stage1[5]),  .sel(ctrl[1]), .out(stage2[3]));
    mux2X1 m12 (.i0(stage1[4]),  .i1(stage1[6]),  .sel(ctrl[1]), .out(stage2[4]));
    mux2X1 m13 (.i0(stage1[5]),  .i1(stage1[7]),  .sel(ctrl[1]), .out(stage2[5]));
    mux2X1 m14 (.i0(stage1[6]),  .i1(stage1[0]),  .sel(ctrl[1]), .out(stage2[6]));
    mux2X1 m15 (.i0(stage1[7]),  .i1(stage1[1]),  .sel(ctrl[1]), .out(stage2[7]));

    // Stage 3: shift by 1 position if ctrl[0] is high
    mux2X1 m16 (.i0(stage2[0]),  .i1(stage2[1]),  .sel(ctrl[0]), .out(out[0]));
    mux2X1 m17 (.i0(stage2[1]),  .i1(stage2[2]),  .sel(ctrl[0]), .out(out[1]));
    mux2X1 m18 (.i0(stage2[2]),  .i1(stage2[3]),  .sel(ctrl[0]), .out(out[2]));
    mux2X1 m19 (.i0(stage2[3]),  .i1(stage2[4]),  .sel(ctrl[0]), .out(out[3]));
    mux2X1 m20 (.i0(stage2[4]),  .i1(stage2[5]),  .sel(ctrl[0]), .out(out[4]));
    mux2X1 m21 (.i0(stage2[5]),  .i1(stage2[6]),  .sel(ctrl[0]), .out(out[5]));
    mux2X1 m22 (.i0(stage2[6]),  .i1(stage2[7]),  .sel(ctrl[0]), .out(out[6]));
    mux2X1 m23 (.i0(stage2[7]),  .i1(stage2[0]),  .sel(ctrl[0]), .out(out[7]));

endmodule
