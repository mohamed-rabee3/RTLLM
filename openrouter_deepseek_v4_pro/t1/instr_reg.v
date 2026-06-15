module instr_reg (
    input wire clk,
    input wire rst,
    input wire [1:0] fetch,
    input wire [7:0] data,
    output wire [2:0] ins,
    output wire [4:0] ad1,
    output wire [7:0] ad2
);

    // Internal 8-bit registers
    reg [7:0] ins_p1;
    reg [7:0] ins_p2;

    // Sequential logic for register updates
    always @(posedge clk) begin
        if (!rst) begin
            // Active low reset: clear both registers
            ins_p1 <= 8'd0;
            ins_p2 <= 8'd0;
        end else begin
            case (fetch)
                2'b01: ins_p1 <= data;  // fetch from register source
                2'b10: ins_p2 <= data;  // fetch from RAM/ROM source
                default: begin
                    // retain previous values
                    ins_p1 <= ins_p1;
                    ins_p2 <= ins_p2;
                end
            endcase
        end
    end

    // Output assignments derived from stored instructions
    // ins: opcode (high 3 bits of ins_p1)
    assign ins = ins_p1[7:5];
    // ad1: register address (low 5 bits of ins_p1)
    assign ad1 = ins_p1[4:0];
    // ad2: full 8-bit data from second source (ins_p2)
    assign ad2 = ins_p2;

endmodule