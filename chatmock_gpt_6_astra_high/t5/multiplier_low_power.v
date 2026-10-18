module mul_low_power (
    input  wire [15:0] a,
    input  wire [15:0] b,
    output wire [31:0] result
);

    wire [31:0] partial_product [0:15];
    wire [31:0] sum_level1 [0:7];
    wire [31:0] sum_level2 [0:3];
    wire [31:0] sum_level3 [0:1];

    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : gen_partial_products
            assign partial_product[i] =
                {16'b0, (a & {16{b[i]}})} << i;
        end

        for (i = 0; i < 8; i = i + 1) begin : gen_sum_level1
            assign sum_level1[i] =
                partial_product[2*i] + partial_product[2*i+1];
        end

        for (i = 0; i < 4; i = i + 1) begin : gen_sum_level2
            assign sum_level2[i] = sum_level1[2*i] + sum_level1[2*i+1];
        end

        for (i = 0; i < 2; i = i + 1) begin : gen_sum_level3
            assign sum_level3[i] = sum_level2[2*i] + sum_level2[2*i+1];
        end
    endgenerate

    assign result = sum_level3[0] + sum_level3[1];

endmodule
