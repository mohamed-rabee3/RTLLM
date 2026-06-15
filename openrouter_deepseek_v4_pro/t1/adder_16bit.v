// 8-bit full adder module
module adder_8bit (
    input  [7:0] a,
    input  [7:0] b,
    input        cin,
    output [7:0] y,
    output       cout
);
    // Combinational 8-bit addition with carry
    assign {cout, y} = a + b + cin;
endmodule

// 16-bit full adder built from two 8-bit adder instances
module adder_16bit (
    input  [15:0] a,
    input  [15:0] b,
    input         Cin,
    output [15:0] y,
    output        Co
);
    // Internal carry between lower and upper 8-bit adders
    wire carry_mid;

    // Lower 8-bit adder (bits 7:0)
    adder_8bit lower (
        .a   (a[7:0]),
        .b   (b[7:0]),
        .cin (Cin),
        .y   (y[7:0]),
        .cout(carry_mid)
    );

    // Upper 8-bit adder (bits 15:8)
    adder_8bit upper (
        .a   (a[15:8]),
        .b   (b[15:8]),
        .cin (carry_mid),
        .y   (y[15:8]),
        .cout(Co)
    );
endmodule