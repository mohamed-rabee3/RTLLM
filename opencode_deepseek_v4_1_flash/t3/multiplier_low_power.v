module mul_low_power (
    input  [15:0] a,
    input  [15:0] b,
    output [31:0] result
);

    reg [31:0] product;
    integer i;

    always @(*) begin
        product = 32'd0;
        for (i = 0; i < 16; i = i + 1) begin
            if (b[i])
                product = product + ({16'b0, a} << i);
        end
    end

    assign result = product;

endmodule
