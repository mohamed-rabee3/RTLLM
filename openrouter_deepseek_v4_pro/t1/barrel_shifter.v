// 2-to-1 multiplexer submodule
module mux2X1 (
    input  a,
    input  b,
    input  sel,
    output y
);
    assign y = sel ? b : a;
endmodule

// 8-bit barrel shifter (rotator)
module barrel_shifter (
    input  [7:0] in,
    input  [2:0] ctrl,
    output [7:0] out
);
    // Intermediate wires after each stage
    wire [7:0] stage1, stage2;

    // Pre-computed rotated versions for each stage
    wire [7:0] shift4 = {in[3:0], in[7:4]};          // rotate left by 4
    wire [7:0] shift2 = {stage1[1:0], stage1[7:2]};  // rotate left by 2
    wire [7:0] shift1 = {stage2[0], stage2[7:1]};    // rotate left by 1

    genvar i;

    // Stage 1: shift by 4 if ctrl[2] is high
    generate
        for (i = 0; i < 8; i = i + 1) begin : stage1_mux
            mux2X1 mux (
                .a(in[i]),
                .b(shift4[i]),
                .sel(ctrl[2]),
                .y(stage1[i])
            );
        end
    endgenerate

    // Stage 2: shift by 2 if ctrl[1] is high
    generate
        for (i = 0; i < 8; i = i + 1) begin : stage2_mux
            mux2X1 mux (
                .a(stage1[i]),
                .b(shift2[i]),
                .sel(ctrl[1]),
                .y(stage2[i])
            );
        end
    endgenerate

    // Stage 3: shift by 1 if ctrl[0] is high
    generate
        for (i = 0; i < 8; i = i + 1) begin : stage3_mux
            mux2X1 mux (
                .a(stage2[i]),
                .b(shift1[i]),
                .sel(ctrl[0]),
                .y(out[i])
            );
        end
    endgenerate

endmodule