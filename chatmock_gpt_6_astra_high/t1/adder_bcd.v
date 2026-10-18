module adder_bcd (
    input  wire [3:0] A,
    input  wire [3:0] B,
    input  wire       Cin,
    output wire [3:0] Sum,
    output wire       Cout
);

    wire [4:0] binary_sum;
    wire [4:0] corrected_sum;

    assign binary_sum = {1'b0, A} + {1'b0, B} + {4'b0000, Cin};
    assign Cout = (binary_sum > 5'd9);
    assign corrected_sum = Cout ? (binary_sum + 5'd6) : binary_sum;
    assign Sum = corrected_sum[3:0];

endmodule
