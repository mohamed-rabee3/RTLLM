module freq_divbyfrac (
    input  wire clk,
    input  wire rst_n,
    output wire clk_div
);

    localparam integer MUL2_DIV_CLK = 7;

    reg [2:0] cnt;
    reg       clk_pos;
    reg       clk_neg;

    // Seven input cycles contain two output periods.
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            cnt <= 3'd0;
        else if (cnt == MUL2_DIV_CLK - 1)
            cnt <= 3'd0;
        else
            cnt <= cnt + 3'd1;
    end

    // Rising-edge waveform: alternating four-cycle and three-cycle
    // periods, with unequal pulse widths.
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            clk_pos <= 1'b0;
        else begin
            case (cnt)
                3'd0, 3'd1, 3'd4: clk_pos <= 1'b1;
                default:          clk_pos <= 1'b0;
            endcase
        end
    end

    // Falling-edge waveform supplies the half-cycle phase adjustment.
    // This logic observes the counter updated on the preceding rising edge.
    always @(negedge clk or negedge rst_n) begin
        if (!rst_n)
            clk_neg <= 1'b0;
        else begin
            case (cnt)
                3'd1, 3'd4, 3'd5: clk_neg <= 1'b1;
                default:          clk_neg <= 1'b0;
            endcase
        end
    end

    // Uniform 3.5-cycle period: high for 2 cycles, low for 1.5 cycles.
    assign clk_div = clk_pos | clk_neg;

endmodule
