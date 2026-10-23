module mul_low_power (
    input  wire [15:0] a,
    input  wire [15:0] b,
    output reg  [31:0] result
);

    reg [31:0] partial_product;
    integer i;

    always @* begin
        result = 32'b0;
        partial_product = 32'b0;

        for (i = 0; i < 16; i = i + 1) begin
            partial_product = {16'b0, (a & {16{b[i]}})} << i;
            result = result + partial_product;
        end
    end

endmodule
