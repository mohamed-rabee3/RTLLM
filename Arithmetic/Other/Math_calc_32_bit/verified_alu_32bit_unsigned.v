module verified_alu_32bit_unsigned(
    input             clk,
    input             rst,
    input             valid_in,
    input      [31:0] a,
    input      [31:0] b,
    input      [1:0]  op,
    output reg [63:0] result,
    output reg        result_valid
);
    always @(posedge clk) begin
        if (rst) begin
            result       <= 64'd0;
            result_valid <= 1'b0;
        end else if (valid_in && !result_valid) begin
            // accept one operation, pulse result_valid for a single cycle
            case (op)
                2'b00: result <= {32'b0, a} + {32'b0, b};   // add
                2'b01: result <= {32'b0, a} * {32'b0, b};   // multiply
                2'b10: result <= (a < b) ? {32'b0, a} : {32'b0, b}; // min
                default: result <= 64'hFFFFFFFFFFFFFFFF;
            endcase
            result_valid <= 1'b1;
        end else begin
            result_valid <= 1'b0;
        end
    end
endmodule
