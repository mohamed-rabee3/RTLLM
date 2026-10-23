module bin2bcd_array(
    input clk,
    input rst,
    input valid_in,
    input [15:0] binary_in,
    output reg [19:0] bcd_out,
    output reg valid_out
);

    integer i;
    reg [19:0] temp;

    always @(posedge clk) begin
        if (rst) begin
            bcd_out <= 20'd0;
            valid_out <= 1'b0;
        end else begin
            valid_out <= valid_in;
            if (valid_in) begin
                temp = 20'd0;
                for (i = 15; i >= 0; i = i - 1) begin
                    if (temp[3:0] >= 4'd5)
                        temp[3:0] = temp[3:0] + 4'd3;
                    if (temp[7:4] >= 4'd5)
                        temp[7:4] = temp[7:4] + 4'd3;
                    if (temp[11:8] >= 4'd5)
                        temp[11:8] = temp[11:8] + 4'd3;
                    if (temp[15:12] >= 4'd5)
                        temp[15:12] = temp[15:12] + 4'd3;
                    if (temp[19:16] >= 4'd5)
                        temp[19:16] = temp[19:16] + 4'd3;
                    temp = {temp[18:0], binary_in[i]};
                end
                bcd_out <= temp;
            end
        end
    end

endmodule
