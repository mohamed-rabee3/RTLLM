module freq_divbyfrac (
    input  wire clk,
    input  wire rst_n,
    output wire clk_div
);

    localparam integer MUL2_DIV_CLK = 7;

    reg [2:0] cnt;
    reg       clk_div_pos;
    reg       clk_div_neg;

    // Seven input cycles contain two output periods.
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt         <= 3'd0;
            clk_div_pos <= 1'b0;
        end else begin
            if (cnt == MUL2_DIV_CLK - 1)
                cnt <= 3'd0;
            else
                cnt <= cnt + 3'd1;

            // Positive-edge component: alternating four- and
            // three-input-cycle spacing between rising edges.
            clk_div_pos <= (cnt == 3'd0) ||
                           (cnt == 3'd1) ||
                           (cnt == 3'd4);
        end
    end

    // At the falling edge, cnt already contains the value updated
    // at the preceding rising edge. This component supplies the
    // half-cycle phase correction and balances the output pulses.
    always @(negedge clk or negedge rst_n) begin
        if (!rst_n)
            clk_div_neg <= 1'b0;
        else
            clk_div_neg <= (cnt == 3'd1) ||
                           (cnt == 3'd4) ||
                           (cnt == 3'd5);
    end

    // Uniform 3.5-cycle period: high for 2 cycles, low for 1.5 cycles.
    assign clk_div = clk_div_pos | clk_div_neg;

endmodule
