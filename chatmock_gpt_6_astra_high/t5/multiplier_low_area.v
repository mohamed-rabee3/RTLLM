module mul_low_area (
    input  wire [15:0] a,
    input  wire [15:0] b,
    output reg  [31:0] result
);

    integer i;

    always @* begin
        result = 32'b0;
        for (i = 0; i < 16; i = i + 1) begin
            if (b[i])
                result = result + ({16'b0, a} << i);
        end
    end

endmodule
