module multi_pipe_4bit #(
    parameter size = 4
) (
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire [size-1:0]        mul_a,
    input  wire [size-1:0]        mul_b,
    output reg  [2*size-1:0]      mul_out
);

    localparam PRODUCT_WIDTH = 2 * size;
    localparam SUM_COUNT     = (size + 1) / 2;

    wire [PRODUCT_WIDTH-1:0] mul_a_ext;
    wire [PRODUCT_WIDTH-1:0] mul_b_ext;
    wire [PRODUCT_WIDTH-1:0] partial_product [0:size-1];
    reg  [PRODUCT_WIDTH-1:0] intermediate_sum [0:SUM_COUNT-1];
    reg  [PRODUCT_WIDTH-1:0] final_sum;

    assign mul_a_ext = {{size{1'b0}}, mul_a};
    assign mul_b_ext = {{size{1'b0}}, mul_b};

    genvar i;
    generate
        for (i = 0; i < size; i = i + 1) begin : gen_partial_products
            assign partial_product[i] =
                mul_b_ext[i] ? (mul_a_ext << i) :
                              {PRODUCT_WIDTH{1'b0}};
        end
    endgenerate

    genvar j;
    generate
        for (j = 0; j < SUM_COUNT; j = j + 1) begin : gen_first_stage
            if ((2*j + 1) < size) begin : gen_pair
                always @(posedge clk or negedge rst_n) begin
                    if (!rst_n)
                        intermediate_sum[j] <= {PRODUCT_WIDTH{1'b0}};
                    else
                        intermediate_sum[j] <= partial_product[2*j]
                                             + partial_product[2*j+1];
                end
            end else begin : gen_unpaired
                always @(posedge clk or negedge rst_n) begin
                    if (!rst_n)
                        intermediate_sum[j] <= {PRODUCT_WIDTH{1'b0}};
                    else
                        intermediate_sum[j] <= partial_product[2*j];
                end
            end
        end
    endgenerate

    integer k;
    always @* begin
        final_sum = {PRODUCT_WIDTH{1'b0}};
        for (k = 0; k < SUM_COUNT; k = k + 1)
            final_sum = final_sum + intermediate_sum[k];
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            mul_out <= {PRODUCT_WIDTH{1'b0}};
        else
            mul_out <= final_sum;
    end

endmodule
