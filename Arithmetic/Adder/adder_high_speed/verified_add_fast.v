module verified_add_fast(
    input  [15:0] a,
    input  [15:0] b,
    output [16:0] result
);
    wire [8:0] lo  = {1'b0, a[7:0]}  + {1'b0, b[7:0]};
    wire [8:0] hi0 = {1'b0, a[15:8]} + {1'b0, b[15:8]};        // carry-in = 0
    wire [8:0] hi1 = {1'b0, a[15:8]} + {1'b0, b[15:8]} + 9'd1; // carry-in = 1
    wire [8:0] hi  = lo[8] ? hi1 : hi0;                        // select by low carry
    assign result = {hi, lo[7:0]};
endmodule
