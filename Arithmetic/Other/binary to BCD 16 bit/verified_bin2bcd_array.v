module verified_bin2bcd_array(
    input             clk,
    input             rst,
    input             valid_in,
    input      [15:0] binary_in,
    output reg [19:0] bcd_out,
    output reg        valid_out
);
    // double-dabble (shift-add-3) 16-bit binary -> 5-digit BCD
    function [19:0] to_bcd;
        input [15:0] bin;
        integer i;
        reg [35:0] shift;   // [15:0]=binary, [35:16]=5 BCD nibbles
        begin
            shift = 36'd0;
            shift[15:0] = bin;
            for (i = 0; i < 16; i = i + 1) begin
                if (shift[19:16] >= 5) shift[19:16] = shift[19:16] + 3;
                if (shift[23:20] >= 5) shift[23:20] = shift[23:20] + 3;
                if (shift[27:24] >= 5) shift[27:24] = shift[27:24] + 3;
                if (shift[31:28] >= 5) shift[31:28] = shift[31:28] + 3;
                if (shift[35:32] >= 5) shift[35:32] = shift[35:32] + 3;
                shift = shift << 1;
            end
            to_bcd = shift[35:16];
        end
    endfunction

    always @(posedge clk) begin
        if (rst) begin
            bcd_out   <= 20'd0;
            valid_out <= 1'b0;
        end else begin
            valid_out <= valid_in;
            if (valid_in)
                bcd_out <= to_bcd(binary_in);
        end
    end
endmodule
