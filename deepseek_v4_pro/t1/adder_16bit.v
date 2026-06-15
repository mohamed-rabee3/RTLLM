// 8-bit full adder module
module adder_8bit (
    input [7:0] a,
    input [7:0] b,
    input Cin,
    output [7:0] y,
    output Co
);
    // Combinational addition
    assign {Co, y} = a + b + Cin;
endmodule

// 16-bit full adder using two 8-bit adders
module adder_16bit (
    input [15:0] a,
    input [15:0] b,
    input Cin,
    output [15:0] y,
    output Co
);
    // Internal carry between the two 8-bit adders
    wire c8;

    // Lower 8 bits: a[7:0] + b[7:0] + Cin
    adder_8bit lower_adder (
        .a   (a[7:0]),
        .b   (b[7:0]),
        .Cin (Cin),
        .y   (y[7:0]),
        .Co  (c8)
    );

    // Upper 8 bits: a[15:8] + b[15:8] + c8
    adder_8bit upper_adder (
        .a   (a[15:8]),
        .b   (b[15:8]),
        .Cin (c8),
        .y   (y[15:8]),
        .Co  (Co)
    );
endmodule