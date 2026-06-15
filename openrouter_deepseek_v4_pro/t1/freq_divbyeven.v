module freq_diveven #(
    parameter NUM_DIV = 4   // Even division factor (must be an even number)
) (
    input  wire clk,        // Input clock
    input  wire rst_n,      // Active-low reset
    output reg  clk_div    // Divided clock output
);

    // 4-bit counter as required by the specification
    reg [3:0] cnt;

    // Asynchronous active-low reset
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt     <= 4'b0;
            clk_div <= 1'b0;
        end else begin
            // If counter has not yet reached the toggle point, just increment
            if (cnt < (NUM_DIV / 2 - 1)) begin
                cnt <= cnt + 1;
            end else begin
                // Toggle the divided clock and reset the counter
                cnt     <= 4'b0;
                clk_div <= ~clk_div;
            end
        end
    end

endmodule