module freq_divbyfrac(
    input clk,
    input rst_n,
    output clk_div
);

    parameter MUL2_DIV_CLK = 7;

    reg [2:0] cnt;
    reg clk_div1;
    reg clk_div2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt <= 3'd0;
        end else if (cnt == MUL2_DIV_CLK - 1) begin
            cnt <= 3'd0;
        end else begin
            cnt <= cnt + 1'b1;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            clk_div1 <= 1'b0;
        end else if (cnt == MUL2_DIV_CLK - 1) begin
            clk_div1 <= 1'b1;
        end else if (cnt == (MUL2_DIV_CLK - 1) / 2) begin
            clk_div1 <= 1'b0;
        end
    end

    always @(negedge clk or negedge rst_n) begin
        if (!rst_n) begin
            clk_div2 <= 1'b0;
        end else if (cnt == MUL2_DIV_CLK - 1) begin
            clk_div2 <= 1'b1;
        end else if (cnt == (MUL2_DIV_CLK - 1) / 2) begin
            clk_div2 <= 1'b0;
        end
    end

    assign clk_div = clk_div1 | clk_div2;

endmodule
