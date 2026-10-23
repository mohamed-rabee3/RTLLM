module sorting_3_numbers (
    input  wire [9:0] a1,
    input  wire [9:0] a2,
    input  wire [9:0] a3,
    output wire [9:0] max,
    output wire [9:0] med,
    output wire [9:0] min
);

    wire [9:0] first_low;
    wire [9:0] first_high;
    wire [9:0] second_low;

    assign first_low  = (a1 > a2) ? a2 : a1;
    assign first_high = (a1 > a2) ? a1 : a2;

    assign second_low = (first_high > a3) ? a3 : first_high;
    assign max        = (first_high > a3) ? first_high : a3;

    assign min = (first_low > second_low) ? second_low : first_low;
    assign med = (first_low > second_low) ? first_low : second_low;

endmodule
