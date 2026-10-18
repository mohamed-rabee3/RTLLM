module haar_wavelet_lh_only(
    input clk,
    input rst_n,
    input valid_in,
    input [3:0] row,
    input [3:0] col,
    input [7:0] data_in,
    output [15:0] data_out,
    output valid_out,
    output [2:0] out_row,
    output [2:0] out_col
);

    reg [7:0] image [0:255];
    reg state;
    localparam IDLE = 1'b0;
    localparam OUTPUT = 1'b1;

    reg [2:0] out_r;
    reg [2:0] out_c;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            out_r <= 3'd0;
            out_c <= 3'd0;
        end else begin
            case (state)
                IDLE: begin
                    if (valid_in) begin
                        image[{row, col}] <= data_in;
                        if (row == 4'd15 && col == 4'd15) begin
                            state <= OUTPUT;
                            out_r <= 3'd0;
                            out_c <= 3'd0;
                        end
                    end
                end
                OUTPUT: begin
                    if (out_r == 3'd7 && out_c == 3'd7) begin
                        state <= IDLE;
                        out_r <= 3'd0;
                        out_c <= 3'd0;
                    end else if (out_c == 3'd7) begin
                        out_c <= 3'd0;
                        out_r <= out_r + 1'b1;
                    end else begin
                        out_c <= out_c + 1'b1;
                    end
                end
                default: state <= IDLE;
            endcase
        end
    end

    wire [3:0] r0 = {out_r, 1'b0};
    wire [3:0] r1 = r0 + 4'd1;
    wire [3:0] c0 = {out_c, 1'b0};
    wire [3:0] c1 = c0 + 4'd1;

    wire [7:0] p00 = image[{r0, c0}];
    wire [7:0] p01 = image[{r0, c1}];
    wire [7:0] p10 = image[{r1, c0}];
    wire [7:0] p11 = image[{r1, c1}];

    wire signed [8:0] diff_top = $signed({1'b0, p00}) - $signed({1'b0, p01});
    wire signed [8:0] diff_bot = $signed({1'b0, p10}) - $signed({1'b0, p11});

    wire signed [31:0] top_hp_mul = diff_top * 9'sd181;
    wire signed [31:0] bot_hp_mul = diff_bot * 9'sd181;
    wire signed [31:0] top_hp = top_hp_mul >>> 8;
    wire signed [31:0] bot_hp = bot_hp_mul >>> 8;

    wire signed [31:0] sum_hp = top_hp + bot_hp;
    wire signed [31:0] lh_mul = sum_hp * 9'sd181;
    wire signed [31:0] lh = lh_mul >>> 8;

    assign data_out = lh[15:0];
    assign valid_out = (state == OUTPUT);
    assign out_row = out_r;
    assign out_col = out_c;

endmodule
