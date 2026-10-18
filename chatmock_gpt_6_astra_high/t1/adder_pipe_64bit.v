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

    reg [47:0] a_s1;
    reg [47:0] b_s1;
    reg [16:0] sum_s1;

    reg [31:0] a_s2;
    reg [31:0] b_s2;
    reg [32:0] sum_s2;

    reg [15:0] a_s3;
    reg [15:0] b_s3;
    reg [48:0] sum_s3;

    wire [16:0] add_s1;
    wire [16:0] add_s2;
    wire [16:0] add_s3;
    wire [16:0] add_s4;

    assign add_s1 = {1'b0, adda[15:0]}
                  + {1'b0, addb[15:0]};

    assign add_s2 = {1'b0, a_s1[15:0]}
                  + {1'b0, b_s1[15:0]}
                  + {{16{1'b0}}, sum_s1[16]};

    assign add_s3 = {1'b0, a_s2[15:0]}
                  + {1'b0, b_s2[15:0]}
                  + {{16{1'b0}}, sum_s2[32]};

    assign add_s4 = {1'b0, a_s3}
                  + {1'b0, b_s3}
                  + {{16{1'b0}}, sum_s3[48]};

    assign o_en = valid_pipe[3];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_pipe <= 4'b0000;

            a_s1   <= 48'b0;
            b_s1   <= 48'b0;
            sum_s1 <= 17'b0;

            a_s2   <= 32'b0;
            b_s2   <= 32'b0;
            sum_s2 <= 33'b0;

            a_s3   <= 16'b0;
            b_s3   <= 16'b0;
            sum_s3 <= 49'b0;

            result <= 65'b0;
        end else begin
            valid_pipe <= {valid_pipe[2:0], i_en};

            // Stage 1: bits 15:0.
            a_s1   <= adda[63:16];
            b_s1   <= addb[63:16];
            sum_s1 <= add_s1;

            // Stage 2: bits 31:16 and delayed lower sum.
            a_s2   <= a_s1[47:16];
            b_s2   <= b_s1[47:16];
            sum_s2 <= {add_s2, sum_s1[15:0]};

            // Stage 3: bits 47:32 and delayed lower sum.
            a_s3   <= a_s2[31:16];
            b_s3   <= b_s2[31:16];
            sum_s3 <= {add_s3, sum_s2[31:0]};

            // Stage 4: bits 63:48, final carry, and lower sum.
            result <= {add_s4, sum_s3[47:0]};
        end
    end

endmodule
