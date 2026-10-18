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
    reg        quotient_negative;
    reg        remainder_negative;

    wire [7:0] dividend_abs;
    wire [7:0] divisor_abs;
    wire [8:0] subtraction;
    wire       quotient_bit;
    wire [7:0] selected_remainder;
    wire [7:0] corrected_quotient;
    wire [7:0] corrected_remainder;

    assign dividend_abs = (sign && dividend[7])
                        ? (~dividend + 8'd1) : dividend;

    assign divisor_abs = (sign && divisor[7])
                       ? (~divisor + 8'd1) : divisor;

    // A clear sign bit indicates that the trial subtraction succeeded.
    assign subtraction = {1'b0, SR[15:8]} + NEG_DIVISOR;
    assign quotient_bit = ~subtraction[8];

    assign selected_remainder = quotient_bit
                              ? subtraction[7:0] : SR[15:8];

    assign corrected_quotient = quotient_negative
                              ? (~SR[7:0] + 8'd1) : SR[7:0];

    assign corrected_remainder = remainder_negative
                               ? (~SR[15:8] + 8'd1) : SR[15:8];

    assign result = {corrected_remainder, corrected_quotient};

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            SR                 <= 16'd0;
            NEG_DIVISOR        <= 9'd0;
            cnt                <= 4'd0;
            start_cnt          <= 1'b0;
            quotient_negative  <= 1'b0;
            remainder_negative <= 1'b0;
            res_valid          <= 1'b0;
        end else begin
            // Without a result-ready input, completion is a one-cycle pulse.
            res_valid <= 1'b0;

            if (start_cnt) begin
                if (cnt[3]) begin
                    // The last iteration does not shift the remainder.
                    SR        <= {selected_remainder,
                                  SR[6:0], quotient_bit};
                    cnt       <= 4'd0;
                    start_cnt <= 1'b0;
                    res_valid <= 1'b1;
                end else begin
                    SR <= {selected_remainder[6:0],
                           SR[7:0], quotient_bit};
                    cnt <= cnt + 4'd1;
                end
            end else if (opn_valid && !res_valid) begin
                SR                 <= {7'd0, dividend_abs, 1'b0};
                NEG_DIVISOR        <= (~{1'b0, divisor_abs}) + 9'd1;
                cnt                <= 4'd1;
                start_cnt          <= 1'b1;
                quotient_negative  <= sign && (dividend[7] ^ divisor[7]);
                remainder_negative <= sign && dividend[7];
            end
        end
    end

endmodule
