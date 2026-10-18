module mul_low_area (
    input  wire [15:0] a,
    input  wire [15:0] b,
    output reg  [31:0] result
);

    integer i;
    reg [31:0] a_ext;

    always @* begin
        result = 32'd0;
        a_ext = {16'b0, a};

        for (i = 0; i < 16; i = i + 1) begin
            if (b[i])
                result = result + (a_ext << i);
        end
    end

endmodule
