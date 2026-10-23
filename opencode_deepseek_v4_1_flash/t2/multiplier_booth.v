module mul_booth(
    input  [15:0] a,
    input  [15:0] b,
    output [31:0] result
);

    wire [31:0] a_ext = {16'b0, a};
    wire [16:0] bx = {b, 1'b0};

    function [31:0] booth_pp;
        input [2:0] code;
        input [31:0] a_val;
        begin
            case (code)
                3'b000, 3'b111: booth_pp = 32'd0;
                3'b001, 3'b010: booth_pp = a_val;
                3'b011: booth_pp = a_val << 1;
                3'b100: booth_pp = -(a_val << 1);
                3'b101, 3'b110: booth_pp = -a_val;
                default: booth_pp = 32'd0;
            endcase
        end
    endfunction

    wire [31:0] pp0 = booth_pp({bx[2],  bx[1],  bx[0]},  a_ext);
    wire [31:0] pp1 = booth_pp({bx[4],  bx[3],  bx[2]},  a_ext);
    wire [31:0] pp2 = booth_pp({bx[6],  bx[5],  bx[4]},  a_ext);
    wire [31:0] pp3 = booth_pp({bx[8],  bx[7],  bx[6]},  a_ext);
    wire [31:0] pp4 = booth_pp({bx[10], bx[9],  bx[8]},  a_ext);
    wire [31:0] pp5 = booth_pp({bx[12], bx[11], bx[10]}, a_ext);
    wire [31:0] pp6 = booth_pp({bx[14], bx[13], bx[12]}, a_ext);
    wire [31:0] pp7 = booth_pp({bx[16], bx[15], bx[14]}, a_ext);

    wire [31:0] correction = b[15] ? {a, 16'b0} : 32'd0;

    assign result = pp0
                  + (pp1 << 2)
                  + (pp2 << 4)
                  + (pp3 << 6)
                  + (pp4 << 8)
                  + (pp5 << 10)
                  + (pp6 << 12)
                  + (pp7 << 14)
                  + correction;

endmodule
