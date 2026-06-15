module multi_booth_8bit (
    input clk,
    input reset,
    input [7:0] a,
    input [7:0] b,
    output reg [15:0] p,
    output reg rdy
);

    reg [15:0] multiplier;
    reg [15:0] multiplicand;
    reg [4:0] ctr;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // Initialize registers with sign-extended inputs
            multiplier  <= {{8{a[7]}}, a};
            multiplicand <= {{8{b[7]}}, b};
            p           <= 16'd0;
            ctr         <= 5'd0;
            rdy         <= 1'b0;
        end else begin
            if (ctr < 16) begin
                // Left-shift multiplicand by 1 (Booth shifting operation)
                multiplicand <= multiplicand << 1;

                // If current bit of multiplier is 1, accumulate multiplicand
                if (multiplier[ctr])
                    p <= p + (multiplicand << 1); // use shifted value
                else
                    p <= p;

                // Increment counter
                ctr <= ctr + 1;
                rdy <= 1'b0;
            end else begin
                // Multiplication process complete
                rdy <= 1'b1;
                // Hold all other values
            end
        end
    end

endmodule