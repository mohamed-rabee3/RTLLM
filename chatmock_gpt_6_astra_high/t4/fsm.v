module fsm (
    input  wire IN,
    input  wire CLK,
    input  wire RST,
    output wire MATCH
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

        case (state)
            S_IDLE: next_state = IN ? S_1 : S_IDLE;
            S_1:    next_state = IN ? S_1 : S_10;
            S_10:   next_state = IN ? S_1 : S_100;
            S_100:  next_state = IN ? S_1001 : S_IDLE;
            S_1001: next_state = IN ? S_1 : S_10;
            default: next_state = S_IDLE;
        endcase
    end

    assign MATCH = !RST && (state == S_1001) && IN;

endmodule
