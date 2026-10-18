module fir_interpolator (
    input clk,
    input rst,
    input valid_in,
    input [15:0] data_in,
    output reg valid_out,
    output reg [15:0] data_out
);

    localparam signed [15:0] H0 = 16'sh0040; // 0.25 Q8.8
    localparam signed [15:0] H1 = 16'sh0080; // 0.50 Q8.8
    localparam signed [15:0] H2 = 16'sh0080; // 0.50 Q8.8
    localparam signed [15:0] H3 = 16'sh0040; // 0.25 Q8.8

    reg signed [15:0] x0, x1, x2, x3;
    reg signed [31:0] acc;

    always @(posedge clk) begin
        if (rst) begin
            x0 <= 16'sd0;
            x1 <= 16'sd0;
            x2 <= 16'sd0;
            x3 <= 16'sd0;
            data_out <= 16'sd0;
            valid_out <= 1'b0;
        end else begin
            valid_out <= valid_in;

            if (valid_in) begin
                x3 <= x2;
                x2 <= x1;
                x1 <= x0;
                x0 <= $signed(data_in);

                acc = H0 * $signed(data_in) +
                      H1 * x0 +
                      H2 * x1 +
                      H3 * x2;

                data_out <= acc >>> 8;
            end
        end
    end

endmodule
