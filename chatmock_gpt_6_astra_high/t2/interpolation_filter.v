module fir_interpolator (
    input  wire               clk,
    input  wire               rst,
    input  wire               valid_in,
    input  wire signed [15:0] data_in,
    output reg                valid_out,
    output reg signed [15:0]  data_out
);

    // Buffer samples that arrive while an interpolation segment is emitted.
    localparam integer FIFO_ADDR_WIDTH = 10;
    localparam integer FIFO_DEPTH      = (1 << FIFO_ADDR_WIDTH);

    reg signed [15:0] sample_fifo [0:FIFO_DEPTH-1];
    reg [FIFO_ADDR_WIDTH-1:0] read_ptr;
    reg [FIFO_ADDR_WIDTH-1:0] write_ptr;
    reg [FIFO_ADDR_WIDTH:0]   fifo_count;

    reg signed [15:0] previous_sample;
    reg signed [15:0] current_sample;
    reg               have_previous;
    reg               busy;
    reg [3:0]         phase;

    wire fifo_empty;
    wire fifo_full;
    wire pop_fifo;
    wire bypass_fifo;
    wire push_fifo;
    wire sample_available;
    wire signed [15:0] next_sample;

    assign fifo_empty = (fifo_count == 0);
    assign fifo_full  = (fifo_count == FIFO_DEPTH);

    assign pop_fifo    = !busy && !fifo_empty;
    assign bypass_fifo = !busy && fifo_empty && valid_in;
    assign push_fifo   = valid_in && !bypass_fifo &&
                         (!fifo_full || pop_fifo);

    assign sample_available = !fifo_empty || valid_in;
    assign next_sample = fifo_empty ? data_in : sample_fifo[read_ptr];

    // Signed division truncates toward zero, including negative differences.
    function signed [15:0] interpolate;
        input signed [15:0] previous_value;
        input signed [15:0] current_value;
        input        [3:0] interpolation_phase;

        reg signed [16:0] difference;
        reg signed [21:0] extended_difference;
        reg signed [21:0] extended_phase;
        reg signed [21:0] product;
        reg signed [21:0] result;
        begin
            difference =
                $signed({current_value[15], current_value}) -
                $signed({previous_value[15], previous_value});

            extended_difference = {{5{difference[16]}}, difference};
            extended_phase      = {18'd0, interpolation_phase};
            product             = extended_difference * extended_phase;

            result = $signed({{6{previous_value[15]}}, previous_value}) +
                     (product / 22'sd8);

            interpolate = result[15:0];
        end
    endfunction

    always @(posedge clk) begin
        if (rst) begin
            read_ptr        <= {FIFO_ADDR_WIDTH{1'b0}};
            write_ptr       <= {FIFO_ADDR_WIDTH{1'b0}};
            fifo_count      <= {(FIFO_ADDR_WIDTH+1){1'b0}};
            previous_sample <= 16'sd0;
            current_sample  <= 16'sd0;
            have_previous   <= 1'b0;
            busy            <= 1'b0;
            phase           <= 4'd0;
            valid_out       <= 1'b0;
            data_out        <= 16'sd0;
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

            if (busy) begin
                valid_out <= 1'b1;
                data_out  <= interpolate(previous_sample,
                                         current_sample,
                                         phase);

                if (phase == 4'd8) begin
                    previous_sample <= current_sample;
                    busy            <= 1'b0;
                    phase           <= 4'd0;
                end else begin
                    phase <= phase + 1'b1;
                end
            end else if (sample_available) begin
                valid_out <= 1'b1;

                if (!have_previous) begin
                    data_out        <= next_sample;
                    previous_sample <= next_sample;
                    have_previous   <= 1'b1;
                end else begin
                    data_out       <= interpolate(previous_sample,
                                                  next_sample,
                                                  4'd1);
                    current_sample <= next_sample;
                    phase          <= 4'd2;
                    busy           <= 1'b1;
                end
            end
        end
    end

endmodule
