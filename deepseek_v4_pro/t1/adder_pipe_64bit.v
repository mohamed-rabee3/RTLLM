module adder_pipe_64bit (
    input           clk,
    input           rst_n,
    input           i_en,
    input  [63:0]   adda,
    input  [63:0]   addb,
    output [64:0]   result,
    output          o_en
);

    // --------------------------------------------------------------
    // Pipeline stage 0 registers
    // --------------------------------------------------------------
    reg         valid0;
    reg         carry1_reg;
    reg [15:0]  sum0_reg;
    reg [47:0]  adda_rem0;
    reg [47:0]  addb_rem0;

    // --------------------------------------------------------------
    // Pipeline stage 1 registers
    // --------------------------------------------------------------
    reg         valid1;
    reg         carry2_reg;
    reg [15:0]  sum1_reg;
    reg [15:0]  sum0_reg1;
    reg [31:0]  adda_rem1;
    reg [31:0]  addb_rem1;

    // --------------------------------------------------------------
    // Pipeline stage 2 registers
    // --------------------------------------------------------------
    reg         valid2;
    reg         carry3_reg;
    reg [15:0]  sum2_reg;
    reg [15:0]  sum1_reg2;
    reg [15:0]  sum0_reg2;
    reg [15:0]  adda_rem2;
    reg [15:0]  addb_rem2;

    // --------------------------------------------------------------
    // Pipeline stage 3 registers
    // --------------------------------------------------------------
    reg         valid3;
    reg         carry4_reg;
    reg [15:0]  sum3_reg;
    reg [15:0]  sum2_reg3;
    reg [15:0]  sum1_reg3;
    reg [15:0]  sum0_reg3;

    // --------------------------------------------------------------
    // Combinational logic for stage 0 (bits 15:0, carry_in = 0)
    // --------------------------------------------------------------
    wire        carry1;
    wire [15:0] sum0;
    assign {carry1, sum0} = {1'b0, adda[15:0]} + {1'b0, addb[15:0]};

    // --------------------------------------------------------------
    // Combinational logic for stage 1 (bits 31:16)
    // --------------------------------------------------------------
    wire        carry2;
    wire [15:0] sum1;
    wire [16:0] sum1_full;
    assign sum1_full = {1'b0, adda_rem0[15:0]} + {1'b0, addb_rem0[15:0]} + {16'd0, carry1_reg};
    assign {carry2, sum1} = sum1_full;

    // --------------------------------------------------------------
    // Combinational logic for stage 2 (bits 47:32)
    // --------------------------------------------------------------
    wire        carry3;
    wire [15:0] sum2;
    wire [16:0] sum2_full;
    assign sum2_full = {1'b0, adda_rem1[15:0]} + {1'b0, addb_rem1[15:0]} + {16'd0, carry2_reg};
    assign {carry3, sum2} = sum2_full;

    // --------------------------------------------------------------
    // Combinational logic for stage 3 (bits 63:48, final carry)
    // --------------------------------------------------------------
    wire        carry4;
    wire [15:0] sum3;
    wire [16:0] sum3_full;
    assign sum3_full = {1'b0, adda_rem2[15:0]} + {1'b0, addb_rem2[15:0]} + {16'd0, carry3_reg};
    assign {carry4, sum3} = sum3_full;

    // --------------------------------------------------------------
    // Pipeline registers update (synchronous with active-low reset)
    // --------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Stage 0 reset
            valid0     <= 1'b0;
            carry1_reg <= 1'b0;
            sum0_reg   <= 16'd0;
            adda_rem0  <= 48'd0;
            addb_rem0  <= 48'd0;

            // Stage 1 reset
            valid1     <= 1'b0;
            carry2_reg <= 1'b0;
            sum1_reg   <= 16'd0;
            sum0_reg1  <= 16'd0;
            adda_rem1  <= 32'd0;
            addb_rem1  <= 32'd0;

            // Stage 2 reset
            valid2     <= 1'b0;
            carry3_reg <= 1'b0;
            sum2_reg   <= 16'd0;
            sum1_reg2  <= 16'd0;
            sum0_reg2  <= 16'd0;
            adda_rem2  <= 16'd0;
            addb_rem2  <= 16'd0;

            // Stage 3 reset
            valid3     <= 1'b0;
            carry4_reg <= 1'b0;
            sum3_reg   <= 16'd0;
            sum2_reg3  <= 16'd0;
            sum1_reg3  <= 16'd0;
            sum0_reg3  <= 16'd0;
        end else begin
            // Stage 0: capture inputs and lower 16-bit addition result
            valid0     <= i_en;
            carry1_reg <= carry1;
            sum0_reg   <= sum0;
            adda_rem0  <= adda[63:16];
            addb_rem0  <= addb[63:16];

            // Stage 1: process next 16 bits, pass lower sum and remaining upper operands
            valid1     <= valid0;
            carry2_reg <= carry2;
            sum1_reg   <= sum1;
            sum0_reg1  <= sum0_reg;
            adda_rem1  <= adda_rem0[47:16];
            addb_rem1  <= addb_rem0[47:16];

            // Stage 2: process bits 47:32, shift partial sums and operands
            valid2     <= valid1;
            carry3_reg <= carry3;
            sum2_reg   <= sum2;
            sum1_reg2  <= sum1_reg;
            sum0_reg2  <= sum0_reg1;
            adda_rem2  <= adda_rem1[31:16];
            addb_rem2  <= addb_rem1[31:16];

            // Stage 3: final chunk (bits 63:48), final carry, and assemble delayed sums
            valid3     <= valid2;
            carry4_reg <= carry4;
            sum3_reg   <= sum3;
            sum2_reg3  <= sum2_reg;
            sum1_reg3  <= sum1_reg2;
            sum0_reg3  <= sum0_reg2;
        end
    end

    // --------------------------------------------------------------
    // Outputs: 65-bit result and pipelined enable
    // --------------------------------------------------------------
    assign result = {carry4_reg, sum3_reg, sum2_reg3, sum1_reg3, sum0_reg3};
    assign o_en   = valid3;

endmodule