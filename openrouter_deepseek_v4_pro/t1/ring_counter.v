module ring_counter (
    input  wire       clk,
    input  wire       reset,
    output reg  [7:0] out
);

    // Ring counter: on reset, initialize with LSB set.
    // On each rising clock edge, rotate left by one bit position.
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            out <= 8'b00000001;   // Start with only the LSB high
        end else begin
            out <= {out[6:0], out[7]}; // Left shift with wrap-around from MSB to LSB
        end
    end

endmodule