module mul_low_area (
    input  [15:0] a,
    input  [15:0] b,
    output [31:0] result
);

    reg [31:0] result_reg;
    integer i;

    always @* begin
        result_reg = 32'd0;
        for (i = 0; i < 16; i = i + 1) begin
            if (b[i]) begin
                result_reg = result_reg + ({16'b0, a} << i);
            end
        end
    end

    assign result = result_reg;

endmodule
