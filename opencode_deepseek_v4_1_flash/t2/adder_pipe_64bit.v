module adder_pipe_64bit(
    input clk,
    input rst_n,
    input i_en,
    input [63:0] adda,
    input [63:0] addb,
    output reg [64:0] result,
    output reg o_en
);

    // Stage 0 registers
    reg [15:0] sum0_reg;
    reg carry0_reg;
    reg [47:0] a_rem1, b_rem1;
    reg en1;

    // Stage 1 registers
    reg [15:0] sum1_reg;
    reg carry1_reg;
    reg [31:0] a_rem2, b_rem2;
    reg [15:0] sum0_d1;
    reg en2;

    // Stage 2 registers
    reg [15:0] sum2_reg;
    reg carry2_reg;
    reg [15:0] a_rem3, b_rem3;
    reg [15:0] sum0_d2;
    reg [15:0] sum1_d1;
    reg en3;

    // Combinational sums
    wire [16:0] sum0 = {1'b0, adda[15:0]} + {1'b0, addb[15:0]};
    wire [16:0] sum1 = {1'b0, a_rem1[15:0]} + {1'b0, b_rem1[15:0]} + carry0_reg;
    wire [16:0] sum2 = {1'b0, a_rem2[15:0]} + {1'b0, b_rem2[15:0]} + carry1_reg;
    wire [16:0] sum3 = {1'b0, a_rem3} + {1'b0, b_rem3} + carry2_reg;

    // Stage 0
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum0_reg <= 16'd0;
            carry0_reg <= 1'b0;
            a_rem1 <= 48'd0;
            b_rem1 <= 48'd0;
            en1 <= 1'b0;
        end else if (i_en) begin
            sum0_reg <= sum0[15:0];
            carry0_reg <= sum0[16];
            a_rem1 <= adda[63:16];
            b_rem1 <= addb[63:16];
            en1 <= 1'b1;
        end else begin
            en1 <= 1'b0;
        end
    end

    // Stage 1
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum1_reg <= 16'd0;
            carry1_reg <= 1'b0;
            a_rem2 <= 32'd0;
            b_rem2 <= 32'd0;
            sum0_d1 <= 16'd0;
            en2 <= 1'b0;
        end else if (en1) begin
            sum1_reg <= sum1[15:0];
            carry1_reg <= sum1[16];
            a_rem2 <= a_rem1[47:16];
            b_rem2 <= b_rem1[47:16];
            sum0_d1 <= sum0_reg;
            en2 <= 1'b1;
        end else begin
            en2 <= 1'b0;
        end
    end

    // Stage 2
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum2_reg <= 16'd0;
            carry2_reg <= 1'b0;
            a_rem3 <= 16'd0;
            b_rem3 <= 16'd0;
            sum0_d2 <= 16'd0;
            sum1_d1 <= 16'd0;
            en3 <= 1'b0;
        end else if (en2) begin
            sum2_reg <= sum2[15:0];
            carry2_reg <= sum2[16];
            a_rem3 <= a_rem2[31:16];
            b_rem3 <= b_rem2[31:16];
            sum0_d2 <= sum0_d1;
            sum1_d1 <= sum1_reg;
            en3 <= 1'b1;
        end else begin
            en3 <= 1'b0;
        end
    end

    // Stage 3 and output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result <= 65'd0;
            o_en <= 1'b0;
        end else begin
            if (en3) begin
                result <= {sum3[16], sum3[15:0], sum2_reg, sum1_d1, sum0_d2};
            end
            o_en <= en3;
        end
    end

endmodule
