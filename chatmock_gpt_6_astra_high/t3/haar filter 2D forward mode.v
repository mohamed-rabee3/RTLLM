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
    reg [2:0] calc_row;
    reg [2:0] calc_col;

    wire [7:0] addr_top_even;
    wire [7:0] addr_top_odd;
    wire [7:0] addr_bottom_even;
    wire [7:0] addr_bottom_odd;

    assign addr_top_even    = {calc_row, 1'b0, calc_col, 1'b0};
    assign addr_top_odd     = {calc_row, 1'b0, calc_col, 1'b1};
    assign addr_bottom_even = {calc_row, 1'b1, calc_col, 1'b0};
    assign addr_bottom_odd  = {calc_row, 1'b1, calc_col, 1'b1};

    wire signed [8:0] top_difference;
    wire signed [8:0] bottom_difference;

    assign top_difference =
        $signed({1'b0, image_mem[addr_top_even]}) -
        $signed({1'b0, image_mem[addr_top_odd]});

    assign bottom_difference =
        $signed({1'b0, image_mem[addr_bottom_even]}) -
        $signed({1'b0, image_mem[addr_bottom_odd]});

    wire signed [31:0] top_product;
    wire signed [31:0] bottom_product;
    wire signed [31:0] top_high;
    wire signed [31:0] bottom_high;
    wire signed [31:0] vertical_sum;
    wire signed [31:0] vertical_product;
    wire signed [31:0] lh_coefficient;

    assign top_product      = top_difference    * 32'sd181;
    assign bottom_product   = bottom_difference * 32'sd181;
    assign top_high         = top_product    >>> 8;
    assign bottom_high      = bottom_product >>> 8;
    assign vertical_sum     = top_high + bottom_high;
    assign vertical_product = vertical_sum * 32'sd181;
    assign lh_coefficient   = vertical_product >>> 8;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            processing <= 1'b0;
            calc_row   <= 3'd0;
            calc_col   <= 3'd0;
            data_out   <= 16'sd0;
            valid_out  <= 1'b0;
            out_row    <= 3'd0;
            out_col    <= 3'd0;
        end else begin
            valid_out <= 1'b0;

            if (!processing) begin
                if (valid_in) begin
                    image_mem[{row, col}] <= data_in;

                    if ((row == 4'd15) && (col == 4'd15)) begin
                        processing <= 1'b1;
                        calc_row   <= 3'd0;
                        calc_col   <= 3'd0;
                    end
                end
            end else begin
                data_out  <= lh_coefficient[15:0];
                valid_out <= 1'b1;
                out_row   <= calc_row;
                out_col   <= calc_col;

                if (calc_col == 3'd7) begin
                    calc_col <= 3'd0;

                    if (calc_row == 3'd7) begin
                        calc_row   <= 3'd0;
                        processing <= 1'b0;
                    end else begin
                        calc_row <= calc_row + 3'd1;
                    end
                end else begin
                    calc_col <= calc_col + 3'd1;
                end
            end
        end
    end

endmodule
