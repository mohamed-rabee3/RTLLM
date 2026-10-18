module SQRT (
    input  wire [15:0] value,
    output reg  [7:0]  result
);

    reg [17:0] remainder;
    reg [17:0] trial;
    reg [7:0]  partial_root;
    integer i;

    always @* begin
        remainder   = 18'd0;
        trial       = 18'd0;
        partial_root = 8'd0;

        for (i = 7; i >= 0; i = i - 1) begin
            // Bring down the next pair of radicand bits.
            remainder = (remainder << 2)
                      | {16'd0, value[2*i +: 2]};

            // Trial divisor is four times the current root plus one.
            trial = ({10'd0, partial_root} << 2) | 18'd1;

            partial_root = partial_root << 1;
            if (remainder >= trial) begin
                remainder = remainder - trial;
                partial_root[0] = 1'b1;
            end
        end

        result = partial_root;
    end

endmodule
