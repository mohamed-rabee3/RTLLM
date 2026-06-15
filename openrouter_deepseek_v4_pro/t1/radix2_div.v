module radix2_div (
    input           clk,
    input           rst,
    input           sign,
    input   [7:0]   dividend,
    input   [7:0]   divisor,
    input           opn_valid,
    output reg      res_valid,
    output reg [15:0] result
);

    // Internal registers
    reg [8:0]   SR;                 // 9-bit shift register
    reg [8:0]   neg_div;            // negated absolute divisor (9 bits)
    reg [3:0]   cnt;                // iteration counter (1..8)
    reg         start_cnt;          // division active flag
    reg         dividend_sign;      // sign of original dividend (1 = negative)
    reg         div_result_sign;    // sign of final quotient (dividend_sign ^ divisor_sign)
    reg [7:0]   dividend_abs;
    reg [7:0]   divisor_abs;

    // Combinational logic for subtraction step
    wire [8:0]  sub_9;              // 9-bit sum: SR + NEG_DIVISOR
    wire        cout;               // carry-out of the addition
    wire [8:0]  selected;           // mux output: sub if cout=1, else SR

    assign sub_9 = SR + neg_div;
    assign cout  = sub_9[8];
    assign selected = cout ? sub_9 : SR;

    // Synchronous state machine
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            SR             <= 9'd0;
            neg_div        <= 9'd0;
            cnt            <= 4'd0;
            start_cnt      <= 1'b0;
            res_valid      <= 1'b0;
            result         <= 16'd0;
            dividend_abs   <= 8'd0;
            divisor_abs    <= 8'd0;
            dividend_sign  <= 1'b0;
            div_result_sign <= 1'b0;
        end else begin
            // Operation start: latching inputs
            if (opn_valid && !res_valid) begin
                // Compute absolute values
                if (sign && dividend[7])
                    dividend_abs <= ~dividend + 1'b1;
                else
                    dividend_abs <= dividend;

                if (sign && divisor[7])
                    divisor_abs <= ~divisor + 1'b1;
                else
                    divisor_abs <= divisor;

                // neg_div = -{1'b0, divisor_abs}  (9-bit two's complement)
                neg_div <= {1'b0, ~divisor_abs} + 9'd1;

                // SR = absolute dividend shifted left by one bit
                SR <= {dividend_abs, 1'b0};

                // Store sign information
                dividend_sign  <= (sign && dividend[7]);
                div_result_sign <= (sign && (dividend[7] ^ divisor[7]));

                // Initialize counter and start flag
                cnt       <= 4'd1;
                start_cnt <= 1'b1;
                res_valid <= 1'b0;
            end
            // Division process
            else if (start_cnt) begin
                // If counter reached 8 (MSB set) → division complete
                if (cnt[3]) begin
                    cnt       <= 4'd0;
                    start_cnt <= 1'b0;

                    // Extract unsigned remainder and quotient from SR
                    // (adjustable according to the exact algorithm)
                    reg [7:0] rem_uns, quot_uns;
                    rem_uns  = SR[8:1];
                    quot_uns = SR[7:0];

                    // Apply sign for signed division
                    result[7:0]   <= div_result_sign ? (~quot_uns + 1'b1) : quot_uns;
                    result[15:8]  <= dividend_sign  ? (~rem_uns + 1'b1) : rem_uns;

                    // Flag that result is ready
                    res_valid <= 1'b1;
                end
                // Otherwise, perform one iteration
                else begin
                    // Update SR: shift left selected value and insert carry-out
                    SR <= {selected[7:0], cout};
                    cnt <= cnt + 4'd1;
                end
            end
        end
    end

endmodule