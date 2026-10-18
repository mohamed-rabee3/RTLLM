module radix2_div (
    input clk,
    input rst,
    input sign,
    input [7:0] dividend,
    input [7:0] divisor,
    input opn_valid,
    output reg res_valid,
    output reg [15:0] result
);

    reg [15:0] SR;
    reg [7:0] NEG_DIVISOR;
    reg [3:0] cnt;
    reg start_cnt;
    reg [7:0] dividend_r;
    reg [7:0] divisor_r;
    reg sign_r;

    wire [7:0] dividend_abs = sign ? (dividend[7] ? -dividend : dividend) : dividend;
    wire [7:0] divisor_abs  = sign ? (divisor[7] ? -divisor : divisor) : divisor;

    wire [7:0] R_cur = SR[15:8];
    wire [8:0] sum = {1'b0, R_cur} + {1'b0, NEG_DIVISOR};
    wire carry = sum[8];
    wire [7:0] selected_R = carry ? sum[7:0] : R_cur;
    wire [7:0] Q_after = {SR[7:1], carry};
    wire [15:0] shifted_SR = {selected_R, Q_after} << 1;
    wire [15:0] final_SR = {selected_R, Q_after};

    wire [7:0] final_remainder = (sign_r && dividend_r[7]) ? -selected_R : selected_R;
    wire [7:0] final_quotient  = (sign_r && (dividend_r[7] ^ divisor_r[7])) ? -Q_after : Q_after;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            SR <= 16'b0;
            NEG_DIVISOR <= 8'b0;
            cnt <= 4'b0;
            start_cnt <= 1'b0;
            dividend_r <= 8'b0;
            divisor_r <= 8'b0;
            sign_r <= 1'b0;
            res_valid <= 1'b0;
            result <= 16'b0;
        end else begin
            if (opn_valid && !res_valid && !start_cnt) begin
                dividend_r <= dividend;
                divisor_r <= divisor;
                sign_r <= sign;
                SR <= {8'b0, dividend_abs} << 1;
                NEG_DIVISOR <= -divisor_abs;
                cnt <= 4'd1;
                start_cnt <= 1'b1;
                res_valid <= 1'b0;
            end else if (start_cnt) begin
                if (cnt == 4'd8) begin
                    cnt <= 4'd0;
                    start_cnt <= 1'b0;
                    SR <= final_SR;
                    result <= {final_remainder, final_quotient};
                    res_valid <= 1'b1;
                end else begin
                    cnt <= cnt + 1'b1;
                    SR <= shifted_SR;
                    res_valid <= 1'b0;
                end
            end else if (res_valid) begin
                res_valid <= 1'b0;
            end
        end
    end

endmodule
