module adder_bcd(
    input  [3:0] A,
    input  [3:0] B,
    input        Cin,
    output [3:0] Sum,
    output       Cout
);

    wire [4:0] sum_bin;
    wire       correction;

    assign sum_bin = {1'b0, A} + {1'b0, B} + Cin;

    assign correction = (sum_bin > 5'd9);

    assign Cout = correction;

    assign Sum = correction ? (sum_bin[3:0] + 4'd6) : sum_bin[3:0];

endmodule
