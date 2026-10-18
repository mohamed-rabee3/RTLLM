module multi_8bit(
    input  [7:0]  A,
    input  [7:0]  B,
    output [15:0] product
);

    reg [15:0] product_reg;
    reg [15:0] shifted_A;
    integer i;

    always @* begin
        product_reg = 16'd0;
        shifted_A   = {8'b0, A};

        for (i = 0; i < 8; i = i + 1) begin
            if (B[i])
                product_reg = product_reg + shifted_A;

            shifted_A = shifted_A << 1;
        end
    end

    assign product = product_reg;

endmodule
