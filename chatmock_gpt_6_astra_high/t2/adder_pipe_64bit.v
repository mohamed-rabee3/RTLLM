module adder_pipe_64bit (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        i_en,
    input  wire [63:0] adda,
    input  wire [63:0] addb,
    output reg  [64:0] result,
    output wire        o_en
);

    reg [3:0] valid_pipe;

    reg [47:0] a_stage1;
    reg [47:0] b_stage1;
    reg [15:0] sum_stage1;
    reg        carry_stage1;

    reg [31:0] a_stage2;
    reg [31:0] b_stage2;
    reg [31:0] sum_stage2;
    reg        carry_stage2;

    reg [15:0] a_stage3;
    reg [15:0] b_stage3;
    reg [47:0] sum_stage3;
    reg        carry_stage3;

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

    assign o_en = valid_pipe[3];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_pipe   <= 4'b0000;

            a_stage1     <= 48'b0;
            b_stage1     <= 48'b0;
            sum_stage1   <= 16'b0;
            carry_stage1 <= 1'b0;

            a_stage2     <= 32'b0;
            b_stage2     <= 32'b0;
            sum_stage2   <= 32'b0;
            carry_stage2 <= 1'b0;

            a_stage3     <= 16'b0;
            b_stage3     <= 16'b0;
            sum_stage3   <= 48'b0;
            carry_stage3 <= 1'b0;

            result       <= 65'b0;
        end else begin
            valid_pipe <= {valid_pipe[2:0], i_en};

            // Stage 1: bits 15:0.
            a_stage1     <= adda[63:16];
            b_stage1     <= addb[63:16];
            sum_stage1   <= add_stage1[15:0];
            carry_stage1 <= add_stage1[16];

            // Stage 2: bits 31:16.
            a_stage2     <= a_stage1[47:16];
            b_stage2     <= b_stage1[47:16];
            sum_stage2   <= {add_stage2[15:0], sum_stage1};
            carry_stage2 <= add_stage2[16];

            // Stage 3: bits 47:32.
            a_stage3     <= a_stage2[31:16];
            b_stage3     <= b_stage2[31:16];
            sum_stage3   <= {add_stage3[15:0], sum_stage2};
            carry_stage3 <= add_stage3[16];

            // Stage 4: bits 63:48 and final carry.
            result <= {add_stage4, sum_stage3};
        end
    end

endmodule
