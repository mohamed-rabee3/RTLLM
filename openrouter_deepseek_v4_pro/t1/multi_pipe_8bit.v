module multi_pipe_8bit (
    input           clk,
    input           rst_n,
    input           mul_en_in,
    input   [7:0]  mul_a,
    input   [7:0]  mul_b,
    output          mul_en_out,
    output  [15:0] mul_out
);

    // Pipeline shift register for enable signal
    reg [2:0] mul_en_out_reg;   // depth = 3

    // Input registers
    reg [7:0] mul_a_reg;
    reg [7:0] mul_b_reg;

    // Partial product wires
    wire [7:0] temp [0:7];

    // Partial sum registers
    reg [9:0]  sum0;
    reg [11:0] sum1;
    reg [13:0] sum2;
    reg [15:0] sum3;

    // Final product register
    reg [15:0] mul_out_reg;

    // Input control: sample enable and data when mul_en_in is active
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mul_en_out_reg <= 3'd0;
            mul_a_reg      <= 8'd0;
            mul_b_reg      <= 8'd0;
        end else begin
            // Shift enable through the pipeline
            mul_en_out_reg <= {mul_en_out_reg[1:0], mul_en_in};

            if (mul_en_in) begin
                mul_a_reg <= mul_a;
                mul_b_reg <= mul_b;
            end
        end
    end

    // Partial product generation (combinational)
    assign temp[0] = {8{mul_b_reg[0]}} & mul_a_reg;
    assign temp[1] = {8{mul_b_reg[1]}} & mul_a_reg;
    assign temp[2] = {8{mul_b_reg[2]}} & mul_a_reg;
    assign temp[3] = {8{mul_b_reg[3]}} & mul_a_reg;
    assign temp[4] = {8{mul_b_reg[4]}} & mul_a_reg;
    assign temp[5] = {8{mul_b_reg[5]}} & mul_a_reg;
    assign temp[6] = {8{mul_b_reg[6]}} & mul_a_reg;
    assign temp[7] = {8{mul_b_reg[7]}} & mul_a_reg;

    // Partial sum calculation (registered)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum0 <= 10'd0;
            sum1 <= 12'd0;
            sum2 <= 14'd0;
            sum3 <= 16'd0;
        end else begin
            // Sum of pp[0] and pp[1] << 1
            sum0 <= {2'd0, temp[0]} + {1'd0, temp[1], 1'd0};
            // Sum of pp[2] << 2 and pp[3] << 3
            sum1 <= {2'd0, temp[2], 2'd0} + {1'd0, temp[3], 3'd0};
            // Sum of pp[4] << 4 and pp[5] << 5
            sum2 <= {2'd0, temp[4], 4'd0} + {1'd0, temp[5], 5'd0};
            // Sum of pp[6] << 6 and pp[7] << 7
            sum3 <= {2'd0, temp[6], 6'd0} + {1'd0, temp[7], 7'd0};
        end
    end

    // Final product calculation (registered)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mul_out_reg <= 16'd0;
        end else begin
            mul_out_reg <= {6'd0, sum0} + {4'd0, sum1} + {2'd0, sum2} + sum3;
        end
    end

    // Output assignments
    assign mul_en_out = mul_en_out_reg[2];
    assign mul_out    = mul_en_out ? mul_out_reg : 16'd0;

endmodule