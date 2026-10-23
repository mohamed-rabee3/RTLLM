module fir_interpolator (
    input  wire               clk,
    input  wire               rst,
    input  wire               valid_in,
    input  wire signed [15:0] data_in,
    output reg                valid_out,
    output reg  signed [15:0] data_out
);

    localparam integer FIFO_ADDR_WIDTH = 10;
    localparam integer FIFO_DEPTH      = (1 << FIFO_ADDR_WIDTH);

    reg signed [15:0] sample_fifo [0:FIFO_DEPTH-1];
    reg [FIFO_ADDR_WIDTH-1:0] read_ptr;
    reg [FIFO_ADDR_WIDTH-1:0] write_ptr;
    reg [FIFO_ADDR_WIDTH:0]   fifo_count;

    reg                      have_previous;
    reg                      busy;
    reg signed [15:0]        previous_sample;
    reg signed [15:0]        bridge_start;
    reg signed [15:0]        bridge_end;
    reg [3:0]                phase;

    wire fifo_empty;
    wire fifo_full;
    wire fifo_pop;
    wire fifo_push;
    wire sample_available;
    wire signed [15:0] next_sample;

    assign fifo_empty = (fifo_count == 0);
    assign fifo_full  = (fifo_count == FIFO_DEPTH);

    assign fifo_pop = !busy && !fifo_empty;

    // When idle with an empty FIFO, consume data_in directly.
    // Otherwise buffer incoming samples while earlier outputs are emitted.
    assign fifo_push = valid_in &&
                       (busy || !fifo_empty) &&
                       (!fifo_full || fifo_pop);

    assign sample_available = !fifo_empty || valid_in;
    assign next_sample = fifo_empty ? data_in : sample_fifo[read_ptr];

    function signed [15:0] interpolate;
        input signed [15:0] start_sample;
        input signed [15:0] end_sample;
        input        [3:0]  sample_phase;

        reg signed [16:0] difference;
        reg signed [20:0] product;
        reg signed [20:0] offset;
        reg signed [20:0] result;
        begin
            difference = $signed({end_sample[15], end_sample}) -
                         $signed({start_sample[15], start_sample});

            product = difference * $signed({1'b0, sample_phase});

            // Signed division truncates toward zero, including for
            // negative differences.
            offset = product / 21'sd8;

            result = $signed({{5{start_sample[15]}}, start_sample}) +
                     offset;

            interpolate = result[15:0];
        end
    endfunction

    always @(posedge clk) begin
        if (rst) begin
            read_ptr        <= {FIFO_ADDR_WIDTH{1'b0}};
            write_ptr       <= {FIFO_ADDR_WIDTH{1'b0}};
            fifo_count      <= {(FIFO_ADDR_WIDTH+1){1'b0}};

            have_previous   <= 1'b0;
            busy            <= 1'b0;
            previous_sample <= 16'sd0;
            bridge_start    <= 16'sd0;
            bridge_end      <= 16'sd0;
            phase           <= 4'd0;

            valid_out       <= 1'b0;
            data_out        <= 16'sd0;
        end else begin
            valid_out <= 1'b0;

            if (fifo_push) begin
                sample_fifo[write_ptr] <= data_in;
                write_ptr <= write_ptr + 1'b1;
            end

            if (fifo_pop)
                read_ptr <= read_ptr + 1'b1;

            case ({fifo_push, fifo_pop})
                2'b10: fifo_count <= fifo_count + 1'b1;
                2'b01: fifo_count <= fifo_count - 1'b1;
                default: fifo_count <= fifo_count;
            endcase

            if (busy) begin
                data_out  <= interpolate(bridge_start, bridge_end, phase);
                valid_out <= 1'b1;

                if (phase == 4'd8) begin
                    busy  <= 1'b0;
                    phase <= 4'd0;
                end else begin
                    phase <= phase + 1'b1;
                end
            end else if (sample_available) begin
                previous_sample <= next_sample;
                valid_out       <= 1'b1;

                if (!have_previous) begin
                    data_out      <= next_sample;
                    have_previous <= 1'b1;
                end else begin
                    data_out     <= interpolate(previous_sample,
                                                next_sample, 4'd1);
                    bridge_start <= previous_sample;
                    bridge_end   <= next_sample;
                    phase        <= 4'd2;
                    busy         <= 1'b1;
                end
            end
        end
    end

endmodule
