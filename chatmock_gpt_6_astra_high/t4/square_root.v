module SQRT (
    input  wire [15:0] value,
    output wire [7:0]  result
);

    reg [7:0]  partial_root;
    reg [17:0] remainder;
    reg [17:0] trial;
    integer i;

    always @* begin
        partial_root = 8'd0;
        remainder    = 18'd0;
        trial        = 18'd0;

        for (i = 7; i >= 0; i = i - 1) begin
            // Bring down the next pair of radicand bits.
            remainder = {remainder[15:0], value[2*i +: 2]};

            // Trial divisor is four times the previous root plus one.
            trial = {8'd0, partial_root, 2'b01};

            if (remainder >= trial) begin
                remainder    = remainder - trial;
                partial_root = {partial_root[6:0], 1'b1};
            end else begin
                partial_root = {partial_root[6:0], 1'b0};
            end
        end
    end

    assign result = partial_root;

endmodule
