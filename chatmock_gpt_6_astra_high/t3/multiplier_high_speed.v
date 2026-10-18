module mul_fast (
    input  wire [15:0] a,
    input  wire [15:0] b,
    output wire [31:0] result
);

    wire [31:0] pp [0:15];
    wire [31:0] s1 [0:10];
    wire [31:0] s2 [0:7];
    wire [31:0] s3 [0:5];
    wire [31:0] s4 [0:3];
    wire [31:0] s5 [0:2];
    wire [31:0] s6 [0:1];

    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : gen_partial_products
            assign pp[i] = ({16'b0, a} << i) & {32{b[i]}};
        end

        // Carry-save reduction: 16 operands to 11.
        for (i = 0; i < 5; i = i + 1) begin : gen_stage1
            assign s1[2*i] =
                pp[3*i] ^ pp[3*i+1] ^ pp[3*i+2];
            assign s1[2*i+1] =
                ((pp[3*i]   & pp[3*i+1]) |
                 (pp[3*i]   & pp[3*i+2]) |
                 (pp[3*i+1] & pp[3*i+2])) << 1;
        end

        // Carry-save reduction: 11 operands to 8.
        for (i = 0; i < 3; i = i + 1) begin : gen_stage2
            assign s2[2*i] =
                s1[3*i] ^ s1[3*i+1] ^ s1[3*i+2];
            assign s2[2*i+1] =
                ((s1[3*i]   & s1[3*i+1]) |
                 (s1[3*i]   & s1[3*i+2]) |
                 (s1[3*i+1] & s1[3*i+2])) << 1;
        end

        // Carry-save reduction: 8 operands to 6.
        for (i = 0; i < 2; i = i + 1) begin : gen_stage3
            assign s3[2*i] =
                s2[3*i] ^ s2[3*i+1] ^ s2[3*i+2];
            assign s3[2*i+1] =
                ((s2[3*i]   & s2[3*i+1]) |
                 (s2[3*i]   & s2[3*i+2]) |
                 (s2[3*i+1] & s2[3*i+2])) << 1;
        end

        // Carry-save reduction: 6 operands to 4.
        for (i = 0; i < 2; i = i + 1) begin : gen_stage4
            assign s4[2*i] =
                s3[3*i] ^ s3[3*i+1] ^ s3[3*i+2];
            assign s4[2*i+1] =
                ((s3[3*i]   & s3[3*i+1]) |
                 (s3[3*i]   & s3[3*i+2]) |
                 (s3[3*i+1] & s3[3*i+2])) << 1;
        end
    endgenerate

    assign s1[10] = pp[15];

    assign s2[6] = s1[9];
    assign s2[7] = s1[10];

    assign s3[4] = s2[6];
    assign s3[5] = s2[7];

    // Carry-save reduction: 4 operands to 3.
    assign s5[0] = s4[0] ^ s4[1] ^ s4[2];
    assign s5[1] = ((s4[0] & s4[1]) |
                    (s4[0] & s4[2]) |
                    (s4[1] & s4[2])) << 1;
    assign s5[2] = s4[3];

    // Carry-save reduction: 3 operands to 2.
    assign s6[0] = s5[0] ^ s5[1] ^ s5[2];
    assign s6[1] = ((s5[0] & s5[1]) |
                    (s5[0] & s5[2]) |
                    (s5[1] & s5[2])) << 1;

    // Final carry-propagate addition.
    assign result = s6[0] + s6[1];

endmodule
