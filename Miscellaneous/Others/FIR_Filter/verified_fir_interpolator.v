module verified_fir_interpolator(
    input                     clk,
    input                     rst,
    input                     valid_in,
    input      signed [15:0]  data_in,
    output reg                valid_out,
    output reg signed [15:0]  data_out
);
    // symmetric 4-tap FIR, Q8.8 coefficients {0.25,0.5,0.5,0.25}
    localparam signed [15:0] H0 = 16'sh0040;
    localparam signed [15:0] H1 = 16'sh0080;
    localparam signed [15:0] H2 = 16'sh0080;
    localparam signed [15:0] H3 = 16'sh0040;

    reg signed [15:0] x1, x2, x3;   // delay line: x[n-1], x[n-2], x[n-3]
    reg signed [31:0] acc;

    always @(posedge clk) begin
        if (rst) begin
            x1 <= 16'sd0; x2 <= 16'sd0; x3 <= 16'sd0;
            data_out  <= 16'sd0;
            valid_out <= 1'b0;
        end else if (valid_in) begin
            acc = H0*data_in + H1*x1 + H2*x2 + H3*x3;
            data_out  <= acc >>> 8;         // remove Q8.8 scaling
            valid_out <= 1'b1;
            x1 <= data_in;
            x2 <= x1;
            x3 <= x2;
        end else begin
            valid_out <= 1'b0;
        end
    end
endmodule
