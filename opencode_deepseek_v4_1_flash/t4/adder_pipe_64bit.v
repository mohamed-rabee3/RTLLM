module adder_pipe_64bit(
    input clk,
    input rst_n,
    input i_en,
    input [63:0] adda,
    input [63:0] addb,
    output reg [64:0] result,
    output reg o_en
);

    reg [15:0] sum0;
    reg carry0;
    reg [47:0] a1, b1;
    reg en1;

    reg [15:0] sum1;
    reg carry1;
    reg [31:0] a2, b2;
    reg en2;

    reg [15:0] sum2;
    reg carry2;
    reg [15:0] a3, b3;
    reg en3;

    wire [16:0] sum3 = {1'b0, a3} + {1'b0, b3} + carry2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum0 <= 16'b0;
            carry0 <= 1'b0;
            a1 <= 48'b0;
            b1 <= 48'b0;
            en1 <= 1'b0;

            sum1 <= 16'b0;
            carry1 <= 1'b0;
            a2 <= 32'b0;
            b2 <= 32'b0;
            en2 <= 1'b0;

            sum2 <= 16'b0;
            carry2 <= 1'b0;
            a3 <= 16'b0;
            b3 <= 16'b0;
            en3 <= 1'b0;

            result <= 65'b0;
            o_en <= 1'b0;
        end else begin
            // Stage 1: bits [15:0]
            {carry0, sum0} <= {1'b0, adda[15:0]} + {1'b0, addb[15:0]};
            a1 <= adda[63:16];
            b1 <= addb[63:16];
            en1 <= i_en;

            // Stage 2: bits [31:16]
            {carry1, sum1} <= {1'b0, a1[15:0]} + {1'b0, b1[15:0]} + carry0;
            a2 <= a1[47:16];
            b2 <= b1[47:16];
            en2 <= en1;

            // Stage 3: bits [47:32]
            {carry2, sum2} <= {1'b0, a2[15:0]} + {1'b0, b2[15:0]} + carry1;
            a3 <= a2[31:16];
            b3 <= b2[31:16];
            en3 <= en2;

            // Stage 4: bits [63:48]
            result <= {sum3[16], sum3[15:0], sum2, sum1, sum0};
            o_en <= en3;
        end
    end

endmodule
