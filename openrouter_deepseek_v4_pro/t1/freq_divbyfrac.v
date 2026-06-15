module freq_divbyfrac (
    input  wire clk,
    input  wire rst_n,
    output wire clk_div
);

    // MUL2_DIV_CLK = 7 for a 3.5x division (2*3.5 = 7)
    localparam MUL2_DIV_CLK = 7;

    // 3-bit counter cycles 0 .. 6
    reg [2:0] cnt;
    // Two intermediate clocks, one based on posedge, one on negedge
    reg pos_int;
    reg neg_int;

    //--------------------------------------------------------------------
    // Counter and posedge intermediate clock generation
    //--------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt      <= 3'd0;
            pos_int  <= 1'b0;
        end else begin
            // modulo-7 counter
            if (cnt == (MUL2_DIV_CLK - 1))
                cnt <= 3'd0;
            else
                cnt <= cnt + 1'b1;

            // pos_int: high for 2 cycles, starting from count 0
            if (cnt == 3'd0)
                pos_int <= 1'b1;
            else if (cnt == 3'd2)
                pos_int <= 1'b0;
        end
    end

    //--------------------------------------------------------------------
    // Negedge intermediate clock generation (phase-shifted by 0.5 cycle)
    //--------------------------------------------------------------------
    always @(negedge clk or negedge rst_n) begin
        if (!rst_n) begin
            neg_int <= 1'b0;
        end else begin
            // neg_int: high for 2 cycles, starting at count = 4 (negedge)
            if (cnt == 3'd4)
                neg_int <= 1'b1;
            else if (cnt == 3'd6)
                neg_int <= 1'b0;
        end
    end

    //--------------------------------------------------------------------
    // Final fractionally divided clock: OR of the two intermediate clocks
    //--------------------------------------------------------------------
    assign clk_div = pos_int | neg_int;

endmodule