module pulse_detect (
    input  wire clk,
    input  wire rst_n,
    input  wire data_in,
    output reg  data_out
);

    localparam [1:0] IDLE     = 2'b00,
                     SEEN_0   = 2'b01,
                     SEEN_01  = 2'b10;

    reg [1:0] state;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state    <= IDLE;
            data_out <= 1'b0;
        end else begin
            data_out <= 1'b0;

            case (state)
                IDLE: begin
                    if (!data_in)
                        state <= SEEN_0;
                    else
                        state <= IDLE;
                end

                SEEN_0: begin
                    if (data_in)
                        state <= SEEN_01;
                    else
                        state <= SEEN_0;
                end

                SEEN_01: begin
                    if (!data_in) begin
                        data_out <= 1'b1;
                        state    <= SEEN_0;
                    end else begin
                        state <= IDLE;
                    end
                end

                default: begin
                    state    <= IDLE;
                    data_out <= 1'b0;
                end
            endcase
        end
    end

endmodule
