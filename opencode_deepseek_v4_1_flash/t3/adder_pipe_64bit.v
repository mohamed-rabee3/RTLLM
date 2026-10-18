module adder_pipe_64bit(
    input clk,
    input rst_n,
    input i_en,
    input [63:0] adda,
    input [63:0] addb,
    output reg [64:0] result,
    output reg o_en
);

    reg [15:0] sum1, sum2, sum3, sum4;
    reg [15:0] a1, a2, a3;
    reg [15:0] b1, b2, b3;
    reg carry1, carry2, carry3, carry4;
    reg en1, en2, en3, en4;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum1 <= 16'b0;
            sum2 <= 16'b0;
            sum3 <= 16'b0;
            sum4 <= 16'b0;
            a1 <= 16'b0;
            a2 <= 16'b0;
            a3 <= 16'b0;
            b1 <= 16'b0;
            b2 <= 16'b0;
            b3 <= 16'b0;
            carry1 <= 1'b0;
            carry2 <= 1'b0;
            carry3 <= 1'b0;
            carry4 <= 1'b0;
            en1 <= 1'b0;
            en2 <= 1'b0;
            en3 <= 1'b0;
            en4 <= 1'b0;
            result <= 65'b0;
            o_en <= 1'b0;
        end else begin
            // Stage 1: bits 0-15
            {carry1, sum1} <= adda[15:0] + addb[15:0];
            a1 <= adda[31:16];
            b1 <= addb[31:16];
            en1 <= i_en;

            // Stage 2: bits 16-31
            {carry2, sum2} <= a1 + b1 + carry1;
            a2 <= adda[47:32];
            b2 <= addb[47:32];
            en2 <= en1;

            // Stage 3: bits 32-47
            {carry3, sum3} <= a2 + b2 + carry2;
            a3 <= adda[63:48];
            b3 <= addb[63:48];
            en3 <= en2;

            // Stage 4: bits 48-63
            {carry4, sum4} <= a3 + b3 + carry3;
            en4 <= en3;

            // Output register
            result <= {carry4, sum4, sum3, sum2, sum1};
            o_en <= en4;
        end
    end

endmodule
