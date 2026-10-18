module SQRT (
    input  [15:0] value,
    output reg [7:0] result
);

    integer i;
    reg [15:0] v;
    reg [17:0] remainder;
    reg [8:0]  root;
    reg [17:0] trial;

    always @* begin
        v = value;
        remainder = 18'd0;
        root = 9'd0;
        trial = 18'd0;

        for (i = 0; i < 8; i = i + 1) begin
            remainder = (remainder << 2) | v[15:14];
            v = v << 2;

            root = root << 1;
            trial = (root << 1) | 18'd1;

            if (remainder >= trial) begin
                remainder = remainder - trial;
                root = root + 1'b1;
            end
        end

        result = root[7:0];
    end

endmodule
