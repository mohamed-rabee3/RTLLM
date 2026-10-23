module div_16bit(
    input [15:0] A,
    input [7:0] B,
    output reg [15:0] result,
    output reg [15:0] odd
);

    reg [15:0] a_reg;
    reg [7:0] b_reg;
    reg [7:0] rem;
    reg [15:0] quo;
    integer i;

    always @(*) begin
        a_reg = A;
        b_reg = B;
    end

    always @(*) begin
        rem = 8'b0;
        quo = 16'b0;
        for (i = 15; i >= 0; i = i - 1) begin
            if ({rem[6:0], A[i]} >= B) begin
                rem = {rem[6:0], A[i]} - B;
                quo[i] = 1'b1;
            end else begin
                rem = {rem[6:0], A[i]};
                quo[i] = 1'b0;
            end
        end
        result = quo;
        odd = {8'b0, rem};
    end

endmodule
