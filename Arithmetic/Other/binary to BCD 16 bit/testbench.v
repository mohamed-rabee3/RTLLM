`timescale 1ns / 1ps

module tb_bin2bcd();

/////////////////////////////////////////////////
// Parameters
/////////////////////////////////////////////////
parameter NUM_RANDOM_TESTS = 10;


/////////////////////////////////////////////////
// DUT Signals
/////////////////////////////////////////////////
logic [15:0] binary_in;
logic [19:0]  bcd_out; // Array for 5 BCD digits
logic        valid_out;

// Control signals
logic clk;
logic rst;
logic valid_in;

/////////////////////
// DUT Instantiation 
////////////////////


bin2bcd_array dut (
    .clk(clk),
    .rst(rst),
    .valid_in(valid_in),
    .binary_in(binary_in),
    .bcd_out(bcd_out),
    .valid_out(valid_out)
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

// Expected BCD digits
logic [19:0] exp_bcd_math;

logic [15:0] rand_binary;
/////////////////////////////////////////////////
// Golden Reference Model - mathematical approach
/////////////////////////////////////////////////
function automatic void binary_to_bcd_math(
    input logic [15:0] binary
);
    int value;
    int digit;
    value = binary;

    // Extract each decimal digit
    for(int i=0; i<=4; i++) begin

        digit = value % 10;
        if (i == 0)  exp_bcd_math[3:0] = digit;
        else if(i == 1)  exp_bcd_math[7:4] = digit;
        else if(i == 2)  exp_bcd_math[11:8] = digit;
        else if(i == 3)  exp_bcd_math[15:12] = digit;
        else if(i == 4)  exp_bcd_math[19:16] = digit;
        
        value = value / 10;
    end
endfunction

/////////////////////////////////////////////////
// Check if BCD is valid (each digit 0-9)
/////////////////////////////////////////////////
function automatic logic is_valid_bcd(
    input logic [19:0] bcd
);
    logic [3:0] temp1;
    for(int i=0; i<5; i++) begin
        if (i == 0)  temp1 = bcd[3:0];
        else if(i == 1)  temp1 = bcd[7:4];
        else if(i == 2)  temp1 = bcd[11:8];
        else if(i == 3)  temp1 = bcd[15:12];
        else if(i == 4)  temp1 = bcd[19:16];
        
        if(temp1 > 9) return 0;
    end
    return 1;
endfunction


/////////////////////////////////////////////////
// Test Generation Task
/////////////////////////////////////////////////
task run_test(
    input logic [15:0] test_binary
);
    
    @(posedge clk);
    valid_in = 1;
    binary_in = test_binary;
    
        begin
            @(posedge valid_out);
            
            // Generate expected results using both methods
            binary_to_bcd_math(test_binary);
            // Check DUT against both expected results
            check_result(test_binary, bcd_out, exp_bcd_math);

        end
        
    valid_in = 0;
endtask



/////////////////////////////////////////////////
// Scoreboard Task
/////////////////////////////////////////////////

task check_result(
    input logic [15:0] test_binary,
    input logic [19:0]  dut_bcd,
    input logic [19:0]  exp_bcd 
);
    
    logic mismatch;
      
    mismatch = 0;
    if(dut_bcd !== exp_bcd) begin
        mismatch = 1;
    end
    
    if(mismatch) begin
        $error("[%0t] MISMATCH: Binary=%0d (0x%b) -> DUT=%h Expected=%h", 
                $time, test_binary, test_binary, dut_bcd, exp_bcd);
        $fwrite(file_handle, "1 "); // Mismatch
        errors++;
    end
    else if(!is_valid_bcd(dut_bcd)) begin
        $error("[%0t] INVALID BCD: Binary=%0d (0x%b) -> DUT=%h (contains digits >9)", 
                $time, test_binary, test_binary, dut_bcd);
        $fwrite(file_handle, "I "); // Invalid BCD
        errors++;
    end
    else begin
        $display("[%0t] PASS: Binary=%b (in decimal %0d) -> BCD=%h", 
                 $time, test_binary, test_binary, dut_bcd);
        $fwrite(file_handle, "0 "); // Match
        tests_passed++;
    end
    tests_run++;
endtask


/////////////////////////////////////////////////
// Main Test Sequence
/////////////////////////////////////////////////
initial begin
    // Open results file
    file_handle = $fopen("../bcd_converter_results.txt", "w");
    if (file_handle == 0) begin
        $error("Failed to open results file");
        $finish;
    end
    
    // Initial reset
    rst = 1;
    valid_in = 0;
    binary_in = 16'd0;
    
    #20;
    @(posedge clk);
    rst = 0;
    
    $display("[%0t] Reset complete, starting tests...", $time);

    for(int i=0;i<10;i++) begin
    
    @(posedge clk);
    $display("\n[%0t] Running Random Test %0d", $time, i);
    rand_binary = $urandom_range(0, 16'hFFFF);
    run_test(rand_binary);
    
    end
    
    // Wait for any remaining operations
    #20
        
    // Summary report
    $display("\n=================================================");
    $display("TEST SUMMARY");
    $display("=================================================");
    $display("Tests Run    : %0d", tests_run);
    $display("Tests Passed : %0d", tests_passed);
    $display("Tests Failed : %0d", errors);
    $display("=================================================");
    
    if (errors == 0) begin
        $display("===========Your Design Passed===========");
    end
    else begin
        $display("===========Error===========");
    end
    $display("=================================================\n");
    
        // Close results file
    $fclose(file_handle);

    $finish;
end

endmodule