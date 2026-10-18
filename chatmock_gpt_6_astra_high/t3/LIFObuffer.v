module LIFObuffer (
    input  wire [3:0] dataIn,
    input  wire       RW,
    input  wire       EN,
    input  wire       Rst,
    input  wire       Clk,
    output wire       EMPTY,
    output wire       FULL,
    output reg  [3:0] dataOut
);

    reg [3:0] stack_mem [0:3];
    reg [2:0] SP;
    integer i;

    assign EMPTY = (SP == 3'd4);
    assign FULL  = (SP == 3'd0);

    always @(posedge Clk) begin
        if (EN) begin
            if (Rst) begin
                SP      <= 3'd4;
                dataOut <= 4'd0;
                for (i = 0; i < 4; i = i + 1) begin
                    stack_mem[i] <= 4'd0;
                end
            end else begin
                if (!RW && !FULL) begin
                    stack_mem[SP - 3'd1] <= dataIn;
                    SP <= SP - 3'd1;
                end else if (RW && !EMPTY) begin
                    dataOut       <= stack_mem[SP];
                    stack_mem[SP] <= 4'd0;
                    SP            <= SP + 3'd1;
                end
            end
        end
    end

endmodule
