module mul_booth(
    input [15:0] a,
    input [15:0] b,
    output reg [31:0] result
);

    reg signed [39:0] acc;
    reg signed [39:0] a_ext;
    reg signed [39:0] pp;
    reg signed [39:0] corr;
    reg [2:0] booth_code;
    integer i;

    always @* begin
        a_ext = {24'b0, a};
        acc = 40'sd0;

        for (i = 0; i < 8; i = i + 1) begin
            if (i == 0)
                booth_code = {b[2*i+1], b[2*i], 1'b0};
            else
                booth_code = {b[2*i+1], b[2*i], b[2*i-1]};

            case (booth_code)
                3'b000: pp = 40'sd0;
                3'b001: pp = a_ext;
                3'b010: pp = a_ext;
                3'b011: pp = a_ext <<< 1;
                3'b100: pp = -(a_ext <<< 1);
                3'b101: pp = -a_ext;
                3'b110: pp = -a_ext;
                3'b111: pp = 40'sd0;
                default: pp = 40'sd0;
            endcase

            acc = acc + (pp <<< (2*i));
        end

        corr = b[15] ? (a_ext <<< 16) : 40'sd0;
        result = acc + corr;
    end

endmodule
