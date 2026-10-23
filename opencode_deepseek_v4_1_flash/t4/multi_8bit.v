module multi_8bit (
    input  [7:0]  A,
    input  [7:0]  B,
    output reg [15:0] product
);

    integer i;
    reg [15:0] multiplicand;

    always @(*) begin
        product = 16'd0;
        multiplicand = {8'b0, A};

        for (i = 0; i < 8; i = i + 1) begin
            if (B[i]) begin
                product = product + multiplicand;
            end
            multiplicand = multiplicand << 1;
        end
    end

endmodule
