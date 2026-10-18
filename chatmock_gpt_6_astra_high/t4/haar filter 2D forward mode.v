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
    reg       emitting;
    reg [5:0] coefficient_index;

    wire [7:0] address_top_even;
    wire [7:0] address_top_odd;
    wire [7:0] address_bottom_even;
    wire [7:0] address_bottom_odd;

    wire signed [31:0] pixel_top_even;
    wire signed [31:0] pixel_top_odd;
    wire signed [31:0] pixel_bottom_even;
    wire signed [31:0] pixel_bottom_odd;

    wire signed [31:0] difference_top;
    wire signed [31:0] difference_bottom;
    wire signed [31:0] product_top;
    wire signed [31:0] product_bottom;
    wire signed [31:0] high_pass_top;
    wire signed [31:0] high_pass_bottom;
    wire signed [31:0] vertical_sum;
    wire signed [31:0] vertical_product;
    wire signed [31:0] lh_coefficient;

    assign address_top_even =
        {coefficient_index[5:3], 1'b0,
         coefficient_index[2:0], 1'b0};

    assign address_top_odd =
        {coefficient_index[5:3], 1'b0,
         coefficient_index[2:0], 1'b1};

    assign address_bottom_even =
        {coefficient_index[5:3], 1'b1,
         coefficient_index[2:0], 1'b0};

    assign address_bottom_odd =
        {coefficient_index[5:3], 1'b1,
         coefficient_index[2:0], 1'b1};

    // Zero-extend unsigned pixels before signed arithmetic.
    assign pixel_top_even    = {24'd0, image_mem[address_top_even]};
    assign pixel_top_odd     = {24'd0, image_mem[address_top_odd]};
    assign pixel_bottom_even = {24'd0, image_mem[address_bottom_even]};
    assign pixel_bottom_odd  = {24'd0, image_mem[address_bottom_odd]};

    assign difference_top    = pixel_top_even - pixel_top_odd;
    assign difference_bottom = pixel_bottom_even - pixel_bottom_odd;

    // Horizontal high-pass, with fixed-point scaling at each stage.
    assign product_top      = difference_top    * 32'sd181;
    assign product_bottom   = difference_bottom * 32'sd181;
    assign high_pass_top    = product_top    >>> 8;
    assign high_pass_bottom = product_bottom >>> 8;

    // Vertical low-pass.
    assign vertical_sum     = high_pass_top + high_pass_bottom;
    assign vertical_product = vertical_sum * 32'sd181;
    assign lh_coefficient   = vertical_product >>> 8;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            emitting          <= 1'b0;
            coefficient_index <= 6'd0;
            data_out          <= 16'sd0;
            valid_out         <= 1'b0;
            out_row           <= 3'd0;
            out_col           <= 3'd0;
        end else begin
            valid_out <= 1'b0;

            if (emitting) begin
                data_out  <= lh_coefficient[15:0];
                valid_out <= 1'b1;
                out_row   <= coefficient_index[5:3];
                out_col   <= coefficient_index[2:0];

                if (coefficient_index == 6'd63) begin
                    emitting          <= 1'b0;
                    coefficient_index <= 6'd0;
                end else begin
                    coefficient_index <= coefficient_index + 6'd1;
                end
            end else if (valid_in) begin
                image_mem[{row, col}] <= data_in;

                if ((row == 4'd15) && (col == 4'd15)) begin
                    emitting          <= 1'b1;
                    coefficient_index <= 6'd0;
                end
            end
        end
    end

endmodule
