module right_shifter (
    input  clk,
    input  d,
    output reg [7:0] q
);

// Initialize the shift register to 0
initial begin
    q = 8'b0;
end

// On each rising edge of the clock, shift in the new bit
always @(posedge clk) begin
    // Right shift the register by one position and
    // place the new input bit d into the most significant bit
    q <= {d, q[7:1]};
end

endmodule