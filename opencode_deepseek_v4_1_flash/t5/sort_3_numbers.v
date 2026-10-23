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
    wire [9:0] lo13;
    wire [9:0] hi13;

    assign lo12 = (a1 < a2) ? a1 : a2;
    assign hi12 = (a1 < a2) ? a2 : a1;

    assign lo13 = (lo12 < a3) ? lo12 : a3;
    assign hi13 = (lo12 < a3) ? a3 : lo12;

    assign min = lo13;
    assign med = (hi12 < hi13) ? hi12 : hi13;
    assign max = (hi12 < hi13) ? hi13 : hi12;

endmodule
