module adder_bcd (
    input  [3:0] A,
    input  [3:0] B,
    input        Cin,
    output [3:0] Sum,
    output       Cout
);

    // Binary addition of A, B, and Cin. Produce a 5-bit intermediate sum.
    wire [4:0] sum_temp;
    assign sum_temp = A + B + Cin;

    // BCD correction condition: correction needed if binary sum exceeds 9.
    wire condition;
    assign condition = (sum_temp > 5'd9);

    // Apply correction (add 6) when condition is true.
    wire [4:0] result;
    assign result = sum_temp + (condition ? 5'd6 : 5'd0);

    // Extract output carry and BCD sum.
    assign Cout = result[4];
    assign Sum  = result[3:0];

endmodule