module multi_pipe_4bit #(
    parameter size = 4
) (
    input wire clk,
    input wire rst_n,
    input wire [size-1:0] mul_a,
    input wire [size-1:0] mul_b,
    output reg [2*size-1:0] mul_out
);

    // Extended inputs with 'size' zeros at the most significant bit positions
    wire [2*size-1:0] mul_a_ext;
    wire [2*size-1:0] mul_b_ext;
    assign mul_a_ext = {size{1'b0}, mul_a};
    assign mul_b_ext = {size{1'b0}, mul_b};

    // Partial products array
    wire [2*size-1:0] pp [0:size-1];

    // Generate partial products for each bit of the multiplier
    genvar i;
    generate
        for (i = 0; i < size; i = i + 1) begin : gen_pp
            assign pp[i] = mul_b[i] ? (mul_a_ext << i) : {2*size{1'b0}};
        end
    endgenerate

    // First pipeline stage: intermediate sum registers
    reg [2*size-1:0] sum01_reg, sum23_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum01_reg <= {2*size{1'b0}};
            sum23_reg <= {2*size{1'b0}};
        end else begin
            // Add corresponding partial products
            sum01_reg <= pp[0] + pp[1];
            sum23_reg <= pp[2] + pp[3];
        end
    end

    // Second pipeline stage: final product register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mul_out <= {2*size{1'b0}};
        end else begin
            mul_out <= sum01_reg + sum23_reg;
        end
    end

endmodule