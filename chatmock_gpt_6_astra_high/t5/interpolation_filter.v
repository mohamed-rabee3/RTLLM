module fir_interpolator (
    input  wire               clk,
    input  wire               rst,
    input  wire               valid_in,
    input  wire signed [15:0] data_in,
    output reg                valid_out,
    output reg signed [15:0] data_out
);

    // Buffer input bursts while an interpolation interval is being emitted.
    localparam integer FIFO_DEPTH = 1024;
    localparam integer PTR_WIDTH  = 10;

    reg signed [15:0] sample_fifo [0:FIFO_DEPTH-1];
    reg [PTR_WIDTH-1:0] write_ptr;
    reg [PTR_WIDTH-1:0] read_ptr;
    reg [PTR_WIDTH:0]   fifo_count;

    reg                have_previous;
    reg signed [15:0]  previous_sample;
    reg                active;
    reg signed [15:0]  interval_base;
    reg signed [16:0]  interval_difference;
    reg [3:0]          phase;

    wire fifo_empty;
    wire fifo_full;
    wire bypass_input;
    wire pop_fifo;
    wire push_fifo;
    wire take_sample;

    wire signed [15:0] selected_sample;
    wire signed [16:0] new_difference;
    wire signed [31:0] previous_extended;
    wire signed [31:0] new_difference_extended;
    wire signed [31:0] first_phase_result;
    wire signed [31:0] base_extended;
    wire signed [31:0] difference_extended;
    wire signed [31:0] phase_extended;
    wire signed [31:0] scaled_difference;
    wire signed [31:0] interpolated_result;

    assign fifo_empty = (fifo_count == 0);
    assign fifo_full  = (fifo_count == FIFO_DEPTH);

    // An idle interpolator can consume a new input without FIFO latency.
    assign bypass_input = !active && fifo_empty && valid_in;
    assign pop_fifo     = !active && !fifo_empty;
    assign push_fifo    = valid_in && !bypass_input &&
                          (!fifo_full || pop_fifo);
    assign take_sample  = bypass_input || pop_fifo;

    assign selected_sample = fifo_empty ? data_in : sample_fifo[read_ptr];

    // Extend before subtracting to preserve the full signed difference.
    assign new_difference =
        $signed({selected_sample[15], selected_sample}) -
        $signed({previous_sample[15], previous_sample});

    assign previous_extended =
        {{16{previous_sample[15]}}, previous_sample};
    assign new_difference_extended =
        {{15{new_difference[16]}}, new_difference};

    // Signed division truncates toward zero, including negative differences.
    assign first_phase_result =
        previous_extended + (new_difference_extended / 32'sd8);

    assign base_extended =
        {{16{interval_base[15]}}, interval_base};
    assign difference_extended =
        {{15{interval_difference[16]}}, interval_difference};
    assign phase_extended = {28'd0, phase};
    assign scaled_difference = difference_extended * phase_extended;
    assign interpolated_result =
        base_extended + (scaled_difference / 32'sd8);

    always @(posedge clk) begin
        if (rst) begin
            write_ptr           <= {PTR_WIDTH{1'b0}};
            read_ptr            <= {PTR_WIDTH{1'b0}};
            fifo_count          <= {(PTR_WIDTH+1){1'b0}};
            have_previous       <= 1'b0;
            previous_sample     <= 16'sd0;
            active              <= 1'b0;
            interval_base       <= 16'sd0;
            interval_difference <= 17'sd0;
            phase               <= 4'd0;
            valid_out           <= 1'b0;
            data_out            <= 16'sd0;
        end else begin
            valid_out <= 1'b0;

            if (push_fifo) begin
                sample_fifo[write_ptr] <= data_in;
                write_ptr <= write_ptr + 1'b1;
            end

            if (pop_fifo)
                read_ptr <= read_ptr + 1'b1;

            case ({push_fifo, pop_fifo})
                2'b10: fifo_count <= fifo_count + 1'b1;
                2'b01: fifo_count <= fifo_count - 1'b1;
                default: fifo_count <= fifo_count;
            endcase

            if (active) begin
                valid_out <= 1'b1;
                data_out  <= interpolated_result[15:0];

                if (phase == 4'd8) begin
                    active <= 1'b0;
                    phase  <= 4'd0;
                end else begin
                    phase <= phase + 1'b1;
                end
            end else if (take_sample) begin
                valid_out       <= 1'b1;
                previous_sample <= selected_sample;

                if (!have_previous) begin
                    // The first sample is emitted exactly once.
                    data_out      <= selected_sample;
                    have_previous <= 1'b1;
                end else begin
                    // Emit phase 1 now, then phases 2 through 8.
                    data_out            <= first_phase_result[15:0];
                    interval_base       <= previous_sample;
                    interval_difference <= new_difference;
                    phase               <= 4'd2;
                    active              <= 1'b1;
                end
            end
        end
    end

endmodule
