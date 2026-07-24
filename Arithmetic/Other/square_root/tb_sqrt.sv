`timescale 1ns/1ps

module tb_sqrt();

/////////////////////////////////////////////////
// DUT signals
/////////////////////////////////////////////////

logic [15:0] value;
logic [7:0]  result;

/////////////////////////////////////////////////
// DUT instantiation
/////////////////////////////////////////////////

SQRT dut (
    .value(value),
    .result(result)
);

/////////////////////////////////////////////////
// Golden reference function
/////////////////////////////////////////////////

function automatic int golden_sqrt(input int v);

    golden_sqrt = $floor($sqrt(v));

endfunction

/////////////////////////////////////////////////
// Scoreboard task
/////////////////////////////////////////////////

task check_result(input int val);

    int expected;

    value = val;

    #1;   // allow combinational propagation

    expected = golden_sqrt(val);

    if(result !== expected) begin
        $error("FAIL: input=%0d expected=%0d got=%0d",
               val, expected, result);
    end
    else begin
        $display("PASS: input=%0d sqrt=%0d",
                 val, result);
    end

endtask

/////////////////////////////////////////////////
// Test stimulus
/////////////////////////////////////////////////

initial begin

    $display("Starting SQRT testbench...");

    repeat (10) begin
        check_result($urandom_range(0,65535));
    end

    $display("Test completed.");
    $finish;

end

endmodule