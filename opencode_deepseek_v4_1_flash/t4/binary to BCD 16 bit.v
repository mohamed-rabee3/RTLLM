module bin2bcd_array (
    input clk,
    input rst,
    input valid_in,
    input [15:0] binary_in,
    output reg [19:0] bcd_out,
    output reg valid_out
);

    integer i;
    reg [19:0] bcd_comb;

    always @(*) begin
        bcd_comb = 20'd0;
        for (i = 15; i >= 0; i = i - 1) begin
            if (bcd_comb[3:0] >= 4'd5)
                bcd_comb[3:0] = bcd_comb[3:0] + 4'd3;
            if (bcd_comb[7:4] >= 4'd5)
                bcd_comb[7:4] = bcd_comb[7:4] + 4'd3;
            if (bcd_comb[11:8] >= 4'd5)
                bcd_comb[11:8] = bcd_comb[11:8] + 4'd3;
            if (bcd_comb[15:12] >= 4'd5)
                bcd_comb[15:12] = bcd_comb[15:12] + 4'd3;
            if (bcd_comb[19:16] >= 4'd5)
                bcd_comb[19:16] = bcd_comb[19:16] + 4'd3;
            bcd_comb = {bcd_comb[18:0], binary_in[i]};
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            bcd_out <= 20'd0;
            valid_out <= 1'b0;
        end else if (valid_in) begin
            bcd_out <= bcd_comb;
            valid_out <= 1'b1;
        end else begin
            valid_out <= 1'b0;
        end
    end

endmodule
