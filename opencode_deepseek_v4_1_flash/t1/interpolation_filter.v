module fir_interpolator(
    input clk,
    input rst,
    input valid_in,
    input signed [15:0] data_in,
    output reg valid_out,
    output reg signed [15:0] data_out
);

    reg signed [15:0] prev_sample;
    reg signed [15:0] cur_sample;
    reg have_prev;
    reg busy;
    reg [3:0] phase;
    reg pending_valid;
    reg signed [15:0] pending_data;

    function signed [15:0] interp_value;
        input signed [15:0] p;
        input signed [15:0] c;
        input [3:0] k;
        reg signed [31:0] diff;
        reg signed [31:0] prod;
        reg signed [31:0] quot;
        begin
            diff = {{16{c[15]}}, c} - {{16{p[15]}}, p};
            prod = diff * $signed({1'b0, k});
            if (prod >= 0)
                quot = prod >>> 3;
            else
                quot = -((-prod) >>> 3);
            interp_value = p + quot;
        end
    endfunction

    always @(posedge clk) begin
        if (rst) begin
            valid_out <= 1'b0;
            data_out <= 16'sd0;
            prev_sample <= 16'sd0;
            cur_sample <= 16'sd0;
            have_prev <= 1'b0;
            busy <= 1'b0;
            phase <= 4'd0;
            pending_valid <= 1'b0;
            pending_data <= 16'sd0;
        end else begin
            valid_out <= 1'b0;

            if (busy && valid_in) begin
                pending_valid <= 1'b1;
                pending_data <= data_in;
            end

            if (!busy) begin
                if (pending_valid) begin
                    if (!have_prev) begin
                        data_out <= pending_data;
                        valid_out <= 1'b1;
                        prev_sample <= pending_data;
                        have_prev <= 1'b1;
                        pending_valid <= 1'b0;
                    end else begin
                        cur_sample <= pending_data;
                        phase <= 4'd1;
                        busy <= 1'b1;
                        data_out <= interp_value(prev_sample, pending_data, 4'd1);
                        valid_out <= 1'b1;
                        pending_valid <= 1'b0;
                    end
                end else if (valid_in) begin
                    if (!have_prev) begin
                        data_out <= data_in;
                        valid_out <= 1'b1;
                        prev_sample <= data_in;
                        have_prev <= 1'b1;
                    end else begin
                        cur_sample <= data_in;
                        phase <= 4'd1;
                        busy <= 1'b1;
                        data_out <= interp_value(prev_sample, data_in, 4'd1);
                        valid_out <= 1'b1;
                    end
                end
            end else begin
                if (phase < 4'd8) begin
                    data_out <= interp_value(prev_sample, cur_sample, phase + 4'd1);
                    valid_out <= 1'b1;
                    phase <= phase + 4'd1;
                    if (phase + 4'd1 == 4'd8) begin
                        busy <= 1'b0;
                        prev_sample <= cur_sample;
                    end
                end else begin
                    busy <= 1'b0;
                    prev_sample <= cur_sample;
                    valid_out <= 1'b0;
                end
            end
        end
    end

endmodule
