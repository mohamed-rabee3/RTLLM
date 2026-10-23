module bin2bcd_array (
    input  wire        clk,
    input  wire        rst,
    input  wire        valid_in,
    input  wire [15:0] binary_in,
    output reg  [19:0] bcd_out,
    output reg         valid_out
);

    reg [19:0] bcd_next;
    integer bit_index;
    integer digit_index;

    always @* begin
        bcd_next = 20'd0;

        for (bit_index = 15; bit_index >= 0; bit_index = bit_index - 1) begin
            for (digit_index = 0; digit_index < 5; digit_index = digit_index + 1) begin
                if (bcd_next[digit_index*4 +: 4] >= 4'd5)
                    bcd_next[digit_index*4 +: 4] =
                        bcd_next[digit_index*4 +: 4] + 4'd3;
            end

            bcd_next = {bcd_next[18:0], binary_in[bit_index]};
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
