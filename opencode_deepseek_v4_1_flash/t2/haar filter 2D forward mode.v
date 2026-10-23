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
    localparam IDLE = 1'b0;
    localparam OUT  = 1'b1;

    reg [6:0] cnt;
    reg [2:0] pos_row, pos_col;

    reg [3:0] r0, r1, c0, c1;
    reg [7:0] p00, p01, p10, p11;
    reg signed [8:0] diff0, diff1;
    reg signed [15:0] hp0, hp1, sum_hp;
    reg signed [15:0] calc_data;

    always @* begin
        r0 = {pos_row, 1'b0};
        r1 = r0 + 4'd1;
        c0 = {pos_col, 1'b0};
        c1 = c0 + 4'd1;

        p00 = mem[{r0, c0}];
        p01 = mem[{r0, c1}];
        p10 = mem[{r1, c0}];
        p11 = mem[{r1, c1}];

        diff0 = {1'b0, p00} - {1'b0, p01};
        diff1 = {1'b0, p10} - {1'b0, p11};

        hp0 = (diff0 * 17'sd181) >>> 8;
        hp1 = (diff1 * 17'sd181) >>> 8;
        sum_hp = hp0 + hp1;
        calc_data = (sum_hp * 17'sd181) >>> 8;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            cnt <= 7'd0;
            pos_row <= 3'd0;
            pos_col <= 3'd0;
            data_out <= 16'sd0;
            valid_out <= 1'b0;
            out_row <= 3'd0;
            out_col <= 3'd0;
        end else begin
            case (state)
                IDLE: begin
                    valid_out <= 1'b0;
                    if (valid_in) begin
                        mem[{row, col}] <= data_in;
                        if (row == 4'd15 && col == 4'd15) begin
                            state <= OUT;
                            cnt <= 7'd0;
                            pos_row <= 3'd0;
                            pos_col <= 3'd0;
                        end
                    end
                end
                OUT: begin
                    if (cnt < 7'd64) begin
                        data_out <= calc_data;
                        out_row <= pos_row;
                        out_col <= pos_col;
                        valid_out <= 1'b1;
                        cnt <= cnt + 7'd1;

                        if (pos_row == 3'd7 && pos_col == 3'd7) begin
                            // last position reached; no need to advance
                        end else if (pos_col == 3'd7) begin
                            pos_col <= 3'd0;
                            pos_row <= pos_row + 3'd1;
                        end else begin
                            pos_col <= pos_col + 3'd1;
                        end
                    end else begin
                        valid_out <= 1'b0;
                        state <= IDLE;
                    end
                end
                default: state <= IDLE;
            endcase
        end
    end

endmodule
