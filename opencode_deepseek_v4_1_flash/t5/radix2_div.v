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
    reg [7:0] V;
    reg [7:0] NEG_DIVISOR;
    reg [3:0] cnt;
    reg busy;
    reg sign_latched;
    reg sign_q;
    reg sign_r;

    wire [15:0] SR_shift = SR << 1;
    wire [8:0] sum = {1'b0, SR_shift[15:8]} + {1'b0, NEG_DIVISOR};
    wire carry = sum[8];

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            SR <= 16'b0;
            V <= 8'b0;
            NEG_DIVISOR <= 8'b0;
            cnt <= 4'b0;
            busy <= 1'b0;
            res_valid <= 1'b0;
            result <= 16'b0;
            sign_latched <= 1'b0;
            sign_q <= 1'b0;
            sign_r <= 1'b0;
        end else begin
            if (opn_valid && !busy) begin
                // Start new operation
                sign_latched <= sign;
                res_valid <= 1'b0;
                cnt <= 4'd8;
                busy <= 1'b1;

                if (sign) begin
                    // Signed division
                    if (dividend[7])
                        SR <= {8'b0, ~dividend + 1'b1};
                    else
                        SR <= {8'b0, dividend};

                    if (divisor[7]) begin
                        V <= ~divisor + 1'b1;
                        NEG_DIVISOR <= divisor;
                    end else begin
                        V <= divisor;
                        NEG_DIVISOR <= ~divisor + 1'b1;
                    end

                    sign_q <= dividend[7] ^ divisor[7];
                    sign_r <= dividend[7];
                end else begin
                    // Unsigned division
                    SR <= {8'b0, dividend};
                    V <= divisor;
                    NEG_DIVISOR <= ~divisor + 1'b1;
                    sign_q <= 1'b0;
                    sign_r <= 1'b0;
                end
            end else if (busy) begin
                if (cnt == 4'd1) begin
                    // Last iteration
                    if (carry) begin
                        if (sign_latched) begin
                            if (sign_q) result[7:0] <= -({SR[6:0], 1'b1});
                            else result[7:0] <= {SR[6:0], 1'b1};
                            if (sign_r) result[15:8] <= -sum[7:0];
                            else result[15:8] <= sum[7:0];
                        end else begin
                            result[7:0] <= {SR[6:0], 1'b1};
                            result[15:8] <= sum[7:0];
                        end
                    end else begin
                        if (sign_latched) begin
                            if (sign_q) result[7:0] <= -SR_shift[7:0];
                            else result[7:0] <= SR_shift[7:0];
                            if (sign_r) result[15:8] <= -SR_shift[15:8];
                            else result[15:8] <= SR_shift[15:8];
                        end else begin
                            result[7:0] <= SR_shift[7:0];
                            result[15:8] <= SR_shift[15:8];
                        end
                    end
                    res_valid <= 1'b1;
                    busy <= 1'b0;
                    cnt <= 4'b0;
                end else begin
                    // Normal iteration
                    if (carry) begin
                        SR <= {sum[7:0], SR[6:0], 1'b1};
                    end else begin
                        SR <= SR_shift;
                    end
                    cnt <= cnt - 1'b1;
                end
            end else begin
                // Idle: keep res_valid until next start
            end
        end
    end

endmodule
