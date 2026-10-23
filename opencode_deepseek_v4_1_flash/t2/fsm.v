module fsm (
    input  IN,
    input  CLK,
    input  RST,
    output reg MATCH
);

    localparam S0 = 3'd0;
    localparam S1 = 3'd1;
    localparam S2 = 3'd2;
    localparam S3 = 3'd3;
    localparam S4 = 3'd4;

    reg [2:0] state;

    always @(posedge CLK or posedge RST) begin
        if (RST)
            state <= S0;
        else begin
            case (state)
                S0: state <= IN ? S1 : S0;
                S1: state <= IN ? S1 : S2;
                S2: state <= IN ? S1 : S3;
                S3: state <= IN ? S4 : S0;
                S4: state <= IN ? S1 : S2;
                default: state <= S0;
            endcase
        end
    end

    always @(*) begin
        if (RST)
            MATCH = 1'b0;
        else if (state == S4 && IN)
            MATCH = 1'b1;
        else
            MATCH = 1'b0;
    end

endmodule
