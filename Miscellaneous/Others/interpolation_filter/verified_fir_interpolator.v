module verified_fir_interpolator(
    input                     clk,
    input                     rst,
    input                     valid_in,
    input      signed [15:0]  data_in,
    output reg                valid_out,
    output reg signed [15:0]  data_out
);
    // linear (triangular-kernel) interpolator, factor L = 8
    localparam integer L = 8;
    reg signed [15:0] prev, cur;
    reg [3:0] k;
    reg busy, first;

    always @(posedge clk) begin
        if (rst) begin
            valid_out <= 1'b0;
            first     <= 1'b1;
            busy      <= 1'b0;
            k         <= 4'd0;
            prev      <= 16'sd0;
            cur       <= 16'sd0;
            data_out  <= 16'sd0;
        end else begin
            valid_out <= 1'b0;
            if (valid_in) begin
                if (first) begin
                    data_out  <= data_in;     // emit first sample directly
                    valid_out <= 1'b1;
                    prev      <= data_in;
                    first     <= 1'b0;
                end else begin
                    cur  <= data_in;          // begin interpolating prev -> data_in
                    busy <= 1'b1;
                    k    <= 4'd1;
                end
            end else if (busy) begin
                data_out  <= prev + (($signed(cur) - $signed(prev)) * $signed({1'b0,k})) / L;
                valid_out <= 1'b1;
                if (k == L) begin
                    busy <= 1'b0;
                    prev <= cur;
                end else begin
                    k <= k + 4'd1;
                end
            end
        end
    end
endmodule
