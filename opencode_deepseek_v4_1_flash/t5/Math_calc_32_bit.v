module alu_32bit_unsigned (
    input wire clk,
    input wire rst,
    input wire valid_in,
    input wire [31:0] a,
    input wire [31:0] b,
    input wire [1:0] op,
    output reg [63:0] result,
    output reg result_valid
);

    always @(posedge clk) begin
        if (rst) begin
            result <= 64'd0;
            result_valid <= 1'b0;
        end else begin
            result_valid <= valid_in;
            if (valid_in) begin
                case (op)
                    2'b00: result <= {32'b0, a} + {32'b0, b};
                    2'b01: result <= {32'b0, a} * {32'b0, b};
                    2'b10: result <= (a < b) ? {32'b0, a} : {32'b0, b};
                    default: result <= 64'hFFFFFFFFFFFFFFFF;
                endcase
            end
        end
    end

endmodule
