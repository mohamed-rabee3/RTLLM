module mul_booth(
    input [15:0] a,
    input [15:0] b,
    output reg [31:0] result
);

    reg signed [33:0] acc;
    reg signed [33:0] A_ext;
    reg signed [33:0] pp;
    reg [16:0] b_ext;
    reg [2:0] code;
    integer i;

    always @* begin
        acc = 34'sd0;
        A_ext = {18'b0, a};
        b_ext = {b, 1'b0};

        for (i = 0; i < 8; i = i + 1) begin
            code = {b_ext[2*i+2], b_ext[2*i+1], b_ext[2*i]};

            case (code)
                3'b000, 3'b111: pp = 34'sd0;
                3'b001, 3'b010: pp = A_ext;
                3'b011: pp = A_ext <<< 1;
                3'b100: pp = -(A_ext <<< 1);
                3'b101, 3'b110: pp = -A_ext;
                default: pp = 34'sd0;
            endcase

            acc = acc + (pp <<< (2*i));
        end

        if (b[15]) begin
            acc = acc + (A_ext <<< 16);
        end

        result = acc[31:0];
    end

endmodule
