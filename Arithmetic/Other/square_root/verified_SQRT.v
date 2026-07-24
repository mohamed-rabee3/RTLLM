module verified_SQRT(
    input  [15:0] value,
    output [7:0]  result
);
    reg [7:0]  res;
    reg [17:0] rem;   // remainder, needs a couple extra bits of headroom
    reg [17:0] trial;
    integer i;
    always @* begin
        res = 8'd0;
        rem = 18'd0;
        for (i = 7; i >= 0; i = i - 1) begin
            // bring down the next two bits of value
            rem   = (rem << 2) | ((value >> (i*2)) & 2'b11);
            trial = ({res, 2'b01});          // (res<<2) | 1
            if (rem >= trial) begin
                rem = rem - trial;
                res = (res << 1) | 1'b1;
            end else begin
                res = (res << 1);
            end
        end
    end
    assign result = res;
endmodule
