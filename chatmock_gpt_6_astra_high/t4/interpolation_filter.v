module fir_interpolator (
    input  wire               clk,
    input  wire               rst,
    input  wire               valid_in,
    input  wire signed [15:0] data_in,
    output reg                valid_out,
    output reg  signed [15:0] data_out
);

    // Buffer samples that arrive while an interpolation segment is active.
    localparam integer FIFO_ADDR_WIDTH = 10;
    localparam integer FIFO_DEPTH = (1 << FIFO_ADDR_WIDTH);

    reg signed [15:0] sample_fifo [0:FIFO_DEPTH-1];
    reg [FIFO_ADDR_WIDTH-1:0] read_ptr;
    reg [FIFO_ADDR_WIDTH-1:0] write_ptr;
    reg [FIFO_ADDR_WIDTH:0]   fifo_count;

    reg                      have_previous;
    reg                      active;
    reg [3:0]                phase;
    reg signed [15:0]        previous_sample;
    reg signed [15:0]        current_sample;
    reg signed [16:0]        difference;

    wire                     fifo_empty;
    wire                     fifo_full;
    wire                     consume_sample;
    wire                     pop_fifo;
    wire                     bypass_fifo;
    wire                     push_fifo;
    wire signed [15:0]       next_sample;

    wire signed [31:0]       previous_extended;
    wire signed [31:0]       next_extended;
    wire signed [31:0]       next_difference;
    wire signed [31:0]       difference_extended;
    wire signed [31:0]       phase_extended;
    wire signed [31:0]       phase_product;
    wire signed [31:0]       first_phase_result;
    wire signed [31:0]       active_phase_result;

    assign fifo_empty = (fifo_count == 0);
    assign fifo_full  = (fifo_count == FIFO_DEPTH);

    assign consume_sample = !active && (!fifo_empty || valid_in);
    assign pop_fifo       = consume_sample && !fifo_empty;
    assign bypass_fifo    = consume_sample && fifo_empty;
    assign push_fifo      = valid_in && !bypass_fifo &&
                            (!fifo_full || pop_fifo);

    assign next_sample = fifo_empty ? data_in : sample_fifo[read_ptr];

    assign previous_extended = {{16{previous_sample[15]}}, previous_sample};
    assign next_extended     = {{16{next_sample[15]}}, next_sample};
    assign next_difference   = next_extended - previous_extended;

    assign difference_extended = {{15{difference[16]}}, difference};
    assign phase_extended      = {28'd0, phase};
    assign phase_product       = difference_extended * phase_extended;

    // Signed division truncates toward zero, including negative slopes.
    assign first_phase_result =
        previous_extended + (next_difference / 32'sd8);

    assign active_phase_result =
        previous_extended + (phase_product / 32'sd8);

    always @(posedge clk) begin
        if (rst) begin
            read_ptr        <= {FIFO_ADDR_WIDTH{1'b0}};
            write_ptr       <= {FIFO_ADDR_WIDTH{1'b0}};
            fifo_count      <= {(FIFO_ADDR_WIDTH+1){1'b0}};
            have_previous   <= 1'b0;
            active          <= 1'b0;
            phase           <= 4'd0;
            previous_sample <= 16'sd0;
            current_sample  <= 16'sd0;
            difference      <= 17'sd0;
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

            if (active) begin
                data_out  <= active_phase_result[15:0];
                valid_out <= 1'b1;

                if (phase == 4'd8) begin
                    previous_sample <= current_sample;
                    active          <= 1'b0;
                    phase           <= 4'd0;
                end else begin
                    phase <= phase + 1'b1;
                end
            end else if (consume_sample) begin
                valid_out <= 1'b1;

                if (!have_previous) begin
                    data_out        <= next_sample;
                    previous_sample <= next_sample;
                    have_previous   <= 1'b1;
                end else begin
                    // Emit k=1 now, followed by k=2 through k=8.
                    data_out       <= first_phase_result[15:0];
                    current_sample <= next_sample;
                    difference     <= next_difference[16:0];
                    phase          <= 4'd2;
                    active         <= 1'b1;
                end
            end
        end
    end

endmodule
