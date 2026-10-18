module adder_8bit (
    input  [7:0] A,
    input  [7:0] B,
    input        Cin,
    output [7:0] Y,
    output       Cout
);

    assign {Cout, Y} = A + B + Cin;

endmodule

module adder_16bit (
    input  [15:0] a,
    input  [15:0] b,
    input         Cin,
    output [15:0] y,
    output        Co
);

    wire carry_mid;

    adder_8bit u_adder_low (
        .A    (a[7:0]),
        .B    (b[7:0]),
        .Cin  (Cin),
        .Y    (y[7:0]),
        .Cout (carry_mid)
    );

    adder_8bit u_adder_high (
        .A    (a[15:8]),
        .B    (b[15:8]),
        .Cin  (carry_mid),
        .Y    (y[15:8]),
        .Cout (Co)
    );

endmodule
