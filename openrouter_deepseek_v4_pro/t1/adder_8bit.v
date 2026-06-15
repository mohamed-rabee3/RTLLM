// Full adder module
module full_adder (
    input  a,
    input  b,
    input  cin,
    output sum,
    output cout
);
    assign sum  = a ^ b ^ cin;
    assign cout = (a & b) | (a & cin) | (b & cin);
endmodule

// 8-bit adder using a chain of full adders
module adder_8bit (
    input  [7:0] a,
    input  [7:0] b,
    input        cin,
    output [7:0] sum,
    output       cout
);
    wire [8:0] carry;   // carry[0] = cin, carry[8] = cout
    assign carry[0] = cin;

    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : bit_adder
            full_adder fa (
                .a   (a[i]),
                .b   (b[i]),
                .cin (carry[i]),
                .sum (sum[i]),
                .cout(carry[i+1])
            );
        end
    endgenerate

    assign cout = carry[8];
endmodule