module sequence_detector (
    input clk,
    input reset_n,
    input data_in,
    output sequence_detected
);

    localparam IDLE = 3'd0;
    localparam S1   = 3'd1;
    localparam S2   = 3'd2;
    localparam S3   = 3'd3;
    localparam S4   = 3'd4;

    reg [2:0] state;
    reg [2:0] next_state;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n)
            state <= IDLE;
        else
            state <= next_state;
    end

    always @(*) begin
        case (state)
            IDLE:    next_state = data_in ? S1 : IDLE;
            S1:      next_state = data_in ? S1 : S2;
            S2:      next_state = data_in ? S1 : S3;
            S3:      next_state = data_in ? S4 : IDLE;
            S4:      next_state = data_in ? S1 : S2;
            default: next_state = IDLE;
        endcase
    end

    assign sequence_detected = (state == S4);

endmodule
