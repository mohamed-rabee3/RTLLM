module adder_8bit(
    input  [7:0] a,
    input  [7:0] b,
    input        Cin,
    output [7:0] y,
    output       Co
);
    assign {Co, y} = a + b + Cin;
endmodule

module adder_16bit(
    input  [15:0] a,
    input  [15:0] b,
    input         Cin,
    output [15:0] y,
    output        Co
);
    wire c8;

    adder_8bit u_adder_low(
        .a(a[7:0]),
        .b(b[7:0]),
        .Cin(Cin),
        .y(y[7:0]),
        .Co(c8)
    );

    adder_8bit u_adder_high(
        .a(a[15:8]),
        .b(b[15:8]),
        .Cin(c8),
        .y(y[15:8]),
        .Co(Co)
    );
endmodule
