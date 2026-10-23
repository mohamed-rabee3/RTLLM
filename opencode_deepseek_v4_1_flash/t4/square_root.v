module SQRT(
    input  [15:0] value,
    output reg [7:0] result
);

    integer i;
    reg [17:0] remainder;
    reg [7:0]  root;

    always @* begin
        remainder = 18'd0;
        root      = 8'd0;

        for (i = 7; i >= 0; i = i - 1) begin
            remainder = (remainder << 2) | value[2*i +: 2];

            if (remainder >= {root, 2'b01}) begin
                remainder = remainder - {root, 2'b01};
                root      = (root << 1) | 8'd1;
            end
            else begin
                root      = root << 1;
            end
        end

        result = root;
    end

endmodule
