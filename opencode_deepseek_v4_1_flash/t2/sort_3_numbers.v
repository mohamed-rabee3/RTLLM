module sorting_3_numbers(
    input  [9:0] a1,
    input  [9:0] a2,
    input  [9:0] a3,
    output [9:0] max,
    output [9:0] med,
    output [9:0] min
);

    wire [9:0] lo12;
    wire [9:0] hi12;
    wire [9:0] tmp;
    wire [9:0] lo_final;
    wire [9:0] hi_final;

    assign lo12 = (a1 <= a2) ? a1 : a2;
    assign hi12 = (a1 <= a2) ? a2 : a1;

    assign hi_final = (hi12 <= a3) ? a3 : hi12;
    assign tmp      = (hi12 <= a3) ? hi12 : a3;

    assign med = (lo12 <= tmp) ? tmp : lo12;
    assign min = (lo12 <= tmp) ? lo12 : tmp;

    assign max = hi_final;

endmodule
