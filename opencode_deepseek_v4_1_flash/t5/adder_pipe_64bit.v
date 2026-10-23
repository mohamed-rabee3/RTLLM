module adder_pipe_64bit(
    input clk,
    input rst_n,
    input i_en,
    input [63:0] adda,
    input [63:0] addb,
    output reg [64:0] result,
    output reg o_en
);

    reg [15:0] sum1_r, sum2_r, sum3_r;
    reg        carry1_r, carry2_r, carry3_r;
    reg [63:0] adda1_r, addb1_r;
    reg [63:0] adda2_r, addb2_r;
    reg [63:0] adda3_r, addb3_r;
    reg        v1, v2, v3;

    wire [16:0] sum1;
    wire [16:0] sum2;
    wire [16:0] sum3;
    wire [16:0] sum4;

    assign sum1 = {1'b0, adda[15:0]} + {1'b0, addb[15:0]};
    assign sum2 = {1'b0, adda1_r[31:16]} + {1'b0, addb1_r[31:16]} + carry1_r;
    assign sum3 = {1'b0, adda2_r[47:32]} + {1'b0, addb2_r[47:32]} + carry2_r;
    assign sum4 = {1'b0, adda3_r[63:48]} + {1'b0, addb3_r[63:48]} + carry3_r;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum1_r   <= 16'd0;
            sum2_r   <= 16'd0;
            sum3_r   <= 16'd0;
            carry1_r <= 1'b0;
            carry2_r <= 1'b0;
            carry3_r <= 1'b0;
            adda1_r  <= 64'd0;
            addb1_r  <= 64'd0;
            adda2_r  <= 64'd0;
            addb2_r  <= 64'd0;
            adda3_r  <= 64'd0;
            addb3_r  <= 64'd0;
            v1       <= 1'b0;
            v2       <= 1'b0;
            v3       <= 1'b0;
            result   <= 65'd0;
            o_en     <= 1'b0;
        end else begin
            // Stage 1
            sum1_r   <= sum1[15:0];
            carry1_r <= sum1[16];
            adda1_r  <= adda;
            addb1_r  <= addb;
            v1       <= i_en;

            // Stage 2
            sum2_r   <= sum2[15:0];
            carry2_r <= sum2[16];
            adda2_r  <= adda1_r;
            addb2_r  <= addb1_r;
            v2       <= v1;

            // Stage 3
            sum3_r   <= sum3[15:0];
            carry3_r <= sum3[16];
            adda3_r  <= adda2_r;
            addb3_r  <= addb2_r;
            v3       <= v2;

            // Stage 4 / Output
            result <= {sum4[16], sum4[15:0], sum3_r, sum2_r, sum1_r};
            o_en   <= v3;
        end
    end

endmodule
