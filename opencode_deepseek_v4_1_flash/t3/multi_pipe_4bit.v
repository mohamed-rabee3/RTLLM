module multi_pipe_4bit #(parameter size = 4) (
    input clk,
    input rst_n,
    input [size-1:0] mul_a,
    input [size-1:0] mul_b,
    output reg [2*size-1:0] mul_out
);

    wire [2*size-1:0] mul_a_ext = {{size{1'b0}}, mul_a};
    wire [2*size-1:0] mul_b_ext = {{size{1'b0}}, mul_b};
    wire [2*size-1:0] partial_product [size-1:0];

    genvar i;
    generate
        for (i = 0; i < size; i = i + 1) begin : gen_pp
            assign partial_product[i] = mul_b_ext[i] ? (mul_a_ext << i) : {2*size{1'b0}};
        end
    endgenerate

    reg [2*size-1:0] sum_comb;
    integer j;
    always @(*) begin
        sum_comb = {2*size{1'b0}};
        for (j = 0; j < size; j = j + 1) begin
            sum_comb = sum_comb + partial_product[j];
        end
    end

    reg [2*size-1:0] sum_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            sum_reg <= {2*size{1'b0}};
        else
            sum_reg <= sum_comb;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            mul_out <= {2*size{1'b0}};
        else
            mul_out <= sum_reg;
    end

endmodule
