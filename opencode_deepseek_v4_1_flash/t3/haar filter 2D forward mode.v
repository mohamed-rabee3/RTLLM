module haar_wavelet_lh_only (
    input clk,
    input rst_n,
    input valid_in,
    input [3:0] row,
    input [3:0] col,
    input [7:0] data_in,
    output signed [15:0] data_out,
    output valid_out,
    output [2:0] out_row,
    output [2:0] out_col
);

    reg [7:0] img [0:255];
    reg state;
    reg [5:0] count;

    localparam IDLE   = 1'b0;
    localparam OUTPUT = 1'b1;

    wire [2:0] r_idx;
    wire [2:0] c_idx;
    wire [3:0] row0, row1, col0, col1;
    wire [7:0] p00, p01, p10, p11;
    wire signed [8:0] diff_top, diff_bot;
    wire signed [15:0] top_h, bot_h, sum_h, lh;

    assign r_idx = count[5:3];
    assign c_idx = count[2:0];

    assign row0 = {r_idx, 1'b0};
    assign row1 = row0 + 4'd1;
    assign col0 = {c_idx, 1'b0};
    assign col1 = col0 + 4'd1;

    assign p00 = img[{row0, col0}];
    assign p01 = img[{row0, col1}];
    assign p10 = img[{row1, col0}];
    assign p11 = img[{row1, col1}];

    assign diff_top = $signed({1'b0, p00}) - $signed({1'b0, p01});
    assign diff_bot = $signed({1'b0, p10}) - $signed({1'b0, p11});

    assign top_h = (diff_top * 181) >>> 8;
    assign bot_h = (diff_bot * 181) >>> 8;
    assign sum_h = top_h + bot_h;
    assign lh = (sum_h * 181) >>> 8;

    assign data_out = lh;
    assign valid_out = (state == OUTPUT);
    assign out_row = r_idx;
    assign out_col = c_idx;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            count <= 6'd0;
        end else begin
            if (valid_in && state == IDLE) begin
                img[{row, col}] <= data_in;
            end

            if (state == IDLE) begin
                count <= 6'd0;
                if (valid_in && row == 4'd15 && col == 4'd15) begin
                    state <= OUTPUT;
                end
            end else if (state == OUTPUT) begin
                if (count == 6'd63) begin
                    state <= IDLE;
                    count <= 6'd0;
                end else begin
                    count <= count + 6'd1;
                end
            end
        end
    end

endmodule
