module alu_32bit_unsigned (
    input clk,
    input rst,
    input valid_in,
    input [31:0] a,
    input [31:0] b,
    input [1:0] op,
    output reg [63:0] result,
    output reg result_valid
);

    wire [63:0] a_ext = {32'b0, a};
    wire [63:0] b_ext = {32'b0, b};
    wire [63:0] sum = a_ext + b_ext;
    wire [63:0] prod = a_ext * b_ext;
    wire [63:0] min_val = (a < b) ? a_ext : b_ext;

    always @(posedge clk) begin
        if (rst) begin
            result <= 64'd0;
            result_valid <= 1'b0;
        end else begin
            result_valid <= valid_in;

            if (valid_in) begin
                case (op)
                    2'b00: result <= sum;
                    2'b01: result <= prod;
                    2'b10: result <= min_val;
                    default: result <= 64'hFFFFFFFFFFFFFFFF;
                endcase
            end
        end
    end

endmodule
