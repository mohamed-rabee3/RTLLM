module adder_bcd(
    input  [3:0] A,
    input  [3:0] B,
    input        Cin,
    output [3:0] Sum,
    output       Cout
);

    wire [4:0] binary_sum;
    wire [4:0] corrected_sum;
    wire       correction;

    assign binary_sum = {1'b0, A} + {1'b0, B} + Cin;
    assign correction = (binary_sum > 5'd9);
    assign corrected_sum = binary_sum + (correction ? 5'd6 : 5'd0);

    assign Sum  = corrected_sum[3:0];
    assign Cout = corrected_sum[4];

endmodule
