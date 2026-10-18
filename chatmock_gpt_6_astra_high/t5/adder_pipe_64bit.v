module adder_pipe_64bit (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        i_en,
    input  wire [63:0] adda,
    input  wire [63:0] addb,
    output reg  [64:0] result,
    output reg         o_en
);

    // Four pipeline stages, each adding sixteen bits.
    reg [47:0] a_stage1, b_stage1;
    reg [31:0] a_stage2, b_stage2;
    reg [15:0] a_stage3, b_stage3;

    reg [15:0] sum_stage1;
    reg [31:0] sum_stage2;
    reg [47:0] sum_stage3;

    reg carry_stage1;
    reg carry_stage2;
    reg carry_stage3;

    reg en_stage1;
    reg en_stage2;
    reg en_stage3;

    wire [16:0] add_stage1;
    wire [16:0] add_stage2;
    wire [16:0] add_stage3;
    wire [16:0] add_stage4;

    assign add_stage1 = {1'b0, adda[15:0]}
                      + {1'b0, addb[15:0]};

    assign add_stage2 = {1'b0, a_stage1[15:0]}
                      + {1'b0, b_stage1[15:0]}
                      + {16'b0, carry_stage1};

    assign add_stage3 = {1'b0, a_stage2[15:0]}
                      + {1'b0, b_stage2[15:0]}
                      + {16'b0, carry_stage2};

    assign add_stage4 = {1'b0, a_stage3}
                      + {1'b0, b_stage3}
                      + {16'b0, carry_stage3};

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_stage1     <= 48'b0;
            b_stage1     <= 48'b0;
            a_stage2     <= 32'b0;
            b_stage2     <= 32'b0;
            a_stage3     <= 16'b0;
            b_stage3     <= 16'b0;

            sum_stage1   <= 16'b0;
            sum_stage2   <= 32'b0;
            sum_stage3   <= 48'b0;

            carry_stage1 <= 1'b0;
            carry_stage2 <= 1'b0;
            carry_stage3 <= 1'b0;

            en_stage1    <= 1'b0;
            en_stage2    <= 1'b0;
            en_stage3    <= 1'b0;

            result       <= 65'b0;
            o_en         <= 1'b0;
        end else begin
            // Stage 1: bits 15:0.
            a_stage1     <= adda[63:16];
            b_stage1     <= addb[63:16];
            sum_stage1   <= add_stage1[15:0];
            carry_stage1 <= add_stage1[16];
            en_stage1    <= i_en;

            // Stage 2: bits 31:16.
            a_stage2     <= a_stage1[47:16];
            b_stage2     <= b_stage1[47:16];
            sum_stage2   <= {add_stage2[15:0], sum_stage1};
            carry_stage2 <= add_stage2[16];
            en_stage2    <= en_stage1;

            // Stage 3: bits 47:32.
            a_stage3     <= a_stage2[31:16];
            b_stage3     <= b_stage2[31:16];
            sum_stage3   <= {add_stage3[15:0], sum_stage2};
            carry_stage3 <= add_stage3[16];
            en_stage3    <= en_stage2;

            // Stage 4: bits 63:48 and final carry.
            result       <= {add_stage4, sum_stage3};
            o_en         <= en_stage3;
        end
    end

endmodule
