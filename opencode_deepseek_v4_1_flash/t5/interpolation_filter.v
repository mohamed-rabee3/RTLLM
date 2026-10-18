module fir_interpolator (
    input clk,
    input rst,
    input valid_in,
    input signed [15:0] data_in,
    output reg valid_out,
    output reg signed [15:0] data_out
);

    // Interpolation factor L = 8
    localparam L = 8;

    // State registers
    reg first;
    reg active;
    reg [3:0] phase;
    reg signed [15:0] prev_sample;
    reg signed [15:0] cur_sample;

    // Interpolation function: prev + (cur - prev) * k / L
    // Uses signed truncating division.
    function signed [15:0] interpolate;
        input signed [15:0] prev;
        input signed [15:0] cur;
        input [3:0] k;
        reg signed [16:0] diff;
        reg signed [21:0] prod;
        reg signed [18:0] quot;
        reg signed [18:0] sum;
        begin
            diff = cur - prev;
            prod = diff * $signed({1'b0, k});
            quot = prod / 8'sd8;
            sum = prev + quot;
            interpolate = sum[15:0];
        end
    endfunction

    always @(posedge clk) begin
        if (rst) begin
            valid_out   <= 1'b0;
            data_out    <= 16'sd0;
            prev_sample <= 16'sd0;
            cur_sample  <= 16'sd0;
            phase       <= 4'd0;
            active      <= 1'b0;
            first       <= 1'b1;
        end else begin
            valid_out <= 1'b0;

            if (valid_in && first) begin
                // Emit the first input sample directly
                data_out    <= data_in;
                valid_out   <= 1'b1;
                prev_sample <= data_in;
                first       <= 1'b0;
                active      <= 1'b0;
                phase       <= 4'd0;
            end else if (valid_in && !first && (!active || phase == L)) begin
                // Start a new interpolation interval
                valid_out <= 1'b1;

                if (active && phase == L) begin
                    // Previous interval's cur_sample becomes new prev_sample
                    prev_sample <= cur_sample;
                    data_out    <= interpolate(cur_sample, data_in, 4'd1);
                end else begin
                    data_out    <= interpolate(prev_sample, data_in, 4'd1);
                end

                cur_sample <= data_in;
                phase      <= 4'd1;
                active     <= 1'b1;
            end else if (active) begin
                if (phase == L) begin
                    active      <= 1'b0;
                    prev_sample <= cur_sample;
                end else begin
                    phase     <= phase + 4'd1;
                    valid_out <= 1'b1;
                    data_out  <= interpolate(prev_sample, cur_sample, phase + 4'd1);
                end
            end
        end
    end

endmodule
