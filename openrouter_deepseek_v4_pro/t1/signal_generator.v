module signal_generator (
    input  wire       clk,
    input  wire       rst_n,
    output reg  [4:0] wave
);

    // State register: 0 = incrementing, 1 = decrementing
    reg state;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= 1'b0;
            wave  <= 5'd0;
        end else begin
            case (state)
                1'b0: begin
                    if (wave == 5'd31) begin
                        state <= 1'b1;   // change direction, keep wave at 31
                    end else begin
                        wave <= wave + 1'b1;
                    end
                end
                1'b1: begin
                    if (wave == 5'd0) begin
                        state <= 1'b0;   // change direction, keep wave at 0
                    end else begin
                        wave <= wave - 1'b1;
                    end
                end
                default: begin
                    state <= 1'b0;
                    wave  <= 5'd0;
                end
            endcase
        end
    end

endmodule