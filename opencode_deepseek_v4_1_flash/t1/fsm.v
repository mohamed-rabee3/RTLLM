module fsm(
    input IN,
    input CLK,
    input RST,
    output MATCH
);

    reg [2:0] state;

    localparam S0 = 3'd0,
               S1 = 3'd1,
               S2 = 3'd2,
               S3 = 3'd3,
               S4 = 3'd4;

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

    assign MATCH = (!RST) && (state == S4) && IN;

endmodule
