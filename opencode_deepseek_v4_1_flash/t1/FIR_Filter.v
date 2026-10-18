module fir_interpolator (
    input clk,
    input rst,
    input valid_in,
    input signed [15:0] data_in,
    output reg valid_out,
    output reg signed [15:0] data_out
);

    localparam signed [15:0] H0 = 16'sh0040; // 0.25 in Q8.8
    localparam signed [15:0] H1 = 16'sh0080; // 0.50 in Q8.8
    localparam signed [15:0] H2 = 16'sh0080; // 0.50 in Q8.8
    localparam signed [15:0] H3 = 16'sh0040; // 0.25 in Q8.8

    reg signed [15:0] x1;
    reg signed [15:0] x2;
    reg signed [15:0] x3;

    always @(posedge clk) begin
        if (rst) begin
            x1 <= 16'sd0;
            x2 <= 16'sd0;
            x3 <= 16'sd0;
            valid_out <= 1'b0;
            data_out <= 16'sd0;
        end else begin
            valid_out <= valid_in;

            if (valid_in) begin
                data_out <= ((H0 * data_in) +
                             (H1 * x1) +
                             (H2 * x2) +
                             (H3 * x3)) >>> 8;

                x3 <= x2;
                x2 <= x1;
                x1 <= data_in;
            end
        end
    end

endmodule
