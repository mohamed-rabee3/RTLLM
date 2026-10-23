module fir_interpolator (
    input  wire               clk,
    input  wire               rst,
    input  wire               valid_in,
    input  wire signed [15:0] data_in,
    output reg                valid_out,
    output reg  signed [15:0] data_out
);

    localparam signed [15:0] H0 = 16'sh0040;
    localparam signed [15:0] H1 = 16'sh0080;
    localparam signed [15:0] H2 = 16'sh0080;
    localparam signed [15:0] H3 = 16'sh0040;

    reg signed [15:0] delay0;
    reg signed [15:0] delay1;
    reg signed [15:0] delay2;
    reg signed [15:0] delay3;

    wire signed [31:0] product0;
    wire signed [31:0] product1;
    wire signed [31:0] product2;
    wire signed [31:0] product3;

    wire signed [33:0] accumulator;
    wire signed [33:0] scaled_result;

    assign product0 = data_in * H0;
    assign product1 = delay0  * H1;
    assign product2 = delay1  * H2;
    assign product3 = delay2  * H3;

    assign accumulator =
        $signed({{2{product0[31]}}, product0}) +
        $signed({{2{product1[31]}}, product1}) +
        $signed({{2{product2[31]}}, product2}) +
        $signed({{2{product3[31]}}, product3});

    assign scaled_result = accumulator >>> 8;

    always @(posedge clk) begin
        if (rst) begin
            delay0    <= 16'sd0;
            delay1    <= 16'sd0;
            delay2    <= 16'sd0;
            delay3    <= 16'sd0;
            valid_out <= 1'b0;
            data_out  <= 16'sd0;
        end else begin
            valid_out <= valid_in;

            if (valid_in) begin
                delay0   <= data_in;
                delay1   <= delay0;
                delay2   <= delay1;
                delay3   <= delay2;
                data_out <= scaled_result[15:0];
            end
        end
    end

endmodule
