`timescale 1ns / 1ps

module tb_mul_fast();
logic [15:0] a;
logic [15:0] b;
logic [31:0] result;
logic [31:0] golden;

int errors = 0;

mul_fast dut (
    .a(a),
    .b(b),
    .result(result)
);


function automatic logic [31:0] golden_mul
(
    input logic [15:0] a,
    input logic [15:0] b
);

        golden_mul = a * b;

endfunction




task check_result(input logic [15:0] a1,
                  input logic [15:0] b1);

    a = a1;
    b = b1;

    #1;

    golden = golden_mul(a1,b1);

    if (result !== golden) begin
        $display("ERROR: %0d * %0d -> DUT=%0d Expected=%0d",
                 a,b,result,golden);
        errors++;
    end
    else begin
        $display("PASS: %0d * %0d -> %0d",
                 a,b,result);
    end

endtask


initial begin

    repeat (10) begin
        check_result($urandom_range(0,65535),
                     $urandom_range(0,65535));
    end

    $display("Total errors = %0d", errors);

    if (errors == 0)
        $display("===========Your Design Passed===========");
    else
        $display("===========Error===========");

    $finish;

end

endmodule
