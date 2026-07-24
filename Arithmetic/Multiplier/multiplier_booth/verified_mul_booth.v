module verified_mul_booth(
    input  [15:0] a,
    input  [15:0] b,
    output [31:0] result
);
    // radix-4 (modified) Booth, unsigned 16x16.
    // Extend multiplier with a leading 0 (unsigned) and an implicit 0 below LSB.
    reg  signed [39:0] acc;
    reg  signed [39:0] A;
    reg  signed [39:0] pp;
    reg  [18:0] mb;          // mb[0]=0, mb[j+1]=b[j], top zero-extended
    reg  [2:0]  code;
    integer i;
    always @* begin
        A   = $signed({{24{1'b0}}, a});        // multiplicand, zero-extended positive
        mb  = {2'b00, b, 1'b0};                // 19 bits
        acc = 40'sd0;
        for (i = 0; i < 9; i = i + 1) begin
            code = {mb[2*i+2], mb[2*i+1], mb[2*i]};
            case (code)
                3'b001, 3'b010: pp =  A;
                3'b011:         pp =  (A <<< 1);
                3'b100:         pp = -(A <<< 1);
                3'b101, 3'b110: pp = -A;
                default:        pp =  40'sd0;
            endcase
            acc = acc + (pp <<< (2*i));
        end
    end
    assign result = acc[31:0];
endmodule
