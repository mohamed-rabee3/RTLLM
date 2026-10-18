module freq_divbyfrac(
    input clk,
    input rst_n,
    output clk_div
);

parameter MUL2_DIV_CLK = 7;

reg [2:0] count;
reg clk_div1, clk_div2;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        count <= 3'd0;
    else if (count == MUL2_DIV_CLK - 1)
        count <= 3'd0;
    else
        count <= count + 1'b1;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        clk_div1 <= 1'b0;
    else if (count == 3'd0)
        clk_div1 <= 1'b1;
    else if (count == 3'd2)
        clk_div1 <= 1'b0;
end

always @(negedge clk or negedge rst_n) begin
    if (!rst_n)
        clk_div2 <= 1'b0;
    else if (count == 3'd4)
        clk_div2 <= 1'b1;
    else if (count == 3'd6)
        clk_div2 <= 1'b0;
end

assign clk_div = clk_div1 | clk_div2;

endmodule
