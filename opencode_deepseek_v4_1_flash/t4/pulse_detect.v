module pulse_detect(
    input clk,
    input rst_n,
    input data_in,
    output reg data_out
);

    localparam IDLE = 2'b00;
    localparam S0   = 2'b01;
    localparam S1   = 2'b10;
    localparam S2   = 2'b11;

    reg [1:0] state;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            data_out <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    data_out <= 1'b0;
                    if (data_in == 1'b0)
                        state <= S0;
                    else
                        state <= IDLE;
                end
                S0: begin
                    data_out <= 1'b0;
                    if (data_in == 1'b1)
                        state <= S1;
                    else
                        state <= S0;
                end
                S1: begin
                    data_out <= 1'b0;
                    if (data_in == 1'b0) begin
                        state <= S2;
                        data_out <= 1'b1;
                    end else begin
                        state <= IDLE;
                    end
                end
                S2: begin
                    data_out <= 1'b0;
                    if (data_in == 1'b1)
                        state <= S1;
                    else
                        state <= S0;
                end
                default: begin
                    state <= IDLE;
                    data_out <= 1'b0;
                end
            endcase
        end
    end

endmodule
