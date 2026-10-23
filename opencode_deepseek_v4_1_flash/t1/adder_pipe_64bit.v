module adder_pipe_64bit(
    input clk,
    input rst_n,
    input i_en,
    input [63:0] adda,
    input [63:0] addb,
    output reg [64:0] result,
    output reg o_en
);

    reg [15:0] sum0, sum1, sum2;
    reg carry0, carry1, carry2;
    reg [15:0] a1, b1, a2, b2, a3, b3;
    reg [15:0] sum0_1, a2_1, b2_1, a3_1, b3_1;
    reg [15:0] sum1_2, sum0_2, a3_2, b3_2;
    reg en0, en1, en2;

    wire [16:0] sum3_full = a3_2 + b3_2 + carry2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum0 <= 16'd0;
            sum1 <= 16'd0;
            sum2 <= 16'd0;
            carry0 <= 1'b0;
            carry1 <= 1'b0;
            carry2 <= 1'b0;
            a1 <= 16'd0;
            b1 <= 16'd0;
            a2 <= 16'd0;
            b2 <= 16'd0;
            a3 <= 16'd0;
            b3 <= 16'd0;
            sum0_1 <= 16'd0;
            a2_1 <= 16'd0;
            b2_1 <= 16'd0;
            a3_1 <= 16'd0;
            b3_1 <= 16'd0;
            sum1_2 <= 16'd0;
            sum0_2 <= 16'd0;
            a3_2 <= 16'd0;
            b3_2 <= 16'd0;
            en0 <= 1'b0;
            en1 <= 1'b0;
            en2 <= 1'b0;
            result <= 65'd0;
            o_en <= 1'b0;
        end else begin
            // Stage 0: lower 16 bits
            {carry0, sum0} <= adda[15:0] + addb[15:0];
            a1 <= adda[31:16];
            b1 <= addb[31:16];
            a2 <= adda[47:32];
            b2 <= addb[47:32];
            a3 <= adda[63:48];
            b3 <= addb[63:48];
            en0 <= i_en;

            // Stage 1: bits 31:16
            {carry1, sum1} <= a1 + b1 + carry0;
            sum0_1 <= sum0;
            a2_1 <= a2;
            b2_1 <= b2;
            a3_1 <= a3;
            b3_1 <= b3;
            en1 <= en0;

            // Stage 2: bits 47:32
            {carry2, sum2} <= a2_1 + b2_1 + carry1;
            sum1_2 <= sum1;
            sum0_2 <= sum0_1;
            a3_2 <= a3_1;
            b3_2 <= b3_1;
            en2 <= en1;

            // Stage 3: bits 63:48 and output assembly
            result <= {sum3_full[16], sum3_full[15:0], sum2, sum1_2, sum0_2};
            o_en <= en2;
        end
    end

endmodule
