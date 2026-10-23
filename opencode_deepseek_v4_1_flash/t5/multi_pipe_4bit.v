module multi_pipe_4bit #(parameter size = 4)(
    input clk,
    input rst_n,
    input [size-1:0] mul_a,
    input [size-1:0] mul_b,
    output reg [2*size-1:0] mul_out
);

    wire [2*size-1:0] mul_a_ext;
    wire [2*size-1:0] mul_b_ext;
    wire [2*size-1:0] partial_product [0:size-1];

    assign mul_a_ext = {{size{1'b0}}, mul_a};
    assign mul_b_ext = {{size{1'b0}}, mul_b};

    genvar i;
    generate
        for (i = 0; i < size; i = i + 1) begin : gen_partial_product
            assign partial_product[i] = mul_b_ext[i] ? (mul_a_ext << i) : 0;
        end
    endgenerate

    reg [2*size-1:0] sum0;
    reg [2*size-1:0] sum1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum0 <= 0;
            sum1 <= 0;
        end else begin
            sum0 <= partial_product[0] + partial_product[1];
            sum1 <= partial_product[2] + partial_product[3];
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mul_out <= 0;
        end else begin
            mul_out <= sum0 + sum1;
        end
    end

endmodule
