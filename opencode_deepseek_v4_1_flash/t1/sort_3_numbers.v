module sorting_3_numbers (
    input  [9:0] a1,
    input  [9:0] a2,
    input  [9:0] a3,
    output [9:0] max,
    output [9:0] med,
    output [9:0] min
);

    wire [9:0] hi12;
    wire [9:0] lo12;
    wire [9:0] max_val;
    wire [9:0] mid_temp;
    wire [9:0] med_val;
    wire [9:0] min_val;

    assign hi12 = (a1 > a2) ? a1 : a2;
    assign lo12 = (a1 > a2) ? a2 : a1;

    assign max_val = (hi12 > a3) ? hi12 : a3;
    assign mid_temp = (hi12 > a3) ? a3 : hi12;

    assign med_val = (mid_temp > lo12) ? mid_temp : lo12;
    assign min_val = (mid_temp > lo12) ? lo12 : mid_temp;

    assign max = max_val;
    assign med = med_val;
    assign min = min_val;

endmodule
