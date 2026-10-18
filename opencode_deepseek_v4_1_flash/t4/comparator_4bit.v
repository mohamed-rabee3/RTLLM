module comparator_4bit (
    input  [3:0] A,
    input  [3:0] B,
    output       A_greater,
    output       A_equal,
    output       A_less
);

    wire [4:0] A_ext;
    wire [4:0] B_ext;
    wire [4:0] diff;

    assign A_ext = {1'b0, A};
    assign B_ext = {1'b0, B};
    assign diff  = A_ext - B_ext;

    assign A_less    = diff[4];
    assign A_equal   = (diff == 5'b00000);
    assign A_greater = (~diff[4]) && (diff[3:0] != 4'b0000);

endmodule
