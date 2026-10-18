module bin2bcd_array (
    input clk,
    input rst,
    input valid_in,
    input [15:0] binary_in,
    output reg [19:0] bcd_out,
    output reg valid_out
);

    reg [19:0] bcd_temp;
    reg [15:0] bin_temp;
    integer i;

    always @* begin
        bcd_temp = 20'd0;
        bin_temp = binary_in;

        for (i = 0; i < 16; i = i + 1) begin
            if (bcd_temp[3:0] >= 4'd5)
                bcd_temp[3:0] = bcd_temp[3:0] + 4'd3;
            if (bcd_temp[7:4] >= 4'd5)
                bcd_temp[7:4] = bcd_temp[7:4] + 4'd3;
            if (bcd_temp[11:8] >= 4'd5)
                bcd_temp[11:8] = bcd_temp[11:8] + 4'd3;
            if (bcd_temp[15:12] >= 4'd5)
                bcd_temp[15:12] = bcd_temp[15:12] + 4'd3;
            if (bcd_temp[19:16] >= 4'd5)
                bcd_temp[19:16] = bcd_temp[19:16] + 4'd3;

            bcd_temp = {bcd_temp[18:0], bin_temp[15]};
            bin_temp = {bin_temp[14:0], 1'b0};
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            bcd_out <= 20'd0;
            valid_out <= 1'b0;
        end else begin
            valid_out <= valid_in;
            if (valid_in)
                bcd_out <= bcd_temp;
        end
    end

endmodule
