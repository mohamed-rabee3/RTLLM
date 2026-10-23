module comparator_4bit (
    input  [3:0] A,
    input  [3:0] B,
    output       A_greater,
    output       A_equal,
    output       A_less
);

    wire [4:0] sub_result;
    wire       borrow;
    wire [3:0] diff;

    assign sub_result = {1'b0, A} - {1'b0, B};
    assign diff       = sub_result[3:0];
    assign borrow     = sub_result[4];

    assign A_less    = borrow;
    assign A_equal   = ~borrow & (diff == 4'b0000);
    assign A_greater = ~borrow & (diff != 4'b0000);

endmodule
