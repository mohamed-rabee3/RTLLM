module mux2X1 (
    input  in0,
    input  in1,
    input  sel,
    output out
);
    assign out = sel ? in1 : in0;
endmodule

module barrel_shifter (
    input  [7:0] in,
    input  [2:0] ctrl,
    output [7:0] out
);

    wire [7:0] w1;
    wire [7:0] w2;

    // Stage 1: shift by 4 if ctrl[2]
    mux2X1 m4_0 (.in0(in[0]), .in1(in[4]), .sel(ctrl[2]), .out(w1[0]));
    mux2X1 m4_1 (.in0(in[1]), .in1(in[5]), .sel(ctrl[2]), .out(w1[1]));
    mux2X1 m4_2 (.in0(in[2]), .in1(in[6]), .sel(ctrl[2]), .out(w1[2]));
    mux2X1 m4_3 (.in0(in[3]), .in1(in[7]), .sel(ctrl[2]), .out(w1[3]));
    mux2X1 m4_4 (.in0(in[4]), .in1(in[0]), .sel(ctrl[2]), .out(w1[4]));
    mux2X1 m4_5 (.in0(in[5]), .in1(in[1]), .sel(ctrl[2]), .out(w1[5]));
    mux2X1 m4_6 (.in0(in[6]), .in1(in[2]), .sel(ctrl[2]), .out(w1[6]));
    mux2X1 m4_7 (.in0(in[7]), .in1(in[3]), .sel(ctrl[2]), .out(w1[7]));

    // Stage 2: shift by 2 if ctrl[1]
    mux2X1 m2_0 (.in0(w1[0]), .in1(w1[6]), .sel(ctrl[1]), .out(w2[0]));
    mux2X1 m2_1 (.in0(w1[1]), .in1(w1[7]), .sel(ctrl[1]), .out(w2[1]));
    mux2X1 m2_2 (.in0(w1[2]), .in1(w1[0]), .sel(ctrl[1]), .out(w2[2]));
    mux2X1 m2_3 (.in0(w1[3]), .in1(w1[1]), .sel(ctrl[1]), .out(w2[3]));
    mux2X1 m2_4 (.in0(w1[4]), .in1(w1[2]), .sel(ctrl[1]), .out(w2[4]));
    mux2X1 m2_5 (.in0(w1[5]), .in1(w1[3]), .sel(ctrl[1]), .out(w2[5]));
    mux2X1 m2_6 (.in0(w1[6]), .in1(w1[4]), .sel(ctrl[1]), .out(w2[6]));
    mux2X1 m2_7 (.in0(w1[7]), .in1(w1[5]), .sel(ctrl[1]), .out(w2[7]));

    // Stage 3: shift by 1 if ctrl[0]
    mux2X1 m1_0 (.in0(w2[0]), .in1(w2[7]), .sel(ctrl[0]), .out(out[0]));
    mux2X1 m1_1 (.in0(w2[1]), .in1(w2[0]), .sel(ctrl[0]), .out(out[1]));
    mux2X1 m1_2 (.in0(w2[2]), .in1(w2[1]), .sel(ctrl[0]), .out(out[2]));
    mux2X1 m1_3 (.in0(w2[3]), .in1(w2[2]), .sel(ctrl[0]), .out(out[3]));
    mux2X1 m1_4 (.in0(w2[4]), .in1(w2[3]), .sel(ctrl[0]), .out(out[4]));
    mux2X1 m1_5 (.in0(w2[5]), .in1(w2[4]), .sel(ctrl[0]), .out(out[5]));
    mux2X1 m1_6 (.in0(w2[6]), .in1(w2[5]), .sel(ctrl[0]), .out(out[6]));
    mux2X1 m1_7 (.in0(w2[7]), .in1(w2[6]), .sel(ctrl[0]), .out(out[7]));

endmodule
