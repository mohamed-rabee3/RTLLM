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

    genvar i;
    generate
        for (i = 0; i < size; i = i + 1) begin : gen_pp
            assign pp[i] = mul_b_ext[i] ? (mul_a_ext << i) : 0;
        end
    endgenerate

    reg [2*size-1:0] sum_reg [0:1];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum_reg[0] <= 0;
            sum_reg[1] <= 0;
        end else begin
            sum_reg[0] <= pp[0] + pp[1];
            sum_reg[1] <= pp[2] + pp[3];
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mul_out <= 0;
        end else begin
            mul_out <= sum_reg[0] + sum_reg[1];
        end
    end

endmodule
