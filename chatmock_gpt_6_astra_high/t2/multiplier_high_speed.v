module mul_fast (
    input  wire [15:0] a,
    input  wire [15:0] b,
    output wire [31:0] result
);

    wire [31:0] pp     [0:15];
    wire [31:0] stage1 [0:10];
    wire [31:0] stage2 [0:7];
    wire [31:0] stage3 [0:5];
    wire [31:0] stage4 [0:3];
    wire [31:0] stage5 [0:2];
    wire [31:0] stage6 [0:1];

    genvar i;
    generate
        // Sixteen zero-extended, shifted partial products.
        for (i = 0; i < 16; i = i + 1) begin : gen_pp
            assign pp[i] = ({16'b0, a} & {32{b[i]}}) << i;
        end

        // Carry-save reduction: 16 operands -> 11 operands.
        for (i = 0; i < 5; i = i + 1) begin : gen_stage1
            assign stage1[2*i] =
                pp[3*i] ^ pp[3*i+1] ^ pp[3*i+2];
            assign stage1[2*i+1] =
                ((pp[3*i]   & pp[3*i+1]) |
                 (pp[3*i]   & pp[3*i+2]) |
                 (pp[3*i+1] & pp[3*i+2])) << 1;
        end
        assign stage1[10] = pp[15];

        // 11 operands -> 8 operands.
        for (i = 0; i < 3; i = i + 1) begin : gen_stage2
            assign stage2[2*i] =
                stage1[3*i] ^ stage1[3*i+1] ^ stage1[3*i+2];
            assign stage2[2*i+1] =
                ((stage1[3*i]   & stage1[3*i+1]) |
                 (stage1[3*i]   & stage1[3*i+2]) |
                 (stage1[3*i+1] & stage1[3*i+2])) << 1;
        end
        assign stage2[6] = stage1[9];
        assign stage2[7] = stage1[10];

        // 8 operands -> 6 operands.
        for (i = 0; i < 2; i = i + 1) begin : gen_stage3
            assign stage3[2*i] =
                stage2[3*i] ^ stage2[3*i+1] ^ stage2[3*i+2];
            assign stage3[2*i+1] =
                ((stage2[3*i]   & stage2[3*i+1]) |
                 (stage2[3*i]   & stage2[3*i+2]) |
                 (stage2[3*i+1] & stage2[3*i+2])) << 1;
        end
        assign stage3[4] = stage2[6];
        assign stage3[5] = stage2[7];

        // 6 operands -> 4 operands.
        for (i = 0; i < 2; i = i + 1) begin : gen_stage4
            assign stage4[2*i] =
                stage3[3*i] ^ stage3[3*i+1] ^ stage3[3*i+2];
            assign stage4[2*i+1] =
                ((stage3[3*i]   & stage3[3*i+1]) |
                 (stage3[3*i]   & stage3[3*i+2]) |
                 (stage3[3*i+1] & stage3[3*i+2])) << 1;
        end
    endgenerate

    // 4 operands -> 3 operands.
    assign stage5[0] = stage4[0] ^ stage4[1] ^ stage4[2];
    assign stage5[1] = ((stage4[0] & stage4[1]) |
                        (stage4[0] & stage4[2]) |
                        (stage4[1] & stage4[2])) << 1;
    assign stage5[2] = stage4[3];

    // 3 operands -> 2 operands.
    assign stage6[0] = stage5[0] ^ stage5[1] ^ stage5[2];
    assign stage6[1] = ((stage5[0] & stage5[1]) |
                        (stage5[0] & stage5[2]) |
                        (stage5[1] & stage5[2])) << 1;

    // Single final carry-propagate addition.
    assign result = stage6[0] + stage6[1];

endmodule
