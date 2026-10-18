module freq_divbyfrac (
    input  wire clk,
    input  wire rst_n,
    output wire clk_div
);

    localparam integer MUL2_DIV_CLK = 7;

    reg [2:0] count;
    reg       clk_div_pos;
    reg       clk_div_neg;

    // Seven input cycles contain two output periods.
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            count <= 3'd0;
        else if (count == MUL2_DIV_CLK - 1)
            count <= 3'd0;
        else
            count <= count + 3'd1;
    end

    // Rising-edge waveform: pulse starts alternate four and three
    // input cycles apart.
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            clk_div_pos <= 1'b0;
        else
            clk_div_pos <= (count == 3'd0) ||
                           (count == 3'd1) ||
                           (count == 3'd4);
    end

    // Extend the shorter pulse by half a cycle at each end.
    // At falling edges, count already contains its updated value.
    always @(negedge clk or negedge rst_n) begin
        if (!rst_n)
            clk_div_neg <= 1'b0;
        else
            clk_div_neg <= (count == 3'd4) ||
                           (count == 3'd5);
    end

    // Uniform 3.5-cycle period: two cycles high, 1.5 cycles low.
    assign clk_div = clk_div_pos | clk_div_neg;

endmodule
