module fir_interpolator (
    input  wire               clk,
    input  wire               rst,
    input  wire               valid_in,
    input  wire signed [15:0] data_in,
    output reg                valid_out,
    output reg signed [15:0] data_out
);

    // Buffer input samples arriving while an interpolation is in progress.
    localparam integer FIFO_DEPTH = 1024;
    localparam integer FIFO_AW    = 10;

    reg signed [15:0] sample_fifo [0:FIFO_DEPTH-1];
    reg [FIFO_AW-1:0] read_ptr;
    reg [FIFO_AW-1:0] write_ptr;
    reg [FIFO_AW:0]   fifo_count;

    reg               have_previous;
    reg               busy;
    reg [3:0]         phase;
    reg signed [15:0] previous_sample;
    reg signed [15:0] current_sample;

    wire fifo_empty;
    wire fifo_full;
    wire dequeue;
    wire bypass;
    wire enqueue;
    wire sample_available;
    wire signed [15:0] next_sample;

    assign fifo_empty = (fifo_count == 0);
    assign fifo_full  = (fifo_count == FIFO_DEPTH);

    assign dequeue = !busy && !fifo_empty;
    assign bypass  = !busy && fifo_empty && valid_in;
    assign enqueue = valid_in && !bypass && (!fifo_full || dequeue);

    assign sample_available = dequeue || bypass;
    assign next_sample = fifo_empty ? data_in : sample_fifo[read_ptr];

    // Signed division truncates toward zero, including for negative slopes.
    function signed [15:0] interpolate;
        input signed [15:0] first_sample;
        input signed [15:0] last_sample;
        input        [3:0]  step;

        reg signed [16:0] difference;
        reg signed [21:0] product;
        reg signed [21:0] result;
        begin
            difference = {last_sample[15], last_sample}
                       - {first_sample[15], first_sample};
            product = difference * $signed({1'b0, step});
            result = {{6{first_sample[15]}}, first_sample}
                   + (product / 22'sd8);
            interpolate = result[15:0];
        end
    endfunction

    always @(posedge clk) begin
        if (rst) begin
            read_ptr   <= {FIFO_AW{1'b0}};
            write_ptr  <= {FIFO_AW{1'b0}};
            fifo_count <= {(FIFO_AW+1){1'b0}};
        end else begin
            if (enqueue) begin
                sample_fifo[write_ptr] <= data_in;
                write_ptr <= write_ptr + 1'b1;
            end

            if (dequeue)
                read_ptr <= read_ptr + 1'b1;

            case ({enqueue, dequeue})
                2'b10: fifo_count <= fifo_count + 1'b1;
                2'b01: fifo_count <= fifo_count - 1'b1;
                default: fifo_count <= fifo_count;
            endcase
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            valid_out       <= 1'b0;
            data_out        <= 16'sd0;
            have_previous   <= 1'b0;
            busy            <= 1'b0;
            phase           <= 4'd0;
            previous_sample <= 16'sd0;
            current_sample  <= 16'sd0;
        end else begin
            valid_out <= 1'b0;

            if (busy) begin
                data_out <= interpolate(previous_sample, current_sample, phase);
                valid_out <= 1'b1;

                if (phase == 4'd8) begin
                    previous_sample <= current_sample;
                    busy  <= 1'b0;
                    phase <= 4'd0;
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
                    data_out <= interpolate(previous_sample, next_sample, 4'd1);
                    current_sample <= next_sample;
                    phase <= 4'd2;
                    busy  <= 1'b1;
                end
            end
        end
    end

endmodule
