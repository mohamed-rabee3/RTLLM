module div_16bit (
    input  wire [15:0] A,
    input  wire [7:0]  B,
    output reg  [15:0] result,
    output reg  [15:0] odd
);

    reg [15:0] a_reg;
    reg [7:0]  b_reg;
    reg [16:0] remainder_work;
    reg [15:0] quotient_work;
    integer i;

    always @* begin
        a_reg = A;
        b_reg = B;
    end

    always @* begin
        remainder_work = 17'd0;
        quotient_work  = 16'd0;

        for (i = 15; i >= 0; i = i - 1) begin
            remainder_work = {remainder_work[15:0], a_reg[i]};

            if (remainder_work >= {9'd0, b_reg}) begin
                remainder_work = remainder_work - {9'd0, b_reg};
                quotient_work[i] = 1'b1;
            end else begin
                quotient_work[i] = 1'b0;
            end
        end

        result = quotient_work;
        odd    = remainder_work[15:0];
    end

endmodule
