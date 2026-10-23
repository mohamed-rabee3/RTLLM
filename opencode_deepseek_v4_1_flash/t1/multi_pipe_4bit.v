module multi_pipe_4bit #(
    parameter size = 4
)(
    input clk,
    input rst_n,
    input [size-1:0] mul_a,
    input [size-1:0] mul_b,
    output reg [2*size-1:0] mul_out
);

    wire [2*size-1:0] mul_a_ext = {{size{1'b0}}, mul_a};
    wire [2*size-1:0] mul_b_ext = {{size{1'b0}}, mul_b};

    wire [2*size-1:0] pp [0:size-1];
    reg  [2*size-1:0] sum [0:(size/2)-1];

    genvar i;
    generate
        for (i = 0; i < size; i = i + 1) begin : gen_partial_products
            assign pp[i] = mul_b_ext[i] ? (mul_a_ext << i) : 0;
        end
    endgenerate

    integer j;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (j = 0; j < size/2; j = j + 1)
                sum[j] <= 0;
        end else begin
            for (j = 0; j < size/2; j = j + 1)
                sum[j] <= pp[2*j] + pp[2*j+1];
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            mul_out <= 0;
        else
            mul_out <= sum[0] + sum[1];
    end

endmodule
