module mul_booth (
    input  [15:0] a,
    input  [15:0] b,
    output [31:0] result
);

    integer i;
    reg signed [39:0] sum;
    reg signed [39:0] a_ext;
    reg signed [39:0] pp;
    reg [2:0] booth;
    reg prev;
    reg [17:0] b_ext;

    always @* begin
        sum = 40'sd0;
        a_ext = {24'b0, a};
        b_ext = {2'b00, b};

        for (i = 0; i < 9; i = i + 1) begin
            if (i == 0)
                prev = 1'b0;
            else
                prev = b_ext[2*i - 1];

            booth = {b_ext[2*i + 1], b_ext[2*i], prev};

            case (booth)
                3'b000, 3'b111: pp = 40'sd0;
                3'b001, 3'b010: pp = a_ext;
                3'b011: pp = a_ext << 1;
                3'b100: pp = -(a_ext << 1);
                3'b101, 3'b110: pp = -a_ext;
                default: pp = 40'sd0;
            endcase

            sum = sum + (pp << (2*i));
        end
    end

    assign result = sum[31:0];

endmodule
