module JC_counter (
    input clk,
    input rst_n,
    output reg [63:0] Q
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            Q <= 64'd0;
        end else begin
            // If Q[0] is 0, MSB becomes 1; if Q[0] is 1, MSB becomes 0.
            // Shift right by 1 and insert the inverted LSB at the MSB position.
            Q <= {~Q[0], Q[63:1]};
        end
    end

endmodule