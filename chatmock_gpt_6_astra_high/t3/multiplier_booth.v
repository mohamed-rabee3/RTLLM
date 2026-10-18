module mul_booth (
    input  wire [15:0] a,
    input  wire [15:0] b,
    output wire [31:0] result
);

    reg        [17:0] multiplier_ext;
    reg signed [33:0] multiplicand_ext;
    reg signed [33:0] partial_product;
    reg signed [33:0] accumulated_sum;
    integer i;

    always @* begin
        multiplicand_ext = $signed({18'b0, a});
        multiplier_ext  = {1'b0, b, 1'b0};
        partial_product = 34'sd0;
        accumulated_sum = 34'sd0;

        // Eight overlapping radix-4 Booth groups.
        for (i = 0; i < 8; i = i + 1) begin
            case (multiplier_ext[2*i +: 3])
                3'b000, 3'b111:
                    partial_product = 34'sd0;
                3'b001, 3'b010:
                    partial_product = multiplicand_ext;
                3'b011:
                    partial_product = multiplicand_ext <<< 1;
                3'b100:
                    partial_product = -(multiplicand_ext <<< 1);
                3'b101, 3'b110:
                    partial_product = -multiplicand_ext;
                default:
                    partial_product = 34'sd0;
            endcase

            accumulated_sum =
                accumulated_sum + (partial_product <<< (2*i));
        end

        // Correct the sign weight of bit 15 for an unsigned multiplier.
        // This is the contribution of the leading zero-extended Booth group.
        if (multiplier_ext[16])
            accumulated_sum =
                accumulated_sum + (multiplicand_ext <<< 16);
    end

    assign result = accumulated_sum[31:0];

endmodule
