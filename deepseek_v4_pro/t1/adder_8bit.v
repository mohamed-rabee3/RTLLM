module adder_8bit (
    input  [7:0] a,
    input  [7:0] b,
    input        cin,
    output [7:0] sum,
    output       cout
);
    // internal carry chain
    wire [8:0] c;
    assign c[0] = cin;

    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : bit_adder
            // Full adder logic for each bit
            assign sum[i] = a[i] ^ b[i] ^ c[i];
            assign c[i+1]  = (a[i] & b[i]) | (b[i] & c[i]) | (a[i] & c[i]);
        end
    endgenerate

    assign cout = c[8];
endmodule