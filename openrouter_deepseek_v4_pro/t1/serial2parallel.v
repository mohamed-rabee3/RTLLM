module serial2parallel (
    input clk,
    input rst_n,
    input din_serial,
    input din_valid,
    output reg [7:0] dout_parallel,
    output reg dout_valid
);
    // 4-bit counter as specified (counts number of received bits, 0 to 7)
    reg [3:0] cnt;

    // Internal shift register to accumulate serial bits
    reg [7:0] shift_reg;

    // Counter logic: increments on valid input, wraps from 7 back to 0
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt <= 4'd0;
        end else if (din_valid) begin
            if (cnt == 4'd7)
                cnt <= 4'd0;
            else
                cnt <= cnt + 4'd1;
        end
    end

    // Shift register: shifts in LSB first, so that first bit becomes MSB
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg <= 8'd0;
        end else if (din_valid) begin
            shift_reg <= {shift_reg[6:0], din_serial};
        end
    end

    // Output register: forms the complete parallel word when 8th bit arrives
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dout_parallel <= 8'd0;
            dout_valid   <= 1'b0;
        end else begin
            dout_valid <= 1'b0;  // default low
            if (din_valid && cnt == 4'd7) begin
                // {shift_reg[6:0], din_serial} contains the full 8-bit word:
                // first received bit is now at dout_parallel[7] (MSB),
                // last received bit at dout_parallel[0] (LSB)
                dout_parallel <= {shift_reg[6:0], din_serial};
                dout_valid   <= 1'b1;
            end
        end
    end
endmodule