module mul_booth(
    input [15:0] a,
    input [15:0] b,
    output reg [31:0] result
);

    integer i;
    reg [2:0] code;
    reg [33:0] sum;
    reg [33:0] pp;

    always @(*) begin
        sum = 34'd0;

        for (i = 0; i < 8; i = i + 1) begin
            if (i == 0)
                code = {b[1], b[0], 1'b0};
            else
                code = {b[2*i+1], b[2*i], b[2*i-1]};

            case (code)
                3'b000, 3'b111: pp = 34'd0;
                3'b001, 3'b010: pp = {{18{1'b0}}, a};
                3'b011:         pp = {{17{1'b0}}, a, 1'b0};
                3'b100:         pp = 34'd0 - {{17{1'b0}}, a, 1'b0};
                3'b101, 3'b110: pp = 34'd0 - {{18{1'b0}}, a};
                default:        pp = 34'd0;
            endcase

            sum = sum + (pp << (2*i));
        end

        if (b[15])
            sum = sum + ({{18{1'b0}}, a} << 16);

        result = sum[31:0];
    end

endmodule
