module square_wave (
    input  wire        clk,
    input  wire [7:0]  freq,
    output reg         wave_out
);

    // Internal 8-bit counter
    reg [7:0] count;

    always @(posedge clk) begin
        // When count reaches freq-1, toggle wave_out and reset count
        if (count == (freq - 1)) begin
            wave_out <= ~wave_out;
            count    <= 8'd0;
        end else begin
            count <= count + 8'd1;
        end
    end

endmodule