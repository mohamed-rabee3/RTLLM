module pulse_detect (
    input  wire clk,
    input  wire rst_n,
    input  wire data_in,
    output wire data_out
);

    // State encoding
    localparam WAIT_0  = 2'b00, // waiting for a 0 to start a pulse
               SAW_0   = 2'b01, // saw a 0, waiting for a 1
               SAW_01  = 2'b10; // saw 0->1, waiting for a 0 to complete pulse

    reg [1:0] state, next_state;

    // Sequential state update
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= WAIT_0;
        else
            state <= next_state;
    end

    // Combinational next-state logic and output
    always @(*) begin
        next_state = state;
        data_out = 1'b0;  // default no pulse
        case (state)
            WAIT_0: begin
                if (data_in == 1'b0)
                    next_state = SAW_0;
                else
                    next_state = WAIT_0;
            end
            SAW_0: begin
                if (data_in == 1'b1)
                    next_state = SAW_01;
                else
                    next_state = SAW_0;
            end
            SAW_01: begin
                if (data_in == 1'b0) begin
                    next_state = SAW_0;   // overlapping detection: this 0 starts next pulse
                    data_out = 1'b1;      // end of current pulse
                end else begin
                    next_state = WAIT_0;  // extra 1 breaks the pattern
                end
            end
            default: next_state = WAIT_0;
        endcase
    end

endmodule