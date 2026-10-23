module add_fast (
    input  wire [15:0] a,
    input  wire [15:0] b,
    output wire [16:0] result
);

    wire [8:0] lower_sum;
    wire [8:0] upper_sum_c0;
    wire [8:0] upper_sum_c1;
    wire [8:0] upper_sum;

    assign lower_sum    = {1'b0, a[7:0]}  + {1'b0, b[7:0]};
    assign upper_sum_c0 = {1'b0, a[15:8]} + {1'b0, b[15:8]};
    assign upper_sum_c1 = {1'b0, a[15:8]} + {1'b0, b[15:8]} + 9'd1;

    assign upper_sum = lower_sum[8] ? upper_sum_c1 : upper_sum_c0;
    assign result    = {upper_sum, lower_sum[7:0]};

endmodule
