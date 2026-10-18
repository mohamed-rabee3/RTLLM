module fir_interpolator (
    input clk,
    input rst,
    input valid_in,
    input signed [15:0] data_in,
    output reg valid_out,
    output reg signed [15:0] data_out
);

    localparam signed [15:0] H0 = 16'sh0040;
    localparam signed [15:0] H1 = 16'sh0080;
    localparam signed [15:0] H2 = 16'sh0080;
    localparam signed [15:0] H3 = 16'sh0040;

    reg signed [15:0] delay0;
    reg signed [15:0] delay1;
    reg signed [15:0] delay2;
    reg signed [15:0] delay3;

    wire signed [31:0] acc;

    assign acc = H0 * data_in + H1 * delay0 + H2 * delay1 + H3 * delay2;

    always @(posedge clk) begin
        if (rst) begin
            delay0 <= 16'sd0;
            delay1 <= 16'sd0;
            delay2 <= 16'sd0;
            delay3 <= 16'sd0;
            valid_out <= 1'b0;
            data_out <= 16'sd0;
        end else begin
            valid_out <= valid_in;

            if (valid_in) begin
                data_out <= acc >>> 8;
                delay3 <= delay2;
                delay2 <= delay1;
                delay1 <= delay0;
                delay0 <= data_in;
            end
        end
    end

endmodule
