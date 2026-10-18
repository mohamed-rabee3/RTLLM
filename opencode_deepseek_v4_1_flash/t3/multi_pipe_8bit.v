module multi_pipe_8bit(
    input clk,
    input rst_n,
    input mul_en_in,
    input [7:0] mul_a,
    input [7:0] mul_b,
    output mul_en_out,
    output [15:0] mul_out
);

    reg [7:0] mul_a_reg;
    reg [7:0] mul_b_reg;
    reg [2:0] mul_en_out_reg;
    reg [15:0] sum0, sum1, sum2, sum3;
    reg [15:0] mul_out_reg;

    wire [15:0] temp0, temp1, temp2, temp3, temp4, temp5, temp6, temp7;

    assign mul_en_out = mul_en_out_reg[2];
    assign mul_out = mul_en_out ? mul_out_reg : 16'd0;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mul_a_reg <= 8'd0;
            mul_b_reg <= 8'd0;
        end else if (mul_en_in) begin
            mul_a_reg <= mul_a;
            mul_b_reg <= mul_b;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mul_en_out_reg <= 3'd0;
        end else begin
            mul_en_out_reg <= {mul_en_out_reg[1:0], mul_en_in};
        end
    end

    assign temp0 = mul_b_reg[0] ? {8'b0, mul_a_reg} : 16'd0;
    assign temp1 = mul_b_reg[1] ? {7'b0, mul_a_reg, 1'b0} : 16'd0;
    assign temp2 = mul_b_reg[2] ? {6'b0, mul_a_reg, 2'b0} : 16'd0;
    assign temp3 = mul_b_reg[3] ? {5'b0, mul_a_reg, 3'b0} : 16'd0;
    assign temp4 = mul_b_reg[4] ? {4'b0, mul_a_reg, 4'b0} : 16'd0;
    assign temp5 = mul_b_reg[5] ? {3'b0, mul_a_reg, 5'b0} : 16'd0;
    assign temp6 = mul_b_reg[6] ? {2'b0, mul_a_reg, 6'b0} : 16'd0;
    assign temp7 = mul_b_reg[7] ? {1'b0, mul_a_reg, 7'b0} : 16'd0;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum0 <= 16'd0;
            sum1 <= 16'd0;
            sum2 <= 16'd0;
            sum3 <= 16'd0;
        end else begin
            sum0 <= temp0 + temp1;
            sum1 <= temp2 + temp3;
            sum2 <= temp4 + temp5;
            sum3 <= temp6 + temp7;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mul_out_reg <= 16'd0;
        end else begin
            mul_out_reg <= sum0 + sum1 + sum2 + sum3;
        end
    end

endmodule
