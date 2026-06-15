module LIFObuffer (
    input [3:0] dataIn,
    input RW,
    input EN,
    input Rst,
    input Clk,
    output EMPTY,
    output FULL,
    output reg [3:0] dataOut
);

    // Stack memory: 4 locations, each 4-bit wide
    reg [3:0] stack_mem [0:3];

    // Stack pointer: 0 = full, 4 = empty
    reg [2:0] sp;

    // EMPTY and FULL flags derived from stack pointer
    assign EMPTY = (sp == 3'd4);
    assign FULL  = (sp == 3'd0);

    integer i;

    always @(posedge Clk) begin
        if (EN) begin
            if (Rst) begin
                // Reset: clear memory, set pointer to empty, clear output
                sp <= 3'd4;
                for (i = 0; i < 4; i = i + 1) begin
                    stack_mem[i] <= 4'b0;
                end
                dataOut <= 4'b0;
            end else begin
                // Write (push) operation
                if ((RW == 1'b0) && (sp != 3'd0)) begin
                    sp <= sp - 1;
                    stack_mem[sp - 1] <= dataIn;
                end
                // Read (pop) operation
                else if ((RW == 1'b1) && (sp != 3'd4)) begin
                    dataOut <= stack_mem[sp];
                    stack_mem[sp] <= 4'b0;   // clear the popped location
                    sp <= sp + 1;
                end
                // If RW=0 and full, or RW=1 and empty, do nothing
            end
        end
    end

endmodule