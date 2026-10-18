module alu (
    input  wire [31:0] a,
    input  wire [31:0] b,
    input  wire [5:0]  aluc,
    output wire [31:0] r,
    output wire        zero,
    output wire        carry,
    output wire        negative,
    output reg         overflow,
    output wire        flag
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
    reg         [32:0] res;

    assign signed_a = a;
    assign signed_b = b;

    assign r        = res[31:0];
    assign zero     = (r == 32'b0);
    assign carry    = res[32];
    assign negative = r[31];
    assign flag     = ((aluc == SLT) || (aluc == SLTU))
                    ? 1'b1 : 1'bz;

    always @* begin
        res      = 33'b0;
        overflow = 1'b0;

        case (aluc)
            ADD: begin
                res = {1'b0, a} + {1'b0, b};
                overflow = (~(a[31] ^ b[31])) &
                           (res[31] ^ a[31]);
            end

            ADDU: begin
                res = {1'b0, a} + {1'b0, b};
            end

            SUB: begin
                res = {1'b0, a} - {1'b0, b};
                overflow = (a[31] ^ b[31]) &
                           (res[31] ^ a[31]);
            end

            SUBU: begin
                res = {1'b0, a} - {1'b0, b};
            end

            AND: begin
                res = {1'b0, (a & b)};
            end

            OR: begin
                res = {1'b0, (a | b)};
            end

            XOR: begin
                res = {1'b0, (a ^ b)};
            end

            NOR: begin
                res = {1'b0, ~(a | b)};
            end

            SLT: begin
                res = {32'b0, (signed_a < signed_b)};
            end

            SLTU: begin
                res = {32'b0, (a < b)};
            end

            SLL: begin
                res = {1'b0, b} << a;
            end

            SRL: begin
                res = {1'b0, b} >> a;
            end

            SRA: begin
                res = {1'b0, (signed_b >>> a)};
            end

            SLLV: begin
                res = {1'b0, b} << a[4:0];
            end

            SRLV: begin
                res = {1'b0, b} >> a[4:0];
            end

            SRAV: begin
                res = {1'b0, (signed_b >>> a[4:0])};
            end

            LUI: begin
                res = {1'b0, a[31:16], 16'b0};
            end

            default: begin
                res = {33{1'bz}};
            end
        endcase
    end

endmodule
