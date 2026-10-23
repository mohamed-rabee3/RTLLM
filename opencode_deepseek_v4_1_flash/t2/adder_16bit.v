module adder_8bit(
    input  [7:0] a,
    input  [7:0] b,
    input        cin,
    output [7:0] sum,
    output       cout
);
    assign {cout, sum} = a + b + cin;
endmodule

module adder_16bit(
    input  [15:0] a,
    input  [15:0] b,
    input         Cin,
    output [15:0] y,
    output        Co
);
    wire carry_mid;

    adder_8bit u_adder_low(
        .a(a[7:0]),
        .b(b[7:0]),
        .cin(Cin),
        .sum(y[7:0]),
        .cout(carry_mid)
    );

    adder_8bit u_adder_high(
        .a(a[15:8]),
        .b(b[15:8]),
        .cin(carry_mid),
        .sum(y[15:8]),
        .cout(Co)
    );
endmodule
