module div_16bit(
    input [15:0] A,
    input [7:0] B,
    output reg [15:0] result,
    output reg [15:0] odd
);

    reg [15:0] a_reg;
    reg [7:0] b_reg;
    reg [8:0] rem;
    reg [15:0] quo;
    integer i;

    always @(A or B) begin
        a_reg = A;
        b_reg = B;
    end

    always @(A or B or a_reg or b_reg) begin
        rem = 9'd0;
        quo = 16'd0;
        for (i = 15; i >= 0; i = i - 1) begin
            rem = {rem[7:0], a_reg[i]};
            if (rem >= {1'b0, b_reg}) begin
                rem = rem - {1'b0, b_reg};
                quo[i] = 1'b1;
            end else begin
                quo[i] = 1'b0;
            end
        end
        result = quo;
        odd = {8'd0, rem[7:0]};
    end

endmodule
