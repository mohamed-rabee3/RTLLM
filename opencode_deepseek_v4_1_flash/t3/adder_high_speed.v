module add_fast (
    input  [15:0] a,
    input  [15:0] b,
    output [16:0] result
);

    wire [8:0] sum_low;
    wire [8:0] sum_high0;
    wire [8:0] sum_high1;
    wire [8:0] sum_high_sel;

    assign sum_low = {1'b0, a[7:0]} + {1'b0, b[7:0]};

    assign sum_high0 = {1'b0, a[15:8]} + {1'b0, b[15:8]};
    assign sum_high1 = {1'b0, a[15:8]} + {1'b0, b[15:8]} + 9'd1;

    assign sum_high_sel = sum_low[8] ? sum_high1 : sum_high0;

    assign result = {sum_high_sel, sum_low[7:0]};

endmodule
