module comparator_4bit (
    input  [3:0] A,
    input  [3:0] B,
    output       A_greater,
    output       A_equal,
    output       A_less
);
    wire [3:0] diff;
    wire       cout;

    // Perform A - B using two's complement addition:
    // {cout, diff} = A + (~B) + 1
    assign {cout, diff} = {1'b0, A} + {1'b0, ~B} + 1'b1;

    // Mutually exclusive outputs
    assign A_less    = ~cout;                // borrow occurred: A < B
    assign A_equal   = (diff == 4'b0);       // difference zero: A == B
    assign A_greater = cout & ~A_equal;      // no borrow & non-zero: A > B

endmodule