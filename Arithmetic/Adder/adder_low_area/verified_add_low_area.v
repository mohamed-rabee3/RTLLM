module verified_add_low_area(
    input  [15:0] a,
    input  [15:0] b,
    output [16:0] result
);
    wire [16:0] c;
    assign c[0] = 1'b0;
    genvar i;
    generate for (i = 0; i < 16; i = i + 1) begin : fa
        assign result[i] = a[i] ^ b[i] ^ c[i];
        assign c[i+1]    = (a[i] & b[i]) | (a[i] & c[i]) | (b[i] & c[i]);
    end endgenerate
    assign result[16] = c[16];
endmodule
