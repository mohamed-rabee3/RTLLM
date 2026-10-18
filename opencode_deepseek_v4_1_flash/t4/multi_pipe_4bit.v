module multi_pipe_4bit #(
    parameter size = 4
)(
    input clk,
    input rst_n,
    input [size-1:0] mul_a,
    input [size-1:0] mul_b,
    output reg [2*size-1:0] mul_out
);

    localparam WIDTH2 = 2 * size;
    localparam PAIR_COUNT = (size + 1) / 2;

    wire [WIDTH2-1:0] mul_a_ext;
    wire [WIDTH2-1:0] mul_b_ext;

    assign mul_a_ext = {{size{1'b0}}, mul_a};
    assign mul_b_ext = {{size{1'b0}}, mul_b};

    wire [WIDTH2-1:0] pp [0:size-1];

    genvar i;
    generate
        for (i = 0; i < size; i = i + 1) begin : gen_pp
            assign pp[i] = mul_b_ext[i] ? (mul_a_ext << i) : {WIDTH2{1'b0}};
        end
    endgenerate

    reg [WIDTH2-1:0] sum_reg [0:PAIR_COUNT-1];

    integer k;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (k = 0; k < PAIR_COUNT; k = k + 1)
                sum_reg[k] <= {WIDTH2{1'b0}};
        end else begin
            for (k = 0; k < PAIR_COUNT; k = k + 1) begin
                if ((2*k + 1) < size)
                    sum_reg[k] <= pp[2*k] + pp[2*k + 1];
                else
                    sum_reg[k] <= pp[2*k];
            end
        end
    end

    reg [WIDTH2-1:0] sum_total;
    integer j;
    always @* begin
        sum_total = {WIDTH2{1'b0}};
        for (j = 0; j < PAIR_COUNT; j = j + 1)
            sum_total = sum_total + sum_reg[j];
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            mul_out <= {WIDTH2{1'b0}};
        else
            mul_out <= sum_total;
    end

endmodule
