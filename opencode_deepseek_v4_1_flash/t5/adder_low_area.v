module full_adder(
    input  a,
    input  b,
    input  cin,
    output sum,
    output cout
);
    assign sum  = a ^ b ^ cin;
    assign cout = (a & b) | (b & cin) | (a & cin);
endmodule

module add_low_area(
    input  [15:0] a,
    input  [15:0] b,
    output [16:0] result
);
    wire [16:0] carry;

    assign carry[0] = 1'b0;

    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : fa_chain
            full_adder fa (
                .a(a[i]),
                .b(b[i]),
                .cin(carry[i]),
                .sum(result[i]),
                .cout(carry[i+1])
            );
        end
    endgenerate

    assign result[16] = carry[16];
endmodule
