module adder_bcd (
    input  [3:0] A,
    input  [3:0] B,
    input        Cin,
    output [3:0] Sum,
    output       Cout
);

    wire [4:0] binary_sum;
    wire       correction;

    assign binary_sum = A + B + Cin;

    assign correction = binary_sum[4] |
                        (binary_sum[3] & (binary_sum[2] | binary_sum[1]));

    assign Cout = correction;

    assign Sum = binary_sum[3:0] + (correction ? 4'd6 : 4'd0);

endmodule
