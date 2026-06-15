module accu (
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    input wire valid_in,
    output reg valid_out,
    output reg [9:0] data_out
);
    // Internal state
    reg [1:0] cnt;   // Counts 0–3 to track number of accumulated inputs
    reg [9:0] sum;   // Holds the sum of the first three inputs in a group

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Active-low reset: clear all registers
            cnt       <= 2'd0;
            sum       <= 10'd0;
            valid_out <= 1'b0;
            data_out  <= 10'd0;
        end else begin
            // Default: deassert valid_out each cycle (pulse lasts only one cycle)
            valid_out <= 1'b0;

            if (valid_in) begin
                if (cnt == 2'd3) begin
                    // Fourth valid input received → produce output
                    // The sum register currently holds the sum of the first three inputs.
                    // Add the current data_in to form the total of four inputs.
                    data_out  <= sum + data_in;
                    valid_out <= 1'b1;
                    // Reset counter and sum for the next group of four
                    cnt       <= 2'd0;
                    sum       <= 10'd0;
                end else begin
                    // Not yet received four inputs → accumulate and increment counter
                    sum <= sum + data_in;
                    cnt <= cnt + 2'd1;
                end
            end
        end
    end
endmodule