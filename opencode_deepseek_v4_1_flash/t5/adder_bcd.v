module adder_bcd(
    input [3:0] A,
    input [3:0] B,
    input Cin,
    output [3:0] Sum,
    output Cout
);

    wire [4:0] temp;
    wire [3:0] corrected_sum;

    assign temp = A + B + Cin;

    assign corrected_sum = temp[3:0] + 4'b0110;

    assign Cout = (temp > 5'd9) ? 1'b1 : 1'b0;

    assign Sum = (temp > 5'd9) ? corrected_sum : temp[3:0];

endmodule
