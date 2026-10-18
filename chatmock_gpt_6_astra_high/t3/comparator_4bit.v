module comparator_4bit (
    input  wire [3:0] A,
    input  wire [3:0] B,
    output wire       A_greater,
    output wire       A_equal,
    output wire       A_less
);

    wire [3:0] difference;
    wire [4:0] borrow;

    assign borrow[0] = 1'b0;

    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin : bit_subtractor
            assign difference[i] = A[i] ^ B[i] ^ borrow[i];
            assign borrow[i+1] = (~A[i] & B[i]) |
                                 (~(A[i] ^ B[i]) & borrow[i]);
        end
    endgenerate

    assign A_less    = borrow[4];
    assign A_equal   = ~borrow[4] & ~(|difference);
    assign A_greater = ~borrow[4] &  (|difference);

endmodule
