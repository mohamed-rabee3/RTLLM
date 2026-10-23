module radix2_div(
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
    reg [8:0] NEG_DIVISOR;
    reg [3:0] cnt;
    reg start_cnt;
    reg [7:0] divisor_abs;
    reg [7:0] dividend_reg;
    reg [7:0] divisor_reg;
    reg sign_reg;

    wire [15:0] SR_shift = SR << 1;
    wire [7:0] rem_shift = SR_shift[15:8];
    wire [8:0] sub_result = {1'b0, rem_shift} + NEG_DIVISOR;
    wire sub_en = ~sub_result[8];
    wire [7:0] rem_sub = sub_result[7:0];

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            SR <= 16'd0;
            NEG_DIVISOR <= 9'd0;
            cnt <= 4'd0;
            start_cnt <= 1'b0;
            res_valid <= 1'b0;
            result <= 16'd0;
            divisor_abs <= 8'd0;
            dividend_reg <= 8'd0;
            divisor_reg <= 8'd0;
            sign_reg <= 1'b0;
        end else begin
            if (opn_valid && !start_cnt) begin
                sign_reg <= sign;
                dividend_reg <= dividend;
                divisor_reg <= divisor;
                if (sign) begin
                    divisor_abs <= (divisor[7] ? -divisor : divisor);
                    SR <= {8'b0, (dividend[7] ? -dividend : dividend)};
                    NEG_DIVISOR <= ~{1'b0, (divisor[7] ? -divisor : divisor)} + 1'b1;
                end else begin
                    divisor_abs <= divisor;
                    SR <= {8'b0, dividend};
                    NEG_DIVISOR <= ~{1'b0, divisor} + 1'b1;
                end
                cnt <= 4'd0;
                start_cnt <= 1'b1;
                res_valid <= 1'b0;
            end else if (start_cnt) begin
                if (cnt < 8) begin
                    if (sub_en) begin
                        SR <= {rem_sub, SR_shift[7:1], 1'b1};
                    end else begin
                        SR <= {rem_shift, SR_shift[7:1], 1'b0};
                    end
                    cnt <= cnt + 1'b1;
                end else begin
                    if (sign_reg) begin
                        if (dividend_reg[7] ^ divisor_reg[7]) begin
                            result[7:0] <= -SR[7:0];
                        end else begin
                            result[7:0] <= SR[7:0];
                        end
                        if (dividend_reg[7]) begin
                            result[15:8] <= -SR[15:8];
                        end else begin
                            result[15:8] <= SR[15:8];
                        end
                    end else begin
                        result[7:0] <= SR[7:0];
                        result[15:8] <= SR[15:8];
                    end
                    res_valid <= 1'b1;
                    start_cnt <= 1'b0;
                    cnt <= 4'd0;
                end
            end
        end
    end

endmodule
