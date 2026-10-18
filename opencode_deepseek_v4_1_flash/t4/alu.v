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

    parameter ADD   = 6'b100000;
    parameter ADDU  = 6'b100001;
    parameter SUB   = 6'b100010;
    parameter SUBU  = 6'b100011;
    parameter AND   = 6'b100100;
    parameter OR    = 6'b100101;
    parameter XOR   = 6'b100110;
    parameter NOR   = 6'b100111;
    parameter SLT   = 6'b101010;
    parameter SLTU  = 6'b101011;
    parameter SLL   = 6'b000000;
    parameter SRL   = 6'b000010;
    parameter SRA   = 6'b000011;
    parameter SLLV  = 6'b000100;
    parameter SRLV  = 6'b000110;
    parameter SRAV  = 6'b000111;
    parameter LUI   = 6'b001111;

    wire signed [31:0] a_s;
    wire signed [31:0] b_s;
    assign a_s = a;
    assign b_s = b;

    reg [32:0] res;
    wire [31:0] r_int;
    assign r_int = res[31:0];

    assign r        = r_int;
    assign zero     = (r_int == 32'b0);
    assign carry    = res[32];
    assign negative = res[31];

    wire ov_add = (a[31] == b[31]) && (r_int[31] != a[31]);
    wire ov_sub = (a[31] != b[31]) && (r_int[31] != a[31]);
    assign overflow = (aluc == ADD) ? ov_add :
                      (aluc == SUB) ? ov_sub : 1'b0;

    assign flag = (aluc == SLT || aluc == SLTU) ? res[0] : 1'bz;

    always @(*) begin
        case (aluc)
            ADD:    res = {1'b0, a} + {1'b0, b};
            ADDU:   res = {1'b0, a} + {1'b0, b};
            SUB:    res = {1'b0, a} + {1'b0, ~b} + 33'd1;
            SUBU:   res = {1'b0, a} + {1'b0, ~b} + 33'd1;
            AND:    res = {1'b0, a & b};
            OR:     res = {1'b0, a | b};
            XOR:    res = {1'b0, a ^ b};
            NOR:    res = {1'b0, ~(a | b)};
            SLT:    res = {32'b0, (a_s < b_s)};
            SLTU:   res = {32'b0, (a < b)};
            SLL:    res = {1'b0, b << a[4:0]};
            SRL:    res = {1'b0, b >> a[4:0]};
            SRA:    res = {1'b0, b_s >>> a[4:0]};
            SLLV:   res = {1'b0, b << a[4:0]};
            SRLV:   res = {1'b0, b >> a[4:0]};
            SRAV:   res = {1'b0, b_s >>> a[4:0]};
            LUI:    res = {1'b0, a[15:0], 16'b0};
            default: res = 33'bz;
        endcase
    end

endmodule
