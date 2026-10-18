module fir_interpolator (
    input clk,
    input rst,
    input valid_in,
    input signed [15:0] data_in,
    output reg valid_out,
    output reg signed [15:0] data_out
);

    reg signed [15:0] prev_sample;
    reg signed [15:0] cur_sample;
    reg signed [15:0] pending_sample;
    reg pending_valid;
    reg have_prev;
    reg busy;
    reg [3:0] phase;

    wire signed [31:0] prev_ext = {{16{prev_sample[15]}}, prev_sample};
    wire signed [31:0] cur_ext = {{16{cur_sample[15]}}, cur_sample};
    wire signed [31:0] diff = cur_ext - prev_ext;
    wire signed [31:0] k_ext = {28'd0, phase};
    wire signed [31:0] prod = diff * k_ext;
    wire signed [31:0] quot = prod / 32'sd8;
    wire signed [31:0] interp_ext = prev_ext + quot;
    wire signed [15:0] interp = interp_ext[15:0];

    wire signed [31:0] data_in_ext = {{16{data_in[15]}}, data_in};
    wire signed [31:0] start_diff = data_in_ext - prev_ext;
    wire signed [31:0] start_quot = start_diff / 32'sd8;
    wire signed [31:0] start_interp = prev_ext + start_quot;
    wire signed [15:0] start_data = start_interp[15:0];

    always @(posedge clk) begin
        if (rst) begin
            valid_out <= 1'b0;
            data_out <= 16'sd0;
            prev_sample <= 16'sd0;
            cur_sample <= 16'sd0;
            pending_sample <= 16'sd0;
            pending_valid <= 1'b0;
            have_prev <= 1'b0;
            busy <= 1'b0;
            phase <= 4'd0;
        end else begin
            valid_out <= 1'b0;

            if (valid_in) begin
                if (!have_prev) begin
                    data_out <= data_in;
                    valid_out <= 1'b1;
                    prev_sample <= data_in;
                    have_prev <= 1'b1;
                end else if (!busy) begin
                    cur_sample <= data_in;
                    phase <= 4'd2;
                    busy <= 1'b1;
                    data_out <= start_data;
                    valid_out <= 1'b1;
                end else begin
                    pending_sample <= data_in;
                    pending_valid <= 1'b1;
                end
            end

            if (busy) begin
                data_out <= interp;
                valid_out <= 1'b1;

                if (phase == 4'd8) begin
                    prev_sample <= cur_sample;
                    if (pending_valid || valid_in) begin
                        if (valid_in) begin
                            cur_sample <= data_in;
                        end else begin
                            cur_sample <= pending_sample;
                        end
                        phase <= 4'd1;
                        busy <= 1'b1;
                        pending_valid <= 1'b0;
                    end else begin
                        busy <= 1'b0;
                        phase <= 4'd0;
                    end
                end else begin
                    phase <= phase + 1'b1;
                end
            end
        end
    end

endmodule
