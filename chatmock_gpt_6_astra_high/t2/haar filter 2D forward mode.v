module haar_wavelet_lh_only (
    input  wire               clk,
    input  wire               rst_n,
    input  wire               valid_in,
    input  wire [3:0]         row,
    input  wire [3:0]         col,
    input  wire [7:0]         data_in,
    output reg  signed [15:0] data_out,
    output reg                valid_out,
    output reg  [2:0]         out_row,
    output reg  [2:0]         out_col
);

    reg [7:0] image [0:255];

    reg       emitting;
    reg [2:0] emit_row;
    reg [2:0] emit_col;

    wire [7:0] addr_top_even;
    wire [7:0] addr_top_odd;
    wire [7:0] addr_bottom_even;
    wire [7:0] addr_bottom_odd;

    reg signed [31:0] top_difference;
    reg signed [31:0] bottom_difference;
    reg signed [31:0] top_high;
    reg signed [31:0] bottom_high;
    reg signed [31:0] lh_value;

    assign addr_top_even    = {emit_row, 1'b0, emit_col, 1'b0};
    assign addr_top_odd     = {emit_row, 1'b0, emit_col, 1'b1};
    assign addr_bottom_even = {emit_row, 1'b1, emit_col, 1'b0};
    assign addr_bottom_odd  = {emit_row, 1'b1, emit_col, 1'b1};

    // Arithmetic shifts implement signed fixed-point scaling by 181/256.
    // Each horizontal result is quantized before the vertical operation.
    always @* begin
        top_difference =
            $signed({1'b0, image[addr_top_even]}) -
            $signed({1'b0, image[addr_top_odd]});

        bottom_difference =
            $signed({1'b0, image[addr_bottom_even]}) -
            $signed({1'b0, image[addr_bottom_odd]});

        top_high    = (top_difference    * 32'sd181) >>> 8;
        bottom_high = (bottom_difference * 32'sd181) >>> 8;

        lh_value = ((top_high + bottom_high) * 32'sd181) >>> 8;
    end

    // The image buffer need not be reset: a complete image is loaded
    // before any coefficients are emitted.
    always @(posedge clk) begin
        if (rst_n && !emitting && valid_in)
            image[{row, col}] <= data_in;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            emitting  <= 1'b0;
            emit_row  <= 3'd0;
            emit_col  <= 3'd0;
            data_out  <= 16'sd0;
            valid_out <= 1'b0;
            out_row   <= 3'd0;
            out_col   <= 3'd0;
        end else begin
            valid_out <= 1'b0;

            if (!emitting) begin
                if (valid_in && (row == 4'd15) && (col == 4'd15)) begin
                    emitting <= 1'b1;
                    emit_row <= 3'd0;
                    emit_col <= 3'd0;
                end
            end else begin
                data_out  <= lh_value[15:0];
                valid_out <= 1'b1;
                out_row   <= emit_row;
                out_col   <= emit_col;

                if (emit_col == 3'd7) begin
                    emit_col <= 3'd0;
                    if (emit_row == 3'd7) begin
                        emit_row <= 3'd0;
                        emitting <= 1'b0;
                    end else begin
                        emit_row <= emit_row + 3'd1;
                    end
                end else begin
                    emit_col <= emit_col + 3'd1;
                end
            end
        end
    end

endmodule
