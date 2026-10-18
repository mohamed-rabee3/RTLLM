module sorting_3_numbers (
    input  wire [9:0] a1,
    input  wire [9:0] a2,
    input  wire [9:0] a3,
    output wire [9:0] max,
    output wire [9:0] med,
    output wire [9:0] min
);

    wire [9:0] first_lo;
    wire [9:0] first_hi;
    wire [9:0] second_lo;

    // Compare and order a1 and a2.
    assign first_lo = (a1 > a2) ? a2 : a1;
    assign first_hi = (a1 > a2) ? a1 : a2;

    // Compare the larger value with a3.
    assign second_lo = (first_hi > a3) ? a3 : first_hi;
    assign max       = (first_hi > a3) ? first_hi : a3;

    // Order the remaining pair.
    assign min = (first_lo > second_lo) ? second_lo : first_lo;
    assign med = (first_lo > second_lo) ? first_lo : second_lo;

endmodule
