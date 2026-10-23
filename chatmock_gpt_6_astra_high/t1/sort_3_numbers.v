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
    wire [9:0] second_high;

    // First compare-and-swap: order a1 and a2.
    assign first_low  = (a1 <= a2) ? a1 : a2;
    assign first_high = (a1 <= a2) ? a2 : a1;

    // Second compare-and-swap: order the larger value and a3.
    assign second_low  = (first_high <= a3) ? first_high : a3;
    assign second_high = (first_high <= a3) ? a3 : first_high;

    // Third compare-and-swap: order the remaining pair.
    assign min = (first_low <= second_low) ? first_low : second_low;
    assign med = (first_low <= second_low) ? second_low : first_low;
    assign max = second_high;

endmodule
