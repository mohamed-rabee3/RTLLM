module sorting_3_numbers (
    input  [9:0] a1,
    input  [9:0] a2,
    input  [9:0] a3,
    output [9:0] max,
    output [9:0] med,
    output [9:0] min
);

    wire [9:0] lo12;
    wire [9:0] hi12;
    wire [9:0] lo23;
    wire [9:0] hi23;

    // First compare and swap a1 and a2
    assign lo12 = (a1 < a2) ? a1 : a2;
    assign hi12 = (a1 < a2) ? a2 : a1;

    // Compare the larger of a1/a2 with a3
    assign lo23 = (hi12 < a3) ? hi12 : a3;
    assign hi23 = (hi12 < a3) ? a3 : hi12;

    // Re-order the remaining pair to complete the sort
    assign min = (lo12 < lo23) ? lo12 : lo23;
    assign med = (lo12 < lo23) ? lo23 : lo12;
    assign max = hi23;

endmodule
