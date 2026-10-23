module fir_interpolator (
    input clk,
    input rst,
    input valid_in,
    input signed [15:0] data_in,
    output reg valid_out,
    output reg signed [15:0] data_out
);

    localparam IDLE_FIRST = 2'd0;
    localparam WAIT_SAMPLE = 2'd1;
    localparam INTERP = 2'd2;

    reg [1:0] state;
    reg signed [15:0] prev_sample;
    reg signed [15:0] cur_sample;
    reg [2:0] cnt;
    reg pending_valid;
    reg signed [15:0] pending_sample;

    function signed [16:0] div8_trunc;
        input signed [19:0] prod;
        reg signed [19:0] shifted;
        begin
            shifted = prod >>> 3;
            if (prod < 0 && prod[2:0] != 0)
                div8_trunc = shifted + 20'sd1;
            else
                div8_trunc = shifted;
        end
    endfunction

    function signed [16:0] interp;
        input signed [15:0] a;
        input signed [15:0] b;
        input integer k;
        reg signed [16:0] diff;
        reg signed [19:0] prod;
        begin
            diff = b - a;
            prod = diff * k;
            interp = a + div8_trunc(prod);
        end
    endfunction

    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE_FIRST;
            prev_sample <= 16'sd0;
            cur_sample <= 16'sd0;
            cnt <= 3'd0;
            valid_out <= 1'b0;
            data_out <= 16'sd0;
            pending_valid <= 1'b0;
            pending_sample <= 16'sd0;
        end else begin
            valid_out <= 1'b0;

            case (state)
                IDLE_FIRST: begin
                    if (valid_in) begin
                        prev_sample <= data_in;
                        data_out <= data_in;
                        valid_out <= 1'b1;
                        state <= WAIT_SAMPLE;
                    end
                end

                WAIT_SAMPLE: begin
                    if (valid_in) begin
                        cur_sample <= data_in;
                        cnt <= 3'd0;
                        data_out <= interp(prev_sample, data_in, 1);
                        valid_out <= 1'b1;
                        state <= INTERP;
                        pending_valid <= 1'b0;
                    end
                end

                INTERP: begin
                    if (cnt == 3'd7) begin
                        if (pending_valid) begin
                            prev_sample <= cur_sample;
                            cur_sample <= pending_sample;
                            cnt <= 3'd0;
                            data_out <= interp(cur_sample, pending_sample, 1);
                            valid_out <= 1'b1;
                            state <= INTERP;
                            if (valid_in) begin
                                pending_sample <= data_in;
                                pending_valid <= 1'b1;
                            end else begin
                                pending_valid <= 1'b0;
                            end
                        end else if (valid_in) begin
                            prev_sample <= cur_sample;
                            cur_sample <= data_in;
                            cnt <= 3'd0;
                            data_out <= interp(cur_sample, data_in, 1);
                            valid_out <= 1'b1;
                            state <= INTERP;
                            pending_valid <= 1'b0;
                        end else begin
                            prev_sample <= cur_sample;
                            state <= WAIT_SAMPLE;
                            valid_out <= 1'b0;
                        end
                    end else begin
                        cnt <= cnt + 1'b1;
                        data_out <= interp(prev_sample, cur_sample, cnt + 2);
                        valid_out <= 1'b1;
                        if (valid_in) begin
                            if (!pending_valid) begin
                                pending_sample <= data_in;
                                pending_valid <= 1'b1;
                            end
                        end
                    end
                end

                default: state <= IDLE_FIRST;
            endcase
        end
    end

endmodule
