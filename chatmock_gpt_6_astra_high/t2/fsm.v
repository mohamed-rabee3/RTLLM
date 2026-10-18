module fsm (
    input  wire IN,
    input  wire CLK,
    input  wire RST,
    output reg  MATCH
);

    localparam [2:0] IDLE  = 3'd0,
                     S1    = 3'd1,
                     S10   = 3'd2,
                     S100  = 3'd3,
                     S1001 = 3'd4;

    reg [2:0] state;
    reg [2:0] next_state;

    always @(posedge CLK or posedge RST) begin
        if (RST)
            state <= IDLE;
        else
            state <= next_state;
    end

    always @(*) begin
        next_state = IDLE;
        MATCH = 1'b0;

        if (!RST) begin
            case (state)
                IDLE: begin
                    next_state = IN ? S1 : IDLE;
                end

                S1: begin
                    next_state = IN ? S1 : S10;
                end

                S10: begin
                    next_state = IN ? S1 : S100;
                end

                S100: begin
                    next_state = IN ? S1001 : IDLE;
                end

                S1001: begin
                    MATCH = IN;
                    next_state = IN ? S1 : S10;
                end

                default: begin
                    next_state = IDLE;
                end
            endcase
        end
    end

endmodule
