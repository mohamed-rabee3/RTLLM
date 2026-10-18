module pulse_detect (
    input  wire clk,
    input  wire rst_n,
    input  wire data_in,
    output reg  data_out
);

    localparam [1:0] WAIT_ZERO = 2'd0,
                     SEEN_ZERO = 2'd1,
                     SEEN_ZERO_ONE = 2'd2;

    reg [1:0] state;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state    <= WAIT_ZERO;
            data_out <= 1'b0;
        end else begin
            data_out <= 1'b0;

            case (state)
                WAIT_ZERO: begin
                    if (!data_in)
                        state <= SEEN_ZERO;
                    else
                        state <= WAIT_ZERO;
                end

                SEEN_ZERO: begin
                    if (data_in)
                        state <= SEEN_ZERO_ONE;
                    else
                        state <= SEEN_ZERO;
                end

                SEEN_ZERO_ONE: begin
                    if (!data_in) begin
                        data_out <= 1'b1;
                        state    <= SEEN_ZERO;
                    end else begin
                        state <= WAIT_ZERO;
                    end
                end

                default: begin
                    state    <= WAIT_ZERO;
                    data_out <= 1'b0;
                end
            endcase
        end
    end

endmodule
