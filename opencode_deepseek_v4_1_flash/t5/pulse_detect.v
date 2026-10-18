module pulse_detect (
    input clk,
    input rst_n,
    input data_in,
    output reg data_out
);

    localparam S0 = 2'b00,
               S1 = 2'b01,
               S2 = 2'b10;

    reg [1:0] state;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= S0;
            data_out <= 1'b0;
        end else begin
            data_out <= 1'b0;

            case (state)
                S0: begin
                    if (data_in)
                        state <= S0;
                    else
                        state <= S1;
                end

                S1: begin
                    if (data_in)
                        state <= S2;
                    else
                        state <= S1;
                end

                S2: begin
                    if (data_in) begin
                        state <= S0;
                    end else begin
                        state <= S1;
                        data_out <= 1'b1;
                    end
                end

                default: begin
                    state <= S0;
                    data_out <= 1'b0;
                end
            endcase
        end
    end

endmodule
