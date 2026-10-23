module haar_wavelet_lh_only (
    input clk,
    input rst_n,
    input valid_in,
    input [3:0] row,
    input [3:0] col,
    input [7:0] data_in,
    output reg signed [15:0] data_out,
    output reg valid_out,
    output reg [2:0] out_row,
    output reg [2:0] out_col
);

    reg [7:0] mem [0:255];
    reg state;
    reg [5:0] out_cnt;

    localparam IDLE   = 1'b0;
    localparam OUTPUT = 1'b1;
    localparam signed [8:0] SCALE = 9'sd181;

    wire [2:0] r = out_cnt[5:3];
    wire [2:0] c = out_cnt[2:0];

    wire [3:0] row_even = {r, 1'b0};
    wire [3:0] row_odd  = row_even + 4'd1;
    wire [3:0] col_even = {c, 1'b0};
    wire [3:0] col_odd  = col_even + 4'd1;

    wire [7:0] addr00 = {row_even, col_even};
    wire [7:0] addr01 = {row_even, col_odd};
    wire [7:0] addr10 = {row_odd,  col_even};
    wire [7:0] addr11 = {row_odd,  col_odd};

    wire [7:0] p00 = mem[addr00];
    wire [7:0] p01 = mem[addr01];
    wire [7:0] p10 = mem[addr10];
    wire [7:0] p11 = mem[addr11];

    wire signed [8:0] p00_s = {1'b0, p00};
    wire signed [8:0] p01_s = {1'b0, p01};
    wire signed [8:0] p10_s = {1'b0, p10};
    wire signed [8:0] p11_s = {1'b0, p11};

    wire signed [8:0] diff_top = p00_s - p01_s;
    wire signed [8:0] diff_bot = p10_s - p11_s;

    wire signed [17:0] h_top_full = diff_top * SCALE;
    wire signed [17:0] h_bot_full = diff_bot * SCALE;
    wire signed [17:0] h_top = h_top_full >>> 8;
    wire signed [17:0] h_bot = h_bot_full >>> 8;

    wire signed [18:0] h_sum = h_top + h_bot;
    wire signed [27:0] coeff_full = h_sum * SCALE;
    wire signed [15:0] coeff = coeff_full >>> 8;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state     <= IDLE;
            out_cnt   <= 6'd0;
            valid_out <= 1'b0;
            data_out  <= 16'sd0;
            out_row   <= 3'd0;
            out_col   <= 3'd0;
        end else begin
            valid_out <= 1'b0;

            case (state)
                IDLE: begin
                    if (valid_in) begin
                        mem[{row, col}] <= data_in;
                        if (row == 4'd15 && col == 4'd15) begin
                            state   <= OUTPUT;
                            out_cnt <= 6'd0;
                        end
                    end
                end

                OUTPUT: begin
                    valid_out <= 1'b1;
                    data_out  <= coeff;
                    out_row   <= r;
                    out_col   <= c;

                    if (out_cnt == 6'd63) begin
                        state   <= IDLE;
                        out_cnt <= 6'd0;
                    end else begin
                        out_cnt <= out_cnt + 6'd1;
                    end
                end

                default: begin
                    state   <= IDLE;
                    out_cnt <= 6'd0;
                end
            endcase
        end
    end

endmodule
