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

    always @* begin
        next_state = S_IDLE;
        MATCH = 1'b0;

        if (!RST) begin
            case (state)
                S_IDLE: begin
                    next_state = IN ? S_1 : S_IDLE;
                end

                S_1: begin
                    next_state = IN ? S_1 : S_10;
                end

                S_10: begin
                    next_state = IN ? S_1 : S_100;
                end

                S_100: begin
                    next_state = IN ? S_1001 : S_IDLE;
                end

                S_1001: begin
                    MATCH = IN;
                    next_state = IN ? S_1 : S_10;
                end

                default: begin
                    next_state = S_IDLE;
                end
            endcase
        end
    end

endmodule
