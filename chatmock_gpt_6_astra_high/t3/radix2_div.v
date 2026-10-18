module radix2_div (
    input  wire        clk,
    input  wire        rst,
    input  wire        sign,
    input  wire [7:0]  dividend,
    input  wire [7:0]  divisor,
    input  wire        opn_valid,
    output reg         res_valid,
    output reg  [15:0] result
);

    reg [15:0] SR;
    reg [8:0]  NEG_DIVISOR;
    reg [3:0]  cnt;
    reg        start_cnt;

    reg [7:0] dividend_saved;
    reg [7:0] divisor_saved;
    reg       sign_saved;

    wire [7:0] dividend_abs;
    wire [7:0] divisor_abs;
    wire [8:0] subtraction;
    wire [7:0] selected_remainder;
    wire [7:0] final_quotient;
    wire [7:0] corrected_quotient;
    wire [7:0] corrected_remainder;

    assign dividend_abs = (sign && dividend[7])
                        ? (~dividend + 8'd1)
                        : dividend;

    assign divisor_abs = (sign && divisor[7])
                       ? (~divisor + 8'd1)
                       : divisor;

    // The ninth bit indicates that the unsigned subtraction succeeded.
    assign subtraction = {1'b0, SR[15:8]} + NEG_DIVISOR;

    assign selected_remainder = subtraction[8]
                              ? subtraction[7:0]
                              : SR[15:8];

    assign final_quotient = {SR[6:0], subtraction[8]};

    assign corrected_quotient =
        (sign_saved && (dividend_saved[7] ^ divisor_saved[7]))
        ? (~final_quotient + 8'd1)
        : final_quotient;

    assign corrected_remainder =
        (sign_saved && dividend_saved[7])
        ? (~selected_remainder + 8'd1)
        : selected_remainder;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            SR             <= 16'd0;
            NEG_DIVISOR    <= 9'd0;
            cnt            <= 4'd0;
            start_cnt      <= 1'b0;
            dividend_saved <= 8'd0;
            divisor_saved  <= 8'd0;
            sign_saved     <= 1'b0;
            res_valid      <= 1'b0;
            result         <= 16'd0;
        end else begin
            // With no result-ready input, completion is a one-cycle pulse.
            res_valid <= 1'b0;

            if (start_cnt) begin
                if (cnt[3]) begin
                    cnt       <= 4'd0;
                    start_cnt <= 1'b0;
                    SR        <= {selected_remainder, final_quotient};
                    result    <= {corrected_remainder, corrected_quotient};
                    res_valid <= 1'b1;
                end else begin
                    cnt <= cnt + 4'd1;
                    SR  <= {selected_remainder[6:0],
                            SR[7:0], subtraction[8]};
                end
            end else if (opn_valid && !res_valid) begin
                dividend_saved <= dividend;
                divisor_saved  <= divisor;
                sign_saved     <= sign;

                SR          <= {7'd0, dividend_abs, 1'b0};
                NEG_DIVISOR <= 9'd256 - {1'b0, divisor_abs};
                cnt         <= 4'd1;
                start_cnt   <= 1'b1;
            end
        end
    end

endmodule
