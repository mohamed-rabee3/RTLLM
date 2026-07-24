`timescale 1ns / 1ps


module tb_alu_32bit_unsigned();

/////////////////////////////////////////////////
// Parameters
/////////////////////////////////////////////////
parameter NUM_TESTS = 10;
parameter OP_ADD = 2'b00;
parameter OP_MUL = 2'b01;
parameter OP_MIN = 2'b10;

/////////////////////////////////////////////////
// DUT Signals
/////////////////////////////////////////////////
logic [31:0] a;           // 32-bit unsigned input
logic [31:0] b;           // 32-bit unsigned input
logic [1:0]  op;
logic [63:0] result;      // 64-bit output

// DUT output valid (optional - for pipelined implementations)
logic result_valid;
logic [63:0] expected_add;
// Control signals
logic clk;
logic rst;
logic valid_in;

/////////////////////////////////////////////////
// DUT Instantiation
/////////////////////////////////////////////////
alu_32bit_unsigned dut (
    .clk(clk),
    .rst(rst),
    .valid_in(valid_in),
    .a(a),
    .b(b),
    .op(op),
    .result(result),
    .result_valid(result_valid)
);

/////////////////////////////////////////////////
// Clock Generation
/////////////////////////////////////////////////
initial clk = 0;
always #5 clk = ~clk; // 100MHz clock

/////////////////////////////////////////////////
// Test control variables
/////////////////////////////////////////////////
int errors = 0;
int tests_run = 0;
int tests_passed = 0;
int file_handle;
logic [63:0] expected_result;

// Operation names for display
string op_name[] = '{"ADD", "MUL", "MIN", "INVALID"};

/////////////////////////////////////////////////
// Golden Reference Model for UNSIGNED inputs
/////////////////////////////////////////////////
function automatic logic [63:0] golden_alu(
    input logic [31:0] a,
    input logic [31:0] b,
    input logic [1:0]  op
);
    logic [63:0] add_result;
    logic [63:0] mul_result;
    logic [63:0] min_result;
    
    case(op)
        OP_ADD: begin
            // Unsigned addition - zero extend to 64 bits
            add_result = {31'b0, a} + {31'b0, b};
            return add_result;
        end
        
        OP_MUL: begin
            // Unsigned multiplication - 32x32 = 64 bits
            mul_result = a * b;
            return mul_result;
        end
        
        OP_MIN: begin
            // Unsigned minimum - zero extend to 64 bits
            min_result = (a < b) ? {32'b0, a} : {32'b0, b};
            return min_result;
        end
        
        default: return 64'hFFFFFFFFFFFFFFFF; // Error condition
    endcase
endfunction


/////////////////////////////////////////////////
// Scoreboard Task
/////////////////////////////////////////////////
task check_result(
    input logic [31:0] test_a,
    input logic [31:0] test_b,
    input logic [1:0]  test_op,
    input logic [63:0] dut_result,
    input logic [63:0] expected
);
    string dut_str, exp_str;
    
    
    if (dut_result !== expected) begin
        $error("[%0t] MISMATCH: %s(%0d, %0d)", 
                $time, op_name[test_op], test_a, test_b);
        $error("          DUT: %s", dut_str);
        $error("      Expected: %s", exp_str);
        $fwrite(file_handle, "1 "); // Mismatch
        errors++;
    end
    else begin
        $display("[%0t] PASS: %s(%0d, %0d) = %s", 
                 $time, op_name[test_op], test_a, test_b, dut_str);
        $fwrite(file_handle, "0 "); // Match
        tests_passed++;
    end
    tests_run++;
endtask

/////////////////////////////////////////////////
// Test Generation Task
/////////////////////////////////////////////////
task run_test(
    input logic [31:0] test_a,
    input logic [31:0] test_b,
    input logic [1:0]  test_op
);
    @(posedge clk);
    valid_in = 1;
    a = test_a;
    b = test_b;
    op = test_op;
    
    // Wait for result (for pipelined implementations)
       
        begin
            @(posedge result_valid);
            expected_result = golden_alu(test_a, test_b, test_op);
            check_result(test_a, test_b, test_op, result, expected_result);
            
        end
 
    valid_in = 0;
endtask

/////////////////////////////////////////////////
// Random Test Cases (UNSIGNED range)
/////////////////////////////////////////////////
task run_random_tests(input int num_tests);
    logic [31:0] rand_a, rand_b;
    logic [1:0]  rand_op;
    
    $display("\n[%0t] Running %0d Random Tests (UNSIGNED)...", $time, num_tests);
    
    for(int i=0; i<num_tests; i++) begin
        rand_a = $urandom_range(0, 32'hFFFFFFFF);
        rand_b = $urandom_range(0, 32'hFFFFFFFF);
        rand_op = $urandom_range(0, 2); // Only valid ops 0,1,2
        
        run_test(rand_a, rand_b, rand_op);
    end
endtask


/////////////////////////////////////////////////
// Main Test Sequence
/////////////////////////////////////////////////
initial begin
    // Open results file
    file_handle = $fopen("../alu_unsigned_results.txt", "w");
    if (file_handle == 0) begin
        $error("Failed to open results file");
        $finish;
    end
    
       
    // Initial reset
    rst = 1;
    valid_in = 0;
    a = 32'd0;
    b = 32'd0;
    op = OP_ADD;
    
    #20;
    @(posedge clk);
    rst = 0;
    
    $display("[%0t] Reset complete, starting tests...", $time);
    
    // Run all test suites
    run_random_tests(NUM_TESTS);
    
    // Wait for any remaining operations
    repeat(10) @(posedge clk);
    
    // Close results file
    $fclose(file_handle);
    
    // Summary report
    $display("\n=========================================================");
    $display("TEST SUMMARY");
    $display("=========================================================");
    $display("Tests Run    : %0d", tests_run);
    $display("Tests Passed : %0d", tests_passed);
    $display("Tests Failed : %0d", errors);
    $display("=========================================================");
    
    if (errors == 0) begin
        $display("===========Your Design Passed===========");
    end
    else begin
        $display("===========Error===========");
    end
    $display("=========================================================\n");
    
    $finish;
end

endmodule