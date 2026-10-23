module SQRT(
    input [15:0] value,
    output reg [7:0] result
);

    integer i;
    reg [7:0] root;
    reg [17:0] rem;
    reg [17:0] trial;

    always @(*) begin
        root = 8'd0;
        rem = 18'd0;
        trial = 18'd0;

        for (i = 7; i >= 0; i = i - 1) begin
            rem = (rem << 2) | ((value >> (2 * i)) & 16'h0003);
            trial = {8'd0, root, 2'b01};

            if (rem >= trial) begin
                rem = rem - trial;
                root = (root << 1) | 8'd1;
            end else begin
                root = (root << 1);
            end
        end

        result = root;
    end

endmodule
