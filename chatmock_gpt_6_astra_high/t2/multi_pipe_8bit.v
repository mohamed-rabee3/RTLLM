module multi_pipe_8bit (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        mul_en_in,
    input  wire [7:0]  mul_a,
    input  wire [7:0]  mul_b,
    output wire        mul_en_out,
    output wire [15:0] mul_out
);

    reg  [2:0]  mul_en_out_reg;
    reg  [7:0]  mul_a_reg;
    reg  [7:0]  mul_b_reg;
    wire [15:0] temp [0:7];
    reg  [15:0] sum [0:3];
    reg  [15:0] mul_out_reg;

    // Three pipeline stages: input capture, partial sums, final sum.
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mul_en_out_reg <= 3'b000;
            mul_a_reg      <= 8'b0;
            mul_b_reg      <= 8'b0;
        end else begin
            mul_en_out_reg <= {mul_en_out_reg[1:0], mul_en_in};
            if (mul_en_in) begin
                mul_a_reg <= mul_a;
                mul_b_reg <= mul_b;
            end
        end
    end

    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : gen_partial_products
            assign temp[i] = mul_b_reg[i]
                           ? ({8'b0, mul_a_reg} << i)
                           : 16'b0;
        end
    endgenerate

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum[0] <= 16'b0;
            sum[1] <= 16'b0;
            sum[2] <= 16'b0;
            sum[3] <= 16'b0;
        end else begin
            sum[0] <= temp[0] + temp[1];
            sum[1] <= temp[2] + temp[3];
            sum[2] <= temp[4] + temp[5];
            sum[3] <= temp[6] + temp[7];
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            mul_out_reg <= 16'b0;
        else
            mul_out_reg <= sum[0] + sum[1] + sum[2] + sum[3];
    end

    assign mul_en_out = mul_en_out_reg[2];
    assign mul_out    = mul_en_out ? mul_out_reg : 16'b0;

endmodule
