module mul_low_power(
    input  [15:0] a,
    input  [15:0] b,
    output [31:0] result
);

    wire [31:0] pp [0:15];
    genvar i;

    generate
        for (i = 0; i < 16; i = i + 1) begin : gen_partial_products
            assign pp[i] = ({16'b0, a} << i) & {32{b[i]}};
        end
    endgenerate

    wire [31:0] s0, s1, s2, s3, s4, s5, s6, s7;
    wire [31:0] t0, t1, t2, t3;
    wire [31:0] u0, u1;

    assign s0 = pp[0] + pp[1];
    assign s1 = pp[2] + pp[3];
    assign s2 = pp[4] + pp[5];
    assign s3 = pp[6] + pp[7];
    assign s4 = pp[8] + pp[9];
    assign s5 = pp[10] + pp[11];
    assign s6 = pp[12] + pp[13];
    assign s7 = pp[14] + pp[15];

    assign t0 = s0 + s1;
    assign t1 = s2 + s3;
    assign t2 = s4 + s5;
    assign t3 = s6 + s7;

    assign u0 = t0 + t1;
    assign u1 = t2 + t3;

    assign result = u0 + u1;

endmodule
