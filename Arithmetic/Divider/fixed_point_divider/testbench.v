`timescale 1ns / 1ps

module tb_fixed_point_divider();
logic signed [15:0] dividend;
logic signed [15:0] divisor;
logic signed [15:0] quotient;
logic signed [15:0] golden;

int errors = 0;

divider dut (
    .dividend(dividend),
    .divisor(divisor),
    .quotient(quotient)
);

function automatic logic signed [15:0] golden_divide
(
    input logic signed [15:0] dividend,
    input logic signed [15:0] divisor
);

    logic signed [31:0] temp;

    if (divisor == 0) begin
        golden_divide = 16'hFFFF;
    end
    else begin
        temp = (dividend <<< 7);  //It converts the integer division into fixed-point division.
        golden_divide = temp / divisor;
    end

endfunction


task check_result(input logic signed [15:0] a,
                  input logic signed [15:0] b);

    dividend = a;
    divisor  = b;

    #1;

    golden = golden_divide(a,b);

    if (quotient !== golden) begin
        $display("ERROR: %0d / %0d -> DUT=%0d Expected=%0d",
                 a,b,quotient,golden);
        errors++;
    end
    else begin
        $display("PASS: %0d / %0d -> %0d",
                 a,b,quotient);
    end

endtask


initial begin

    repeat (10) begin
        check_result($urandom_range(-32768,32767),
                     $urandom_range(-32768,32767));
    end

    $display("Total errors = %0d", errors);

    if (errors == 0)
        $display("===========Your Design Passed===========");
    else
        $display("===========Error===========");

    $finish;

end

endmodule
