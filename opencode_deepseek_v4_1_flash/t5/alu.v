module alu(
    input [31:0] a,
    input [31:0] b,
    input [5:0] aluc,
    output reg [31:0] r,
    output zero,
    output reg carry,
    output negative,
    output reg overflow,
    output reg flag
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

    wire signed [31:0] a_signed = a;
    wire signed [31:0] b_signed = b;

    reg [32:0] res;

    assign zero = (r == 32'b0);
    assign negative = r[31];

    always @(*) begin
        res = 33'b0;
        carry = 1'b0;
        overflow = 1'b0;
        flag = 1'bz;

        case (aluc)
            ADD: begin
                res = {1'b0, a} + {1'b0, b};
                carry = res[32];
                overflow = (a[31] == b[31]) && (res[31] != a[31]);
            end
            ADDU: begin
                res = {1'b0, a} + {1'b0, b};
                carry = res[32];
            end
            SUB: begin
                res = {1'b0, a} - {1'b0, b};
                carry = res[32];
                overflow = (a[31] != b[31]) && (res[31] != a[31]);
            end
            SUBU: begin
                res = {1'b0, a} - {1'b0, b};
                carry = res[32];
            end
            AND: begin
                res = {1'b0, a & b};
            end
            OR: begin
                res = {1'b0, a | b};
            end
            XOR: begin
                res = {1'b0, a ^ b};
            end
            NOR: begin
                res = {1'b0, ~(a | b)};
            end
            SLT: begin
                res = {32'b0, (a_signed < b_signed)};
                flag = res[0];
            end
            SLTU: begin
                res = {32'b0, (a < b)};
                flag = res[0];
            end
            SLL: begin
                res = {1'b0, b << a[4:0]};
            end
            SRL: begin
                res = {1'b0, b >> a[4:0]};
            end
            SRA: begin
                res = {1'b0, $signed(b) >>> a[4:0]};
            end
            SLLV: begin
                res = {1'b0, b << a[4:0]};
            end
            SRLV: begin
                res = {1'b0, b >> a[4:0]};
            end
            SRAV: begin
                res = {1'b0, $signed(b) >>> a[4:0]};
            end
            LUI: begin
                res = {1'b0, a[15:0], 16'b0};
            end
            default: begin
                res = 33'bz;
            end
        endcase

        r = res[31:0];
    end

endmodule
