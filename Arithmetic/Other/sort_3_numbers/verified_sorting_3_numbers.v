module verified_sorting_3_numbers(
    input  [9:0] a1,
    input  [9:0] a2,
    input  [9:0] a3,
    output reg [9:0] max,
    output reg [9:0] med,
    output reg [9:0] min
);
    reg [9:0] x1, x2, x3, t;
    always @* begin
        x1 = a1; x2 = a2; x3 = a3;
        if (x1 > x2) begin t = x1; x1 = x2; x2 = t; end
        if (x2 > x3) begin t = x2; x2 = x3; x3 = t; end
        if (x1 > x2) begin t = x1; x1 = x2; x2 = t; end
        min = x1;
        med = x2;
        max = x3;
    end
endmodule
