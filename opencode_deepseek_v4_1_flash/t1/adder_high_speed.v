module add_fast(
    input  [15:0] a,
    input  [15:0] b,
    output [16:0] result
);

    wire [7:0] sum_low;
    wire       carry_low;

    wire [7:0] sum_upper0;
    wire [7:0] sum_upper1;
    wire       carry_upper0;
    wire       carry_upper1;

    wire [7:0] sum_upper;
    wire       carry_high;

    assign {carry_low, sum_low} = {1'b0, a[7:0]} + {1'b0, b[7:0]};

    assign {carry_upper0, sum_upper0} = {1'b0, a[15:8]} + {1'b0, b[15:8]};
    assign {carry_upper1, sum_upper1} = {1'b0, a[15:8]} + {1'b0, b[15:8]} + 9'd1;

    assign sum_upper  = carry_low ? sum_upper1  : sum_upper0;
    assign carry_high = carry_low ? carry_upper1 : carry_upper0;

    assign result = {carry_high, sum_upper, sum_low};

endmodule
