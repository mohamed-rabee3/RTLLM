module add_fast (
    input  [15:0] a,
    input  [15:0] b,
    output [16:0] result
);

    wire       carry_low;
    wire [8:0] upper_sum0;
    wire [8:0] upper_sum1;

    assign {carry_low, result[7:0]} = {1'b0, a[7:0]} + {1'b0, b[7:0]};

    assign upper_sum0 = {1'b0, a[15:8]} + {1'b0, b[15:8]};
    assign upper_sum1 = upper_sum0 + 9'd1;

    assign result[16:8] = carry_low ? upper_sum1 : upper_sum0;

endmodule
