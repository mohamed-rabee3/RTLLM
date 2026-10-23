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
    reg [7:0] NEG_DIVISOR;
    reg [3:0] cnt;
    reg start_cnt;
    reg sign_reg;
    reg [7:0] dividend_reg;
    reg [7:0] divisor_reg;

    wire [8:0] sub = {1'b0, SR[15:8]} + {1'b0, NEG_DIVISOR};
    wire carry = sub[8];
    wire [7:0] R_new = carry ? sub[7:0] : SR[15:8];
    wire [7:0] Q_new = {SR[7:1], carry};

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            res_valid <= 1'b0;
            SR <= 16'b0;
            NEG_DIVISOR <= 8'b0;
            cnt <= 4'b0;
            start_cnt <= 1'b0;
            sign_reg <= 1'b0;
            dividend_reg <= 8'b0;
            divisor_reg <= 8'b0;
            result <= 16'b0;
        end else begin
            if (opn_valid && !res_valid) begin
                // Start operation
                sign_reg <= sign;
                dividend_reg <= dividend;
                divisor_reg <= divisor;
                SR <= {8'b0, (sign && dividend[7]) ? -dividend : dividend} << 1;
                NEG_DIVISOR <= -((sign && divisor[7]) ? -divisor : divisor);
                cnt <= 4'd1;
                start_cnt <= 1'b1;
                res_valid <= 1'b0;
            end else if (start_cnt) begin
                if (cnt[3]) begin
                    // Division complete (cnt == 8)
                    SR <= {R_new, Q_new};
                    cnt <= 4'd0;
                    start_cnt <= 1'b0;
                    res_valid <= 1'b1;

                    // Sign correction
                    if (sign_reg) begin
                        result <= {
                            (dividend_reg[7] ? -R_new : R_new),
                            ((dividend_reg[7] ^ divisor_reg[7]) ? -Q_new : Q_new)
                        };
                    end else begin
                        result <= {R_new, Q_new};
                    end
                end else begin
                    // Iteration
                    cnt <= cnt + 1'b1;
                    SR <= {R_new, Q_new} << 1;
                end
            end else if (res_valid) begin
                res_valid <= 1'b0;
            end
        end
    end

endmodule
