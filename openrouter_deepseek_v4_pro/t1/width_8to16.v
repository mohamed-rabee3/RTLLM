module width_8to16 (
    input           clk,
    input           rst_n,
    input           valid_in,
    input   [7:0]   data_in,
    output reg      valid_out,
    output reg [15:0] data_out
);

    reg [7:0] data_lock;  // Stores the first 8-bit data
    reg       flag;       // Indicates that the first byte is stored

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_lock <= 8'b0;
            flag      <= 1'b0;
            data_out  <= 16'b0;
            valid_out <= 1'b0;
        end else begin
            // valid_out is only asserted for one cycle when new output is ready
            valid_out <= 1'b0;

            if (valid_in) begin
                if (flag) begin
                    // Second byte received: concatenate with stored byte (MSB: data_lock, LSB: data_in)
                    data_out  <= {data_lock, data_in};
                    valid_out <= 1'b1;
                    flag      <= 1'b0;   // Clear flag after generating output
                end else begin
                    // First byte received: store it and set the flag
                    data_lock <= data_in;
                    flag      <= 1'b1;
                end
            end
        end
    end

endmodule