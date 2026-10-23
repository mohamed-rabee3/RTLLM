module mul_booth (
    input  wire [15:0] a,
    input  wire [15:0] b,
    output reg  [31:0] result
);

    reg signed [33:0] a_ext;
    reg signed [33:0] partial;
    reg signed [33:0] accumulator;
    reg        [17:0] b_ext;
    integer i;

    always @* begin
        a_ext       = $signed({18'b0, a});
        b_ext       = {1'b0, b, 1'b0};
        partial     = 34'sd0;
        accumulator = 34'sd0;

        // Eight radix-4 Booth partial products.
        for (i = 0; i < 8; i = i + 1) begin
            case (b_ext[2*i +: 3])
                3'b000, 3'b111: partial = 34'sd0;
                3'b001, 3'b010: partial = a_ext;
                3'b011:         partial = a_ext <<< 1;
                3'b100:         partial = -(a_ext <<< 1);
                3'b101, 3'b110: partial = -a_ext;
                default:        partial = 34'sd0;
            endcase

            accumulator = accumulator + (partial <<< (2*i));
        end

        // Correct the eight-group signed recoding for unsigned b.
        // This is the contribution of the leading zero-extension group.
        if (b[15])
            accumulator = accumulator + (a_ext <<< 16);

        result = accumulator[31:0];
    end

endmodule
