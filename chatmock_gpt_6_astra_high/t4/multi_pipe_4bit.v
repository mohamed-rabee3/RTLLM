module multi_pipe_4bit #(
    parameter size = 4
) (
    input  wire                    clk,
    input  wire                    rst_n,
    input  wire [size-1:0]         mul_a,
    input  wire [size-1:0]         mul_b,
    output reg  [2*size-1:0]       mul_out
);

    localparam NUM_SUMS = (size + 1) / 2;

    wire [2*size-1:0] mul_a_ext;
    wire [2*size-1:0] mul_b_ext;
    wire [2*size-1:0] partial_product [0:size-1];
    reg  [2*size-1:0] sum_reg [0:NUM_SUMS-1];
    reg  [2*size-1:0] final_sum;

    assign mul_a_ext = {{size{1'b0}}, mul_a};
    assign mul_b_ext = {{size{1'b0}}, mul_b};

    genvar i;
    generate
        for (i = 0; i < size; i = i + 1) begin : gen_partial_products
            assign partial_product[i] =
                mul_b_ext[i] ? (mul_a_ext << i) : {2*size{1'b0}};
        end
    endgenerate

    genvar j;
    generate
        for (j = 0; j < NUM_SUMS; j = j + 1) begin : gen_sum_registers
            if ((2*j + 1) < size) begin : gen_pair
                always @(posedge clk or negedge rst_n) begin
                    if (!rst_n)
                        sum_reg[j] <= {2*size{1'b0}};
                    else
                        sum_reg[j] <= partial_product[2*j]
                                    + partial_product[2*j + 1];
                end
            end else begin : gen_unpaired
                always @(posedge clk or negedge rst_n) begin
                    if (!rst_n)
                        sum_reg[j] <= {2*size{1'b0}};
                    else
                        sum_reg[j] <= partial_product[2*j];
                end
            end
        end
    endgenerate

    integer k;
    always @* begin
        final_sum = {2*size{1'b0}};
        for (k = 0; k < NUM_SUMS; k = k + 1)
            final_sum = final_sum + sum_reg[k];
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            mul_out <= {2*size{1'b0}};
        else
            mul_out <= final_sum;
    end

endmodule
