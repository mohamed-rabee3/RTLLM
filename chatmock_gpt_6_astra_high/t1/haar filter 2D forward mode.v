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
    reg [5:0] output_index;

    wire [7:0] top_even_addr;
    wire [7:0] top_odd_addr;
    wire [7:0] bottom_even_addr;
    wire [7:0] bottom_odd_addr;

    wire signed [31:0] top_difference;
    wire signed [31:0] bottom_difference;
    wire signed [31:0] top_high;
    wire signed [31:0] bottom_high;
    wire signed [31:0] lh_coefficient;

    assign top_even_addr =
        {output_index[5:3], 1'b0, output_index[2:0], 1'b0};
    assign top_odd_addr =
        {output_index[5:3], 1'b0, output_index[2:0], 1'b1};
    assign bottom_even_addr =
        {output_index[5:3], 1'b1, output_index[2:0], 1'b0};
    assign bottom_odd_addr =
        {output_index[5:3], 1'b1, output_index[2:0], 1'b1};

    // Zero-extend unsigned pixels before performing signed subtraction.
    assign top_difference =
        $signed({1'b0, image_mem[top_even_addr]}) -
        $signed({1'b0, image_mem[top_odd_addr]});

    assign bottom_difference =
        $signed({1'b0, image_mem[bottom_even_addr]}) -
        $signed({1'b0, image_mem[bottom_odd_addr]});

    // Truncate the fixed-point result after each Haar stage.
    assign top_high =
        (top_difference * 32'sd181) >>> 8;

    assign bottom_high =
        (bottom_difference * 32'sd181) >>> 8;

    assign lh_coefficient =
        ((top_high + bottom_high) * 32'sd181) >>> 8;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            processing   <= 1'b0;
            output_index <= 6'd0;
            data_out     <= 16'sd0;
            valid_out    <= 1'b0;
            out_row      <= 3'd0;
            out_col      <= 3'd0;
        end else begin
            valid_out <= 1'b0;

            if (!processing) begin
                if (valid_in) begin
                    image_mem[{row, col}] <= data_in;

                    if ((row == 4'd15) && (col == 4'd15)) begin
                        processing   <= 1'b1;
                        output_index <= 6'd0;
                    end
                end
            end else begin
                data_out  <= lh_coefficient[15:0];
                valid_out <= 1'b1;
                out_row   <= output_index[5:3];
                out_col   <= output_index[2:0];

                if (output_index == 6'd63) begin
                    processing   <= 1'b0;
                    output_index <= 6'd0;
                end else begin
                    output_index <= output_index + 6'd1;
                end
            end
        end
    end

endmodule
