module mul_booth (
    input  wire [15:0] a,
    input  wire [15:0] b,
    output reg  [31:0] result
);

    reg signed [33:0] a_ext;
    reg signed [33:0] partial_product;
    reg signed [33:0] accumulator;
    reg        [18:0] b_ext;
    integer i;

    always @* begin
        a_ext           = $signed({18'b0, a});
        b_ext           = {2'b00, b, 1'b0};
        accumulator     = 34'sd0;
        partial_product = 34'sd0;

        // Eight radix-4 Booth groups cover the original multiplier bits.
        for (i = 0; i < 8; i = i + 1) begin
            case (b_ext[2*i +: 3])
                3'b000, 3'b111: partial_product = 34'sd0;
                3'b001, 3'b010: partial_product = a_ext;
                3'b011:         partial_product = a_ext <<< 1;
                3'b100:         partial_product = -(a_ext <<< 1);
                3'b101, 3'b110: partial_product = -a_ext;
                default:        partial_product = 34'sd0;
            endcase

            accumulator = accumulator + (partial_product <<< (2*i));
        end

        // The zero-extension Booth group is {0, 0, b[15]}.
        // Its contribution corrects the eight-group signed interpretation
        // of b, ensuring an unsigned product.
        if (b_ext[16])
            accumulator = accumulator + (a_ext <<< 16);

        result = accumulator[31:0];
    end

endmodule
