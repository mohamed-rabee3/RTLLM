module alu(
    input [31:0] a,
    input [31:0] b,
    input [5:0] aluc,
    output [31:0] r,
    output zero,
    output carry,
    output negative,
    output overflow,
    output flag
);

parameter ADD  = 6'b100000;
parameter ADDU = 6'b100001;
parameter SUB  = 6'b100010;
parameter SUBU = 6'b100011;
parameter AND  = 6'b100100;
parameter OR   = 6'b100101;
parameter XOR  = 6'b100110;
parameter NOR  = 6'b100111;
parameter SLT  = 6'b101010;
parameter SLTU = 6'b101011;
parameter SLL  = 6'b000000;
parameter SRL  = 6'b000010;
parameter SRA  = 6'b000011;
parameter SLLV = 6'b000100;
parameter SRLV = 6'b000110;
parameter SRAV = 6'b000111;
parameter LUI  = 6'b001111;

wire signed [31:0] signed_a;
wire signed [31:0] signed_b;
assign signed_a = a;
assign signed_b = b;

reg [32:0] res;
reg overflow_reg;

assign r        = res[31:0];
assign zero     = (res[31:0] == 32'b0) ? 1'b1 : 1'b0;
assign carry    = res[32];
assign negative = res[31];
assign overflow = overflow_reg;
assign flag     = (aluc == SLT || aluc == SLTU) ? res[0] : 1'bz;

always @(*) begin
    res = 33'b0;
    overflow_reg = 1'b0;

    case (aluc)
        ADD: begin
            {res[32], res[31:0]} = {1'b0, a} + {1'b0, b};
            overflow_reg = (a[31] == b[31]) && (res[31] != a[31]);
        end

        ADDU: begin
            {res[32], res[31:0]} = {1'b0, a} + {1'b0, b};
        end

        SUB: begin
            {res[32], res[31:0]} = {1'b0, a} + {1'b0, ~b} + 1'b1;
            overflow_reg = (a[31] != b[31]) && (res[31] != a[31]);
        end

        SUBU: begin
            {res[32], res[31:0]} = {1'b0, a} + {1'b0, ~b} + 1'b1;
        end

        AND: begin
            res[31:0] = a & b;
        end

        OR: begin
            res[31:0] = a | b;
        end

        XOR: begin
            res[31:0] = a ^ b;
        end

        NOR: begin
            res[31:0] = ~(a | b);
        end

        SLT: begin
            res[31:0] = (signed_a < signed_b) ? 32'd1 : 32'd0;
        end

        SLTU: begin
            res[31:0] = (a < b) ? 32'd1 : 32'd0;
        end

        SLL: begin
            res[31:0] = b << a[4:0];
        end

        SRL: begin
            res[31:0] = b >> a[4:0];
        end

        SRA: begin
            res[31:0] = signed_b >>> a[4:0];
        end

        SLLV: begin
            res[31:0] = b << a[4:0];
        end

        SRLV: begin
            res[31:0] = b >> a[4:0];
        end

        SRAV: begin
            res[31:0] = signed_b >>> a[4:0];
        end

        LUI: begin
            res[31:0] = {a[15:0], 16'b0};
        end

        default: begin
            res = 33'bz;
        end
    endcase
end

endmodule
