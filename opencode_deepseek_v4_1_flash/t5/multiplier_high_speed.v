module mul_fast (
    input  wire [15:0] a,
    input  wire [15:0] b,
    output wire [31:0] result
);

    // Generate the 16 partial products
    wire [31:0] pp [0:15];
    genvar j;
    generate
        for (j = 0; j < 16; j = j + 1) begin : gen_pp
            assign pp[j] = ({16'b0, a} & {32{b[j]}}) << j;
        end
    endgenerate

    // Stage 1: reduce 16 rows to 11 rows
    wire [31:0] s1_0, c1_0, c1_0_s;
    assign s1_0 = pp[0] ^ pp[1] ^ pp[2];
    assign c1_0 = (pp[0] & pp[1]) | (pp[1] & pp[2]) | (pp[0] & pp[2]);
    assign c1_0_s = c1_0 << 1;

    wire [31:0] s1_1, c1_1, c1_1_s;
    assign s1_1 = pp[3] ^ pp[4] ^ pp[5];
    assign c1_1 = (pp[3] & pp[4]) | (pp[4] & pp[5]) | (pp[3] & pp[5]);
    assign c1_1_s = c1_1 << 1;

    wire [31:0] s1_2, c1_2, c1_2_s;
    assign s1_2 = pp[6] ^ pp[7] ^ pp[8];
    assign c1_2 = (pp[6] & pp[7]) | (pp[7] & pp[8]) | (pp[6] & pp[8]);
    assign c1_2_s = c1_2 << 1;

    wire [31:0] s1_3, c1_3, c1_3_s;
    assign s1_3 = pp[9] ^ pp[10] ^ pp[11];
    assign c1_3 = (pp[9] & pp[10]) | (pp[10] & pp[11]) | (pp[9] & pp[11]);
    assign c1_3_s = c1_3 << 1;

    wire [31:0] s1_4, c1_4, c1_4_s;
    assign s1_4 = pp[12] ^ pp[13] ^ pp[14];
    assign c1_4 = (pp[12] & pp[13]) | (pp[13] & pp[14]) | (pp[12] & pp[14]);
    assign c1_4_s = c1_4 << 1;

    // Stage 2: reduce 11 rows to 8 rows
    wire [31:0] s2_0, c2_0, c2_0_s;
    assign s2_0 = s1_0 ^ c1_0_s ^ s1_1;
    assign c2_0 = (s1_0 & c1_0_s) | (c1_0_s & s1_1) | (s1_0 & s1_1);
    assign c2_0_s = c2_0 << 1;

    wire [31:0] s2_1, c2_1, c2_1_s;
    assign s2_1 = c1_1_s ^ s1_2 ^ c1_2_s;
    assign c2_1 = (c1_1_s & s1_2) | (s1_2 & c1_2_s) | (c1_1_s & c1_2_s);
    assign c2_1_s = c2_1 << 1;

    wire [31:0] s2_2, c2_2, c2_2_s;
    assign s2_2 = s1_3 ^ c1_3_s ^ s1_4;
    assign c2_2 = (s1_3 & c1_3_s) | (c1_3_s & s1_4) | (s1_3 & s1_4);
    assign c2_2_s = c2_2 << 1;

    // Stage 3: reduce 8 rows to 6 rows
    wire [31:0] s3_0, c3_0, c3_0_s;
    assign s3_0 = s2_0 ^ c2_0_s ^ s2_1;
    assign c3_0 = (s2_0 & c2_0_s) | (c2_0_s & s2_1) | (s2_0 & s2_1);
    assign c3_0_s = c3_0 << 1;

    wire [31:0] s3_1, c3_1, c3_1_s;
    assign s3_1 = c2_1_s ^ s2_2 ^ c2_2_s;
    assign c3_1 = (c2_1_s & s2_2) | (s2_2 & c2_2_s) | (c2_1_s & c2_2_s);
    assign c3_1_s = c3_1 << 1;

    // Stage 4: reduce 6 rows to 4 rows
    wire [31:0] s4_0, c4_0, c4_0_s;
    assign s4_0 = s3_0 ^ c3_0_s ^ s3_1;
    assign c4_0 = (s3_0 & c3_0_s) | (c3_0_s & s3_1) | (s3_0 & s3_1);
    assign c4_0_s = c4_0 << 1;

    wire [31:0] s4_1, c4_1, c4_1_s;
    assign s4_1 = c3_1_s ^ c1_4_s ^ pp[15];
    assign c4_1 = (c3_1_s & c1_4_s) | (c1_4_s & pp[15]) | (c3_1_s & pp[15]);
    assign c4_1_s = c4_1 << 1;

    // Stage 5: reduce 4 rows to 3 rows
    wire [31:0] s5_0, c5_0, c5_0_s;
    assign s5_0 = s4_0 ^ c4_0_s ^ s4_1;
    assign c5_0 = (s4_0 & c4_0_s) | (c4_0_s & s4_1) | (s4_0 & s4_1);
    assign c5_0_s = c5_0 << 1;

    // Stage 6: reduce 3 rows to 2 rows
    wire [31:0] s6_0, c6_0, c6_0_s;
    assign s6_0 = s5_0 ^ c5_0_s ^ c4_1_s;
    assign c6_0 = (s5_0 & c5_0_s) | (c5_0_s & c4_1_s) | (s5_0 & c4_1_s);
    assign c6_0_s = c6_0 << 1;

    // Final addition
    assign result = s6_0 + c6_0_s;

endmodule
