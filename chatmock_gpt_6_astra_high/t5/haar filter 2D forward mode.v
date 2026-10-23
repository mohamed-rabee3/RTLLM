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

    reg [7:0] image_mem [0:255];

    reg       processing;
    reg [2:0] coeff_row;
    reg [2:0] coeff_col;

    wire [7:0] addr_top_even;
    wire [7:0] addr_top_odd;
    wire [7:0] addr_bottom_even;
    wire [7:0] addr_bottom_odd;

    reg signed [31:0] top_difference;
    reg signed [31:0] bottom_difference;
    reg signed [31:0] top_high;
    reg signed [31:0] bottom_high;
    reg signed [31:0] vertical_sum;
    reg signed [31:0] lh_coefficient;

    assign addr_top_even    = {coeff_row, 1'b0, coeff_col, 1'b0};
    assign addr_top_odd     = {coeff_row, 1'b0, coeff_col, 1'b1};
    assign addr_bottom_even = {coeff_row, 1'b1, coeff_col, 1'b0};
    assign addr_bottom_odd  = {coeff_row, 1'b1, coeff_col, 1'b1};

    // Apply each fixed-point scaling separately. Arithmetic shifts
    // preserve the sign of negative high-pass coefficients.
    always @* begin
        top_difference =
            $signed({1'b0, image_mem[addr_top_even]}) -
            $signed({1'b0, image_mem[addr_top_odd]});

        bottom_difference =
            $signed({1'b0, image_mem[addr_bottom_even]}) -
            $signed({1'b0, image_mem[addr_bottom_odd]});

        top_high       = (top_difference    * 32'sd181) >>> 8;
        bottom_high    = (bottom_difference * 32'sd181) >>> 8;
        vertical_sum   = top_high + bottom_high;
        lh_coefficient = (vertical_sum * 32'sd181) >>> 8;
    end

    // Image storage need not be reset: a complete image is loaded
    // before processing starts.
    always @(posedge clk) begin
        if (rst_n && !processing && valid_in)
            image_mem[{row, col}] <= data_in;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            processing <= 1'b0;
            coeff_row  <= 3'd0;
            coeff_col  <= 3'd0;
            data_out   <= 16'sd0;
            valid_out  <= 1'b0;
            out_row    <= 3'd0;
            out_col    <= 3'd0;
        end else begin
            valid_out <= 1'b0;

            if (!processing) begin
                if (valid_in && row == 4'd15 && col == 4'd15) begin
                    processing <= 1'b1;
                    coeff_row  <= 3'd0;
                    coeff_col  <= 3'd0;
                end
            end else begin
                data_out  <= lh_coefficient[15:0];
                valid_out <= 1'b1;
                out_row   <= coeff_row;
                out_col   <= coeff_col;

                if (coeff_col == 3'd7) begin
                    coeff_col <= 3'd0;
                    if (coeff_row == 3'd7) begin
                        coeff_row  <= 3'd0;
                        processing <= 1'b0;
                    end else begin
                        coeff_row <= coeff_row + 3'd1;
                    end
                end else begin
                    coeff_col <= coeff_col + 3'd1;
                end
            end
        end
    end

endmodule
