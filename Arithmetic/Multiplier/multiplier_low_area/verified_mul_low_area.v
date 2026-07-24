module verified_mul_low_area(
    input  [15:0] a,
    input  [15:0] b,
    output [31:0] result
);
    integer i;
    reg [31:0] acc;
    always @* begin
        acc = 32'd0;
        for (i = 0; i < 16; i = i + 1)
            if (b[i]) acc = acc + ({16'd0, a} << i);
    end
    assign result = acc;
endmodule
