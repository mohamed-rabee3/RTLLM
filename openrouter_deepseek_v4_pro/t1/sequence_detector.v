module sequence_detector (
    input  wire clk,
    input  wire reset_n,        // Active high reset (as per specification: "when reset is high")
    input  wire data_in,
    output wire sequence_detected
);

    // FSM state encoding
    localparam IDLE = 3'd0,
               S1   = 3'd1,
               S2   = 3'd2,
               S3   = 3'd3,
               S4   = 3'd4;

    reg [2:0] state, next_state;

    // Combinational next-state logic (overlapping sequence detection)
    always @(*) begin
        next_state = state;
        case (state)
            IDLE: next_state = data_in ? S1 : IDLE;
            S1:   next_state = data_in ? S1 : S2;
            S2:   next_state = data_in ? S1 : S3;
            S3:   next_state = data_in ? S4 : IDLE;
            S4:   next_state = data_in ? S1 : S2;
            default: next_state = IDLE;
        endcase
    end

    // Sequential state update with asynchronous active-high reset
    always @(posedge clk or posedge reset_n) begin
        if (reset_n)
            state <= IDLE;
        else
            state <= next_state;
    end

    // Moore output: asserted when the complete sequence 1001 is recognized
    assign sequence_detected = (state == S4);

endmodule