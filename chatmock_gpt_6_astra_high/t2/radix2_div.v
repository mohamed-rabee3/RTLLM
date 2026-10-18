module radix2_div (
    input  wire        clk,
    input  wire        rst,
    input  wire        sign,
    input  wire [7:0]  dividend,
    input  wire [7:0]  divisor,
    input  wire        opn_valid,
    output reg         res_valid,
    output wire [15:0] result
);

    reg [15:0] SR;
    reg [8:0]  NEG_DIVISOR;
    reg [3:0]  cnt;
    reg        start_cnt;

    reg [7:0]  saved_dividend;
    reg [7:0]  saved_divisor;
    reg        saved_sign;

    wire [7:0] dividend_abs;
    wire [7:0] divisor_abs;
    wire [8:0] subtraction;
    wire       quotient_bit;
    wire [7:0] next_remainder;
    wire       negate_quotient;
    wire       negate_remainder;
    wire [7:0] quotient;
    wire [7:0] remainder;

    assign dividend_abs = (sign && dividend[7])
                        ? (~dividend + 8'd1) : dividend;
    assign divisor_abs  = (sign && divisor[7])
                        ? (~divisor + 8'd1) : divisor;

    // The ninth bit is the no-borrow indication.
    assign subtraction   = {1'b0, SR[15:8]} + NEG_DIVISOR;
    assign quotient_bit  = subtraction[8];
    assign next_remainder = quotient_bit
                          ? subtraction[7:0] : SR[15:8];

    assign negate_quotient = saved_sign
                           && (saved_dividend[7] ^ saved_divisor[7]);
    assign negate_remainder = saved_sign && saved_dividend[7];

    assign quotient  = negate_quotient
                     ? (~SR[7:0] + 8'd1) : SR[7:0];
    assign remainder = negate_remainder
                     ? (~SR[15:8] + 8'd1) : SR[15:8];

    assign result = {remainder, quotient};

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            SR             <= 16'd0;
            NEG_DIVISOR    <= 9'd0;
            cnt            <= 4'd0;
            start_cnt      <= 1'b0;
            saved_dividend <= 8'd0;
            saved_divisor  <= 8'd0;
            saved_sign     <= 1'b0;
            res_valid      <= 1'b0;
        end else begin
            // Retain a completed result until the request is withdrawn.
            if (!opn_valid)
                res_valid <= 1'b0;

            if (start_cnt) begin
                if (cnt[3]) begin
                    // The final iteration does not shift the remainder.
                    SR        <= {next_remainder, SR[7:1], quotient_bit};
                    cnt       <= 4'd0;
                    start_cnt <= 1'b0;
                    res_valid <= 1'b1;
                end else begin
                    SR  <= {next_remainder[6:0], SR[7:0], quotient_bit};
                    cnt <= cnt + 4'd1;
                end
            end else if (opn_valid && !res_valid) begin
                saved_dividend <= dividend;
                saved_divisor  <= divisor;
                saved_sign     <= sign;

                SR          <= {7'd0, dividend_abs, 1'b0};
                NEG_DIVISOR <= {1'b0, ~divisor_abs} + 9'd1;
                cnt         <= 4'd1;
                start_cnt   <= 1'b1;
                res_valid   <= 1'b0;
            end
        end
    end

endmodule
