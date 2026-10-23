module SQRT (
    input  wire [15:0] value,
    output reg  [7:0]  result
);

    reg [17:0] remainder;
    reg [17:0] trial;
    reg [7:0]  root;
    reg [15:0] radicand;
    integer i;

    always @* begin
        remainder = 18'd0;
        trial     = 18'd0;
        root      = 8'd0;
        radicand  = value;

        for (i = 0; i < 8; i = i + 1) begin
            // Bring down the next pair of radicand bits.
            remainder = (remainder << 2) |
                        {16'd0, radicand[15:14]};
            radicand = radicand << 2;

            // Trial divisor is four times the current root plus one.
            trial = ({10'd0, root} << 2) | 18'd1;
            root = root << 1;

            if (remainder >= trial) begin
                remainder = remainder - trial;
                root = root | 8'd1;
            end
        end

        result = root;
    end

endmodule
