module freq_divbyfrac (
    input  wire clk,
    input  wire rst_n,
    output wire clk_div
);

    localparam integer MUL2_DIV_CLK = 7;

    reg [2:0] count;
    reg       clk_div_pos;
    reg       clk_div_neg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            count <= 3'd0;
        else if (count == MUL2_DIV_CLK - 1)
            count <= 3'd0;
        else
            count <= count + 3'd1;
    end

    // Uneven intermediate clock: alternating four- and three-cycle periods.
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            clk_div_pos <= 1'b0;
        end else begin
            case (count)
                3'd0, 3'd4: clk_div_pos <= 1'b1;
                3'd2, 3'd5: clk_div_pos <= 1'b0;
                default:    clk_div_pos <= clk_div_pos;
            endcase
        end
    end

    // The counter has already advanced at the preceding rising edge.
    // Advance the second pulse's rising edge by half a source cycle
    // and delay its falling edge by half a source cycle.
    always @(negedge clk or negedge rst_n) begin
        if (!rst_n) begin
            clk_div_neg <= 1'b0;
        end else begin
            case (count)
                3'd4:    clk_div_neg <= 1'b1;
                3'd6:    clk_div_neg <= 1'b0;
                default: clk_div_neg <= clk_div_neg;
            endcase
        end
    end

    // Uniform 3.5-cycle period: two cycles high, 1.5 cycles low.
    assign clk_div = clk_div_pos | clk_div_neg;

endmodule
