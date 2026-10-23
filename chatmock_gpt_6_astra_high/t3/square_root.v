module SQRT (
    input  wire [15:0] value,
    output reg  [7:0]  result
);

    reg [15:0] radicand;
    reg [17:0] remainder;
    reg [17:0] trial;
    reg [7:0]  root;
    integer i;

    always @* begin
        radicand = value;
        remainder = 18'd0;
        trial = 18'd0;
        root = 8'd0;

        for (i = 0; i < 8; i = i + 1) begin
            // Bring down the next pair of radicand bits.
            remainder = (remainder << 2) | {16'd0, radicand[15:14]};
            radicand = radicand << 2;

            // Trial divisor is four times the previous root plus one.
            trial = {8'd0, root, 2'b01};
            root = root << 1;

            if (remainder >= trial) begin
                remainder = remainder - trial;
                root[0] = 1'b1;
            end
        end

        result = root;
    end

endmodule
