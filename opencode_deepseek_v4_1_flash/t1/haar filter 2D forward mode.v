module haar_wavelet_lh_only (
    input clk,
    input rst_n,
    input valid_in,
    input [3:0] row,
    input [3:0] col,
    input [7:0] data_in,
    output signed [15:0] data_out,
    output reg valid_out,
    output reg [2:0] out_row,
    output reg [2:0] out_col
);

    reg [7:0] mem [0:255];

    localparam IDLE = 1'b0;
    localparam OUT  = 1'b1;

    reg state;
    reg [2:0] r_cnt;
    reg [2:0] c_cnt;
    reg signed [15:0] data_out_reg;

    assign data_out = data_out_reg;

    function [15:0] calc_lh;
        input [2:0] r;
        input [2:0] c;
        reg [3:0] row0, row1, col0, col1;
        reg [7:0] p00, p01, p10, p11;
        reg signed [8:0] d0, d1;
        reg signed [17:0] m0, m1, m2;
        reg signed [9:0] s0, s1;
        reg signed [10:0] sum;
        begin
            row0 = {r, 1'b0};
            row1 = row0 + 4'd1;
            col0 = {c, 1'b0};
            col1 = col0 + 4'd1;

            p00 = mem[{row0, col0}];
            p01 = mem[{row0, col1}];
            p10 = mem[{row1, col0}];
            p11 = mem[{row1, col1}];

            d0 = $signed({1'b0, p00}) - $signed({1'b0, p01});
            d1 = $signed({1'b0, p10}) - $signed({1'b0, p11});

            m0 = d0 * 18'sd181;
            m1 = d1 * 18'sd181;
            s0 = m0 >>> 8;
            s1 = m1 >>> 8;

            sum = s0 + s1;
            m2 = sum * 18'sd181;
            calc_lh = m2 >>> 8;
        end
    endfunction

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            r_cnt <= 3'd0;
            c_cnt <= 3'd0;
            valid_out <= 1'b0;
            data_out_reg <= 16'sd0;
            out_row <= 3'd0;
            out_col <= 3'd0;
        end else begin
            if (state == IDLE) begin
                valid_out <= 1'b0;
                if (valid_in) begin
                    mem[{row, col}] <= data_in;
                    if (row == 4'd15 && col == 4'd15) begin
                        state <= OUT;
                        r_cnt <= 3'd0;
                        c_cnt <= 3'd0;
                    end
                end
            end else begin
                valid_out <= 1'b1;
                out_row <= r_cnt;
                out_col <= c_cnt;
                data_out_reg <= calc_lh(r_cnt, c_cnt);

                if (r_cnt == 3'd7 && c_cnt == 3'd7) begin
                    state <= IDLE;
                    r_cnt <= 3'd0;
                    c_cnt <= 3'd0;
                end else if (c_cnt == 3'd7) begin
                    c_cnt <= 3'd0;
                    r_cnt <= r_cnt + 3'd1;
                end else begin
                    c_cnt <= c_cnt + 3'd1;
                end
            end
        end
    end

endmodule
