module multi_8bit (
    input  [7:0]  A,
    input  [7:0]  B,
    output [15:0] product
);

    reg [15:0] product;
    integer    i;

    always @* begin
        product = 16'd0;
        for (i = 0; i < 8; i = i + 1) begin
            if (B[i]) begin
                // Zero-extend A to 16 bits, then shift left by i positions
                // This correctly aligns the partial product before addition.
                product = product + ( { {8{1'b0}}, A } << i );
            end
        end
    end

endmodule