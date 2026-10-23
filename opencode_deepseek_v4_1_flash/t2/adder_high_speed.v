module add_fast(
    input  [15:0] a,
    input  [15:0] b,
    output [16:0] result
);

    wire [8:0] low_sum;
    wire [8:0] high_sum0;
    wire [8:0] high_sum1;
    wire [8:0] high_sum;
    wire       carry_low;

    assign low_sum = {1'b0, a[7:0]} + {1'b0, b[7:0]};
    assign carry_low = low_sum[8];

    assign high_sum0 = {1'b0, a[15:8]} + {1'b0, b[15:8]};
    assign high_sum1 = high_sum0 + 9'd1;

    assign high_sum = carry_low ? high_sum1 : high_sum0;

    assign result[7:0]   = low_sum[7:0];
    assign result[15:8]  = high_sum[7:0];
    assign result[16]    = high_sum[8];

endmodule
