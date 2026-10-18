module SQRT(
    input [15:0] value,
    output reg [7:0] result
);

    integer i;
    reg [9:0] rem;
    reg [9:0] trial;
    reg [7:0] root;
    reg [15:0] shifted_value;
    reg [1:0] pair;

    always @* begin
        rem = 10'd0;
        root = 8'd0;
        shifted_value = value;

        for (i = 0; i < 8; i = i + 1) begin
            pair = shifted_value[15:14];
            shifted_value = shifted_value << 2;

            rem = (rem << 2) | {8'b0, pair};
            trial = {root, 2'b00} | 10'd1;

            if (rem >= trial) begin
                rem = rem - trial;
                root = (root << 1) | 8'd1;
            end else begin
                root = root << 1;
            end
        end

        result = root;
    end

endmodule
