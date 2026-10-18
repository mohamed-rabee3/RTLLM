module clkgenerator #(
    parameter PERIOD = 10
) (
    output reg clk
);

    initial begin
        clk = 1'b0;
    end

    always #(PERIOD / 2) begin
        clk = ~clk;
    end

endmodule
