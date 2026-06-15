module accu (
    input           clk,
    input           rst_n,
    input  [7:0]    data_in,
    input           valid_in,
    output reg      valid_out,
    output reg [9:0] data_out
);

    reg [1:0] count;  // counts number of accumulated data (0 to 3)
    reg [9:0] sum;    // accumulation sum

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count      <= 2'd0;
            sum        <= 10'd0;
            valid_out  <= 1'b0;
            data_out   <= 10'd0;
        end else begin
            if (valid_in) begin
                if (count == 2'd3) begin
                    // 4th valid input data: compute final sum and present output
                    data_out   <= sum + data_in;
                    valid_out  <= 1'b1;
                    // start a new accumulation for the next batch
                    sum        <= 10'd0;
                    count      <= 2'd0;
                end else begin
                    // intermediate accumulation
                    sum        <= sum + data_in;
                    count      <= count + 2'd1;
                    valid_out  <= 1'b0;
                    data_out   <= 10'd0;
                end
            end else begin
                // no new data
                valid_out  <= 1'b0;
                data_out   <= 10'd0;
            end
        end
    end

endmodule