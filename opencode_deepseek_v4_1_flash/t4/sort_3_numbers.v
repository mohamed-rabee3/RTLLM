module sorting_3_numbers (
    input  [9:0] a1,
    input  [9:0] a2,
    input  [9:0] a3,
    output [9:0] max,
    output [9:0] med,
    output [9:0] min
);

    wire [9:0] low12;
    wire [9:0] high12;
    wire [9:0] mid_temp;
    wire [9:0] max_temp;

    assign low12  = (a1 < a2) ? a1 : a2;
    assign high12 = (a1 > a2) ? a1 : a2;

    assign mid_temp = (high12 < a3) ? high12 : a3;
    assign max_temp = (high12 > a3) ? high12 : a3;

    assign min = (low12 < mid_temp) ? low12 : mid_temp;
    assign med = (low12 > mid_temp) ? low12 : mid_temp;
    assign max = max_temp;

endmodule
