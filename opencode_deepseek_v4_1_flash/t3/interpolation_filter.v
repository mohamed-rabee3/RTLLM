module fir_interpolator (
    input clk,
    input rst,
    input valid_in,
    input signed [15:0] data_in,
    output reg valid_out,
    output reg signed [15:0] data_out
);

    localparam IDLE   = 1'b0;
    localparam INTERP = 1'b1;

    reg state;
    reg [3:0] phase;
    reg signed [15:0] prev;
    reg signed [15:0] cur;
    reg has_prev;

    reg signed [31:0] diff;
    reg signed [31:0] prod;
    reg signed [31:0] out;

    always @(posedge clk) begin
        if (rst) begin
            state     <= IDLE;
            phase     <= 4'd0;
            prev      <= 16'sd0;
            cur       <= 16'sd0;
            has_prev  <= 1'b0;
            valid_out <= 1'b0;
            data_out  <= 16'sd0;
        end else begin
            valid_out <= 1'b0;

            if (state == IDLE) begin
                if (valid_in) begin
                    if (!has_prev) begin
                        // First input sample: emit directly
                        prev      <= data_in;
                        data_out  <= data_in;
                        valid_out <= 1'b1;
                        has_prev  <= 1'b1;
                    end else begin
                        // Start interpolation for this new sample
                        cur   <= data_in;
                        phase <= 4'd1;
                        state <= INTERP;
                    end
                end
            end else begin
                // Interpolation state: compute current phase output
                diff = {{16{cur[15]}}, cur} - {{16{prev[15]}}, prev};
                prod = diff * $signed(phase);

                // Signed truncating division by 8
                if (prod >= 0)
                    out = prod >>> 3;
                else
                    out = -((-prod) >>> 3);

                data_out  <= prev + out;
                valid_out <= 1'b1;

                if (phase == 4'd8) begin
                    prev <= cur;
                    if (valid_in) begin
                        cur   <= data_in;
                        phase <= 4'd1;
                        state <= INTERP;
                    end else begin
                        state <= IDLE;
                    end
                end else begin
                    phase <= phase + 1'b1;
                end
            end
        end
    end

endmodule
