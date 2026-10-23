module mul_low_power (
    input  [15:0] a,
    input  [15:0] b,
    output [31:0] result
);

    wire [31:0] a_ext;
    assign a_ext = {16'b0, a};

    wire [31:0] pp0;
    wire [31:0] pp1;
    wire [31:0] pp2;
    wire [31:0] pp3;
    wire [31:0] pp4;
    wire [31:0] pp5;
    wire [31:0] pp6;
    wire [31:0] pp7;
    wire [31:0] pp8;
    wire [31:0] pp9;
    wire [31:0] pp10;
    wire [31:0] pp11;
    wire [31:0] pp12;
    wire [31:0] pp13;
    wire [31:0] pp14;
    wire [31:0] pp15;

    assign pp0  = b[0]  ? (a_ext)         : 32'b0;
    assign pp1  = b[1]  ? (a_ext << 1)    : 32'b0;
    assign pp2  = b[2]  ? (a_ext << 2)    : 32'b0;
    assign pp3  = b[3]  ? (a_ext << 3)    : 32'b0;
    assign pp4  = b[4]  ? (a_ext << 4)    : 32'b0;
    assign pp5  = b[5]  ? (a_ext << 5)    : 32'b0;
    assign pp6  = b[6]  ? (a_ext << 6)    : 32'b0;
    assign pp7  = b[7]  ? (a_ext << 7)    : 32'b0;
    assign pp8  = b[8]  ? (a_ext << 8)    : 32'b0;
    assign pp9  = b[9]  ? (a_ext << 9)    : 32'b0;
    assign pp10 = b[10] ? (a_ext << 10)   : 32'b0;
    assign pp11 = b[11] ? (a_ext << 11)   : 32'b0;
    assign pp12 = b[12] ? (a_ext << 12)   : 32'b0;
    assign pp13 = b[13] ? (a_ext << 13)   : 32'b0;
    assign pp14 = b[14] ? (a_ext << 14)   : 32'b0;
    assign pp15 = b[15] ? (a_ext << 15)   : 32'b0;

    assign result = pp0 + pp1 + pp2 + pp3 + pp4 + pp5 + pp6 + pp7 +
                    pp8 + pp9 + pp10 + pp11 + pp12 + pp13 + pp14 + pp15;

endmodule
