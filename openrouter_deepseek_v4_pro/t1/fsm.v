module fsm (
    input  IN,
    input  CLK,
    input  RST,
    output reg MATCH
);

    // State encoding for the sequence 10011
    localparam S0 = 3'b000; // no match
    localparam S1 = 3'b001; // recognized "1"
    localparam S2 = 3'b010; // recognized "10"
    localparam S3 = 3'b011; // recognized "100"
    localparam S4 = 3'b100; // recognized "1001"

    reg [2:0] state, next_state;

    // State register with asynchronous reset
    always @(posedge CLK or posedge RST) begin
        if (RST)
            state <= S0;
        else
            state <= next_state;
    end

    // Mealy next-state and output combinational logic
    always @(*) begin
        // Default values
        next_state = state;
        MATCH     = 1'b0;

        case (state)
            S0: begin
                if (IN)
                    next_state = S1;
                else
                    next_state = S0;
            end

            S1: begin
                if (IN)
                    next_state = S1;
                else
                    next_state = S2;
            end

            S2: begin
                if (IN)
                    next_state = S1; // "101" -> longest prefix is "1"
                else
                    next_state = S3; // "100"
            end

            S3: begin
                if (IN)
                    next_state = S4; // "1001"
                else
                    next_state = S0; // "1000" -> no prefix
            end

            S4: begin
                if (IN) begin
                    next_state = S1;    // "10011" -> overlap with "1"
                    MATCH     = 1'b1;   // Assert match immediately
                end else begin
                    next_state = S2;    // "10010" -> longest prefix "10"
                end
            end

            default: next_state = S0;
        endcase
    end

endmodule