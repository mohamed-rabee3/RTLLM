module sequence_detector (
    input clk,
    input reset_n,
    input data_in,
    output sequence_detected
);

    localparam IDLE = 3'b000;
    localparam S1   = 3'b001;
    localparam S2   = 3'b010;
    localparam S3   = 3'b011;
    localparam S4   = 3'b100;

    reg [2:0] state, next_state;

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

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n)
            state <= IDLE;
        else
            state <= next_state;
    end

    assign sequence_detected = (state == S4);

endmodule
