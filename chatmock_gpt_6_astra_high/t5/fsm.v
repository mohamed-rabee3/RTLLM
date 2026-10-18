module fsm (
    input  wire IN,
    input  wire CLK,
    input  wire RST,
    output reg  MATCH
);

    localparam [2:0]
        S_IDLE = 3'd0,
        S_1    = 3'd1,
        S_10   = 3'd2,
        S_100  = 3'd3,
        S_1001 = 3'd4;

    reg [2:0] state;
    reg [2:0] next_state;

    always @(posedge CLK or posedge RST) begin
        if (RST)
            state <= S_IDLE;
        else
            state <= next_state;
    end

    always @(*) begin
        next_state = S_IDLE;
        MATCH = 1'b0;

        if (RST) begin
            next_state = S_IDLE;
        end else begin
            case (state)
                S_IDLE: begin
                    if (IN)
                        next_state = S_1;
                    else
                        next_state = S_IDLE;
                end

                S_1: begin
                    if (IN)
                        next_state = S_1;
                    else
                        next_state = S_10;
                end

                S_10: begin
                    if (IN)
                        next_state = S_1;
                    else
                        next_state = S_100;
                end

                S_100: begin
                    if (IN)
                        next_state = S_1001;
                    else
                        next_state = S_IDLE;
                end

                S_1001: begin
                    if (IN) begin
                        MATCH = 1'b1;
                        next_state = S_1;
                    end else begin
                        next_state = S_10;
                    end
                end

                default: begin
                    next_state = S_IDLE;
                end
            endcase
        end
    end

endmodule
