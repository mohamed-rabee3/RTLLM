module alu(
    input  [31:0] a,
    input  [31:0] b,
    input  [5:0]  aluc,
    output [31:0] r,
    output        zero,
    output        carry,
    output        negative,
    output        overflow,
    output        flag
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

    wire signed [31:0] sa = a;
    wire signed [31:0] sb = b;

    reg [31:0] res;
    reg        carry_r;
    reg        overflow_r;
    reg        flag_r;

    wire [32:0] add_ext = {1'b0, a} + {1'b0, b};
    wire [32:0] sub_ext = {1'b0, a} - {1'b0, b};

    always @(*) begin
        res        = 32'bz;
        carry_r    = 1'b0;
        overflow_r = 1'b0;
        flag_r     = 1'b0;

        case (aluc)
            ADD: begin
                res        = a + b;
                carry_r    = add_ext[32];
                overflow_r = (a[31] == b[31]) && (res[31] != a[31]);
            end
            ADDU: begin
                res     = a + b;
                carry_r = add_ext[32];
            end
            SUB: begin
                res        = a - b;
                carry_r    = sub_ext[32];
                overflow_r = (a[31] != b[31]) && (res[31] != a[31]);
            end
            SUBU: begin
                res     = a - b;
                carry_r = sub_ext[32];
            end
            AND:  res = a & b;
            OR:   res = a | b;
            XOR:  res = a ^ b;
            NOR:  res = ~(a | b);
            SLT: begin
                res    = (sa < sb) ? 32'd1 : 32'd0;
                flag_r = res[0];
            end
            SLTU: begin
                res    = (a < b) ? 32'd1 : 32'd0;
                flag_r = res[0];
            end
            SLL:  res = b << a[4:0];
            SRL:  res = b >> a[4:0];
            SRA:  res = sb >>> a[4:0];
            SLLV: res = b << a[4:0];
            SRLV: res = b >> a[4:0];
            SRAV: res = sb >>> a[4:0];
            LUI:  res = {a[15:0], 16'b0};
            default: res = 32'bz;
        endcase
    end

    assign r        = res;
    assign zero     = (res == 32'b0);
    assign negative = res[31];
    assign carry    = carry_r;
    assign overflow = overflow_r;
    assign flag     = (aluc == SLT || aluc == SLTU) ? flag_r : 1'bz;

endmodule
