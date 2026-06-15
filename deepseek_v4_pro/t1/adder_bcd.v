module adder_bcd (
    input [3:0] A,      // First BCD input (0-9)
    input [3:0] B,      // Second BCD input (0-9)
    input Cin,          // Carry-in input
    output [3:0] Sum,   // BCD sum output (0-9)
    output Cout         // Carry-out output
);
    // Perform binary addition of A, B, and Cin
    wire [4:0] bin_sum;
    assign bin_sum = A + B + Cin;

    // BCD correction: if binary sum exceeds 9, add 6 and generate carry
    assign Cout = (bin_sum > 5'd9);
    assign Sum  = Cout ? (bin_sum[3:0] + 4'd6) : bin_sum[3:0];
endmodule