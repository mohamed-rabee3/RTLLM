module alu (
    input  wire [31:0] a,
    input  wire [31:0] b,
    input  wire [5:0]  aluc,
    output reg  [31:0] r,
    output reg         zero,
    output reg         carry,
    output reg         negative,
    output reg         overflow,
    output reg         flag
);

    // Operation parameters
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

    // Signed versions of inputs for signed operations
    wire signed [31:0] sa = a;
    wire signed [31:0] sb = b;

    // Internal result register with extra bit for carry
    reg [32:0] res;

    always @(*) begin
        // Default values for outputs in case of unknown aluc
        r        = 32'bz;
        carry    = 1'bz;
        overflow = 1'bz;
        flag     = 1'bz;
        res      = 33'bz;

        case (aluc)
            ADD: begin
                res = {1'b0, a} + {1'b0, b};
                r = res[31:0];
                carry = res[32];
                // Signed overflow: signs of operands and result
                overflow = (a[31] & b[31] & ~r[31]) | (~a[31] & ~b[31] & r[31]);
            end

            ADDU: begin
                res = {1'b0, a} + {1'b0, b};
                r = res[31:0];
                carry = res[32];
                overflow = 1'b0;
            end

            SUB: begin
                res = {1'b0, a} - {1'b0, b};
                r = res[31:0];
                carry = res[32];
                // Signed overflow for subtraction
                overflow = (a[31] & ~b[31] & ~r[31]) | (~a[31] & b[31] & r[31]);
            end

            SUBU: begin
                res = {1'b0, a} - {1'b0, b};
                r = res[31:0];
                carry = res[32];
                overflow = 1'b0;
            end

            AND: begin
                r = a & b;
                carry = 1'b0;
                overflow = 1'b0;
            end

            OR: begin
                r = a | b;
                carry = 1'b0;
                overflow = 1'b0;
            end

            XOR: begin
                r = a ^ b;
                carry = 1'b0;
                overflow = 1'b0;
            end

            NOR: begin
                r = ~(a | b);
                carry = 1'b0;
                overflow = 1'b0;
            end

            SLT: begin
                if (sa < sb)
                    r = 32'd1;
                else
                    r = 32'd0;
                carry = 1'b0;
                overflow = 1'b0;
            end

            SLTU: begin
                if (a < b)
                    r = 32'd1;
                else
                    r = 32'd0;
                carry = 1'b0;
                overflow = 1'b0;
            end

            SLL: begin
                r = b << a[4:0];
                carry = 1'b0;
                overflow = 1'b0;
            end

            SRL: begin
                r = b >> a[4:0];
                carry = 1'b0;
                overflow = 1'b0;
            end

            SRA: begin
                r = $signed(b) >>> a[4:0];
                carry = 1'b0;
                overflow = 1'b0;
            end

            SLLV: begin
                r = b << a[4:0];
                carry = 1'b0;
                overflow = 1'b0;
            end

            SRLV: begin
                r = b >> a[4:0];
                carry = 1'b0;
                overflow = 1'b0;
            end

            SRAV: begin
                r = $signed(b) >>> a[4:0];
                carry = 1'b0;
                overflow = 1'b0;
            end

            LUI: begin
                // Upper 16 bits of 'a' concatenated with 16 zeros
                r = {a[31:16], 16'b0};
                carry = 1'b0;
                overflow = 1'b0;
            end

            default: begin
                r = 32'bz;
                carry = 1'bz;
                overflow = 1'bz;
                flag = 1'bz;  // will also be set below but keeps consistency
                // zero and negative will be derived from r (which is 'z')
            end
        endcase

        // Zero flag: 1 if result is all zeros, else 0
        zero = (r == 32'b0) ? 1'b1 : 1'b0;

        // Negative flag: MSB of result
        negative = r[31];

        // Flag output: result bit for SLT/SLTU, high-impedance otherwise
        if ((aluc == SLT) || (aluc == SLTU))
            flag = r[0];
        else
            flag = 1'bz;
    end

endmodule