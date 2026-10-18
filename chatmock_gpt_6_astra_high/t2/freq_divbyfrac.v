module freq_divbyfrac (
    input  wire clk,
    input  wire rst_n,
    output wire clk_div
);

    localparam integer MUL2_DIV_CLK = 7;

    reg [2:0] count;
    reg       clk_div_pos;
    reg       clk_div_neg;

    // Seven input cycles contain two complete output periods.
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            count <= 3'd0;
        else if (count == MUL2_DIV_CLK - 1)
            count <= 3'd0;
        else
            count <= count + 3'd1;
    end

    // Positive-edge phase: pulse starts alternate four and three
    // source-clock cycles apart.
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            clk_div_pos <= 1'b0;
        else
            clk_div_pos <= (count == 3'd0) ||
                           (count == 3'd1) ||
                           (count == 3'd4);
    end

    // Negative-edge phase uses the counter updated on the preceding
    // positive edge to provide the half-cycle phase adjustment.
    always @(negedge clk or negedge rst_n) begin
        if (!rst_n)
            clk_div_neg <= 1'b0;
        else
            clk_div_neg <= (count == 3'd1) ||
                           (count == 3'd4) ||
                           (count == 3'd5);
    end

    // Uniform 3.5-cycle period: high for 2 cycles, low for 1.5 cycles.
    assign clk_div = clk_div_pos | clk_div_neg;

endmodule
