module adder_pipe_64bit (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        i_en,
    input  wire [63:0] adda,
    input  wire [63:0] addb,
    output wire [64:0] result,
    output wire        o_en
);

    // Pipeline stage registers
    reg [63:0] adda_stage1, addb_stage1;
    reg        i_en_stage1;
    
    reg [63:0] adda_stage2, addb_stage2;
    reg        i_en_stage2;
    
    reg [64:0] result_reg;
    reg        o_en_reg;

    // Stage 1: Register inputs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            adda_stage1 <= 64'd0;
            addb_stage1 <= 64'd0;
            i_en_stage1 <= 1'b0;
        end else begin
            adda_stage1 <= adda;
            addb_stage1 <= addb;
            i_en_stage1 <= i_en;
        end
    end

    // Stage 2: Register stage 1 outputs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            adda_stage2 <= 64'd0;
            addb_stage2 <= 64'd0;
            i_en_stage2 <= 1'b0;
        end else begin
            adda_stage2 <= adda_stage1;
            addb_stage2 <= addb_stage1;
            i_en_stage2 <= i_en_stage1;
        end
    end

    // Stage 3: Compute sum and register result
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result_reg <= 65'd0;
            o_en_reg   <= 1'b0;
        end else begin
            result_reg <= {1'b0, adda_stage2} + {1'b0, addb_stage2};
            o_en_reg   <= i_en_stage2;
        end
    end

    // Output assignments
    assign result = result_reg;
    assign o_en   = o_en_reg;

endmodule