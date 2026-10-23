module sequence_detector (
    input clk,
    input reset_n,
    input data_in,
    output sequence_detected
);

    reg [2:0] state, next_state;

    localparam IDLE = 3'd0,
               S1   = 3'd1,
               S2   = 3'd2,
               S3   = 3'd3,
               S4   = 3'd4;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n)
            state <= IDLE;
        else
            state <= next_state;
    end

    always @(*) begin
        next_state = state;

        case (state)
            IDLE: begin
                if (data_in)
                    next_state = S1;
                else
                    next_state = IDLE;
            end

            S1: begin
                if (data_in)
                    next_state = S1;
                else
                    next_state = S2;
            end

            S2: begin
                if (data_in)
                    next_state = S1;
                else
                    next_state = S3;
            end

            S3: begin
                if (data_in)
                    next_state = S4;
                else
                    next_state = IDLE;
            end

            S4: begin
                if (data_in)
                    next_state = S1;
                else
                    next_state = S2;
            end

            default: next_state = IDLE;
        endcase
    end

    assign sequence_detected = (state == S4);

endmodule
