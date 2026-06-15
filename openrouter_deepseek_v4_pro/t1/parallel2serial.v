module parallel2serial (
    input  wire       clk,
    input  wire      rst_n,
    input  wire [3:0] d,
    output reg       valid_out,
    output reg       dout
);

    reg [1:0] cnt;    // 2-bit counter (0 .. 3)
    reg [3:0] data;   // shift register

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt       <= 2'd0;
            data      <= 4'd0;
            valid_out <= 1'b0;
            dout      <= 1'b0;
        end else begin
            if (cnt == 2'd3) begin
                // Last bit of current word, load new parallel data
                data      <= d;
                cnt       <= 2'd0;
                valid_out <= 1'b1;
                dout      <= d[3];           // MSB first
            end else begin
                // Shift left with wrap (MSB -> LSB)
                data      <= {data[2:0], data[3]};
                cnt       <= cnt + 2'd1;
                valid_out <= 1'b0;
                dout      <= data[2];        // next bit to output
            end
        end
    end

endmodule