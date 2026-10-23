module mul_low_area(
    input  [15:0] a,
    input  [15:0] b,
    output reg [31:0] result
);

    integer i;
    reg [31:0] sum;

    always @(*) begin
        sum = 32'd0;
        for (i = 0; i < 16; i = i + 1) begin
            if (b[i])
                sum = sum + ({16'b0, a} << i);
        end
        result = sum;
    end

endmodule
