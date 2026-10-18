module bin2bcd_array (
    input  wire        clk,
    input  wire        rst,
    input  wire        valid_in,
    input  wire [15:0] binary_in,
    output reg  [19:0] bcd_out,
    output reg         valid_out
);

    reg [19:0] bcd_next;
    integer bit_idx;
    integer digit_idx;

    always @* begin
        bcd_next = 20'd0;

        for (bit_idx = 15; bit_idx >= 0; bit_idx = bit_idx - 1) begin
            for (digit_idx = 0; digit_idx < 5; digit_idx = digit_idx + 1) begin
                if (bcd_next[digit_idx*4 +: 4] >= 4'd5)
                    bcd_next[digit_idx*4 +: 4] =
                        bcd_next[digit_idx*4 +: 4] + 4'd3;
            end

            bcd_next = {bcd_next[18:0], binary_in[bit_idx]};
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            bcd_out   <= 20'd0;
            valid_out <= 1'b0;
        end else begin
            valid_out <= valid_in;
            if (valid_in)
                bcd_out <= bcd_next;
        end
    end

endmodule
