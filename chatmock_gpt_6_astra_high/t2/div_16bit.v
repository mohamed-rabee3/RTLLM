module div_16bit (
    input  wire [15:0] A,
    input  wire [7:0]  B,
    output reg  [15:0] result,
    output reg  [15:0] odd
);

    reg [15:0] a_reg;
    reg [7:0]  b_reg;
    integer i;

    always @* begin
        a_reg = A;
        b_reg = B;
    end

    always @* begin
        result = 16'b0;
        odd    = 16'b0;

        for (i = 15; i >= 0; i = i - 1) begin
            odd = {odd[14:0], a_reg[i]};

            if (odd >= {8'b0, b_reg}) begin
                odd       = odd - {8'b0, b_reg};
                result[i] = 1'b1;
            end
        end
    end

endmodule
