module mux2X1(
    input a,
    input b,
    input sel,
    output y
);
    assign y = sel ? b : a;
endmodule

module barrel_shifter(
    input [7:0] in,
    input [2:0] ctrl,
    output [7:0] out
);
    wire [7:0] stage1;
    wire [7:0] stage2;
    wire [7:0] stage3;

    // Stage 1: rotate right by 4 if ctrl[2] is high
    mux2X1 m0(in[0], in[4], ctrl[2], stage1[0]);
    mux2X1 m1(in[1], in[5], ctrl[2], stage1[1]);
    mux2X1 m2(in[2], in[6], ctrl[2], stage1[2]);
    mux2X1 m3(in[3], in[7], ctrl[2], stage1[3]);
    mux2X1 m4(in[4], in[0], ctrl[2], stage1[4]);
    mux2X1 m5(in[5], in[1], ctrl[2], stage1[5]);
    mux2X1 m6(in[6], in[2], ctrl[2], stage1[6]);
    mux2X1 m7(in[7], in[3], ctrl[2], stage1[7]);

    // Stage 2: rotate right by 2 if ctrl[1] is high
    mux2X1 m8(stage1[0], stage1[2], ctrl[1], stage2[0]);
    mux2X1 m9(stage1[1], stage1[3], ctrl[1], stage2[1]);
    mux2X1 m10(stage1[2], stage1[4], ctrl[1], stage2[2]);
    mux2X1 m11(stage1[3], stage1[5], ctrl[1], stage2[3]);
    mux2X1 m12(stage1[4], stage1[6], ctrl[1], stage2[4]);
    mux2X1 m13(stage1[5], stage1[7], ctrl[1], stage2[5]);
    mux2X1 m14(stage1[6], stage1[0], ctrl[1], stage2[6]);
    mux2X1 m15(stage1[7], stage1[1], ctrl[1], stage2[7]);

    // Stage 3: rotate right by 1 if ctrl[0] is high
    mux2X1 m16(stage2[0], stage2[1], ctrl[0], stage3[0]);
    mux2X1 m17(stage2[1], stage2[2], ctrl[0], stage3[1]);
    mux2X1 m18(stage2[2], stage2[3], ctrl[0], stage3[2]);
    mux2X1 m19(stage2[3], stage2[4], ctrl[0], stage3[3]);
    mux2X1 m20(stage2[4], stage2[5], ctrl[0], stage3[4]);
    mux2X1 m21(stage2[5], stage2[6], ctrl[0], stage3[5]);
    mux2X1 m22(stage2[6], stage2[7], ctrl[0], stage3[6]);
    mux2X1 m23(stage2[7], stage2[0], ctrl[0], stage3[7]);

    assign out = stage3;
endmodule
