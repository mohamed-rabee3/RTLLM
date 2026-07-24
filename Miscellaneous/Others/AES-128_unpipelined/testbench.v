`timescale 1ns / 1ps

module tb1();

// Parameters
parameter CLK_PERIOD = 10;  // 10ns clock period
parameter KEY_SETUP_CYCLES = 2;  // Key expansion takes 2 cycles
parameter PIPELINE_DEPTH = 11;   // 11 cycles from input to output

// Test bench signals
reg clk;
reg rst;
reg EN;
reg [127:0] Plain_text;
reg [127:0] Key_in;
wire [127:0] Cypher_text;

// Test variables
reg test_passed;
integer test_count;
integer pass_count;
integer fail_count;
integer i, j;
integer cycle_count;
reg [127:0] expected_output;
reg [127:0] output_history [0:20];  // History for pipeline alignment
integer history_idx;

// Expected test vectors (same as before)
reg [127:0] test_vectors [0:41][0:2];

// Instantiate the AES_Encrypt module
AES_Encrypt uut (
    .clk(clk),
    .rst(rst),
    .Plain_text(Plain_text),
    .EN(EN),
    .Key_in(Key_in),
    .Cypher_text(Cypher_text)
);

// Clock generation
always begin
    clk = 0;
    #(CLK_PERIOD/2);
    clk = 1;
    #(CLK_PERIOD/2);
end

// Initialize test vectors (same as your original)
initial begin
    // Test vectors from file 1.txt (Key = 0x000...0)
    test_vectors[0][0] = 128'h00000000000000000000000000000000;
    test_vectors[0][1] = 128'h9798c4640bad75c7c3227db910174e72;
    test_vectors[0][2] = 128'ha9a1631bf4996954ebc093957b234589;
    
    test_vectors[1][0] = 128'h00000000000000000000000000000000;
    test_vectors[1][1] = 128'h96ab5c2ff612d9dfaae8c31f30c42168;
    test_vectors[1][2] = 128'hff4f8391a6a40ca5b25d23bedd44a597;
    
    test_vectors[2][0] = 128'h00000000000000000000000000000000;
    test_vectors[2][1] = 128'h6a118a874519e64e9963798a503f1d35;
    test_vectors[2][2] = 128'hdc43be40be0e53712f7e2bf5ca707209;
    
    test_vectors[3][0] = 128'h00000000000000000000000000000000;
    test_vectors[3][1] = 128'hcb9fceec81286ca3e989bd979b0cb284;
    test_vectors[3][2] = 128'h92beedab1895a94faa69b632e5cc47ce;
    
    test_vectors[4][0] = 128'h00000000000000000000000000000000;
    test_vectors[4][1] = 128'hb26aeb1874e47ca8358ff22378f09144;
    test_vectors[4][2] = 128'h459264f4798f6a78bacb89c15ed3d601;
    
    test_vectors[5][0] = 128'h00000000000000000000000000000000;
    test_vectors[5][1] = 128'h58c8e00b2631686d54eab84b91f0aca1;
    test_vectors[5][2] = 128'h08a4e2efec8a8e3312ca7460b9040bbf;
    
    // Test vectors from file 2.txt (Key = 0x800...0)
    test_vectors[6][0] = 128'h80000000000000000000000000000000;
    test_vectors[6][1] = 128'h9798c4640bad75c7c3227db910174e72;
    test_vectors[6][2] = 128'h8ee2abbee0fca82e745ccc3a76265a9b;
    
    test_vectors[7][0] = 128'h80000000000000000000000000000000;
    test_vectors[7][1] = 128'h96ab5c2ff612d9dfaae8c31f30c42168;
    test_vectors[7][2] = 128'h1a22a7318c2187aa55983eb11baf8a7c;
    
    test_vectors[8][0] = 128'h80000000000000000000000000000000;
    test_vectors[8][1] = 128'h6a118a874519e64e9963798a503f1d35;
    test_vectors[8][2] = 128'h68b3b0147b43473a9f29a165cfc69c78;
    
    test_vectors[9][0] = 128'h80000000000000000000000000000000;
    test_vectors[9][1] = 128'hcb9fceec81286ca3e989bd979b0cb284;
    test_vectors[9][2] = 128'h7802cde1b7a149572ee05c7db5cb2e6c;
    
    test_vectors[10][0] = 128'h80000000000000000000000000000000;
    test_vectors[10][1] = 128'hb26aeb1874e47ca8358ff22378f09144;
    test_vectors[10][2] = 128'h5c38c5ea9efa16d087099669300ec68a;
    
    test_vectors[11][0] = 128'h80000000000000000000000000000000;
    test_vectors[11][1] = 128'h58c8e00b2631686d54eab84b91f0aca1;
    test_vectors[11][2] = 128'h74dbabb2128debd217d5d44e3c91afce;
    
    // Test vectors from file 3.txt (Key = 0xC00...0)
    test_vectors[12][0] = 128'hc0000000000000000000000000000000;
    test_vectors[12][1] = 128'h9798c4640bad75c7c3227db910174e72;
    test_vectors[12][2] = 128'hf44a89396ff79904bc79febf88ab05ce;
    
    test_vectors[13][0] = 128'hc0000000000000000000000000000000;
    test_vectors[13][1] = 128'h96ab5c2ff612d9dfaae8c31f30c42168;
    test_vectors[13][2] = 128'h809e1c2259c781a706f7acd0f426b059;
    
    test_vectors[14][0] = 128'hc0000000000000000000000000000000;
    test_vectors[14][1] = 128'h6a118a874519e64e9963798a503f1d35;
    test_vectors[14][2] = 128'h38e92afdd56dbe444e6004c5c819ab93;
    
    test_vectors[15][0] = 128'hc0000000000000000000000000000000;
    test_vectors[15][1] = 128'hcb9fceec81286ca3e989bd979b0cb284;
    test_vectors[15][2] = 128'hd2717e54aa90743a2e200acd7a36e2f4;
    
    test_vectors[16][0] = 128'hc0000000000000000000000000000000;
    test_vectors[16][1] = 128'hb26aeb1874e47ca8358ff22378f09144;
    test_vectors[16][2] = 128'h3dc1575c868f1b28c7fcd2a524ef9475;
    
    test_vectors[17][0] = 128'hc0000000000000000000000000000000;
    test_vectors[17][1] = 128'h58c8e00b2631686d54eab84b91f0aca1;
    test_vectors[17][2] = 128'hd49419d76d76fa19febec7e74c639f68;
    
    // Test vectors from file 4.txt (Key = 0xE00...0)
    test_vectors[18][0] = 128'he0000000000000000000000000000000;
    test_vectors[18][1] = 128'h9798c4640bad75c7c3227db910174e72;
    test_vectors[18][2] = 128'hf75b8704ce586245dbf5d5f1d804b9fb;
    
    test_vectors[19][0] = 128'he0000000000000000000000000000000;
    test_vectors[19][1] = 128'h96ab5c2ff612d9dfaae8c31f30c42168;
    test_vectors[19][2] = 128'hc2eb78d8ee4908c3acfaa5c6bdba8e0f;
    
    test_vectors[20][0] = 128'he0000000000000000000000000000000;
    test_vectors[20][1] = 128'h6a118a874519e64e9963798a503f1d35;
    test_vectors[20][2] = 128'hf526eea3a4ed5b3edeb7ca02b726d96a;
    
    test_vectors[21][0] = 128'he0000000000000000000000000000000;
    test_vectors[21][1] = 128'hcb9fceec81286ca3e989bd979b0cb284;
    test_vectors[21][2] = 128'h08b2f40231b2ed9a9eaf4cd926697564;
    
    test_vectors[22][0] = 128'he0000000000000000000000000000000;
    test_vectors[22][1] = 128'hb26aeb1874e47ca8358ff22378f09144;
    test_vectors[22][2] = 128'h362bbe98ccdacd5d9318e6f7f224f8d4;
    
    test_vectors[23][0] = 128'he0000000000000000000000000000000;
    test_vectors[23][1] = 128'h58c8e00b2631686d54eab84b91f0aca1;
    test_vectors[23][2] = 128'h1fe2bedc38ccac38eb5e694f326590d0;
    
    // Test vectors from file 5.txt (Key = 0xF00...0)
    test_vectors[24][0] = 128'hf0000000000000000000000000000000;
    test_vectors[24][1] = 128'h9798c4640bad75c7c3227db910174e72;
    test_vectors[24][2] = 128'hc3983992a27223402d08f425a18b3c2c;
    
    test_vectors[25][0] = 128'hf0000000000000000000000000000000;
    test_vectors[25][1] = 128'h96ab5c2ff612d9dfaae8c31f30c42168;
    test_vectors[25][2] = 128'h79f968846592f4547e1e308d6b8529ac;
    
    test_vectors[26][0] = 128'hf0000000000000000000000000000000;
    test_vectors[26][1] = 128'h6a118a874519e64e9963798a503f1d35;
    test_vectors[26][2] = 128'habf3c93618bf47984ac07abd1af4fac5;
    
    test_vectors[27][0] = 128'hf0000000000000000000000000000000;
    test_vectors[27][1] = 128'hcb9fceec81286ca3e989bd979b0cb284;
    test_vectors[27][2] = 128'h0d8adf415e6234e06d10ff916394e833;
    
    test_vectors[28][0] = 128'hf0000000000000000000000000000000;
    test_vectors[28][1] = 128'hb26aeb1874e47ca8358ff22378f09144;
    test_vectors[28][2] = 128'h0162702daa4d55bdf3f7e75c765b1e99;
    
    test_vectors[29][0] = 128'hf0000000000000000000000000000000;
    test_vectors[29][1] = 128'h58c8e00b2631686d54eab84b91f0aca1;
    test_vectors[29][2] = 128'hea07467ce210bcbb480ce862e97d8e04;
    
    // Test vectors from file 6.txt (Key = 0xF80...0)
    test_vectors[30][0] = 128'hf8000000000000000000000000000000;
    test_vectors[30][1] = 128'h9798c4640bad75c7c3227db910174e72;
    test_vectors[30][2] = 128'h2193754dbf9cfd91f78a0775aa398f18;
    
    test_vectors[31][0] = 128'hf8000000000000000000000000000000;
    test_vectors[31][1] = 128'h96ab5c2ff612d9dfaae8c31f30c42168;
    test_vectors[31][2] = 128'heeaed8e67358288398edf2090afcb0cb;
    
    test_vectors[32][0] = 128'hf8000000000000000000000000000000;
    test_vectors[32][1] = 128'h6a118a874519e64e9963798a503f1d35;
    test_vectors[32][2] = 128'h6c228a20f6d86b261f93fbaaa5d047fa;
    
    test_vectors[33][0] = 128'hf8000000000000000000000000000000;
    test_vectors[33][1] = 128'hcb9fceec81286ca3e989bd979b0cb284;
    test_vectors[33][2] = 128'heefb9ebb6bfaec0381b84ba7171de5ec;
    
    test_vectors[34][0] = 128'hf8000000000000000000000000000000;
    test_vectors[34][1] = 128'hb26aeb1874e47ca8358ff22378f09144;
    test_vectors[34][2] = 128'hb869d89fc937d6c35d3a28ec942f59aa;
    
    test_vectors[35][0] = 128'hf8000000000000000000000000000000;
    test_vectors[35][1] = 128'h58c8e00b2631686d54eab84b91f0aca1;
    test_vectors[35][2] = 128'hffc64d053f54c34b572a9e5797d4528b;
    
    // Test vectors from file 7.txt (Key = 0xFC0...0)
    test_vectors[36][0] = 128'hfc000000000000000000000000000000;
    test_vectors[36][1] = 128'h9798c4640bad75c7c3227db910174e72;
    test_vectors[36][2] = 128'hdaf7abad45e0208424c592fb58078340;
    
    test_vectors[37][0] = 128'hfc000000000000000000000000000000;
    test_vectors[37][1] = 128'h96ab5c2ff612d9dfaae8c31f30c42168;
    test_vectors[37][2] = 128'h9ff25a905ee66d73a9eb45caa8ecf59c;
    
    test_vectors[38][0] = 128'hfc000000000000000000000000000000;
    test_vectors[38][1] = 128'h6a118a874519e64e9963798a503f1d35;
    test_vectors[38][2] = 128'h568e92e3ff944472c825790a81fc77d4;
    
    test_vectors[39][0] = 128'hfc000000000000000000000000000000;
    test_vectors[39][1] = 128'hcb9fceec81286ca3e989bd979b0cb284;
    test_vectors[39][2] = 128'he8f64cf956a13b8195906587be57f387;
    
    test_vectors[40][0] = 128'hfc000000000000000000000000000000;
    test_vectors[40][1] = 128'hb26aeb1874e47ca8358ff22378f09144;
    test_vectors[40][2] = 128'hb2725108dfedcce3505cc8670c8031e7;
    
    test_vectors[41][0] = 128'hfc000000000000000000000000000000;
    test_vectors[41][1] = 128'h58c8e00b2631686d54eab84b91f0aca1;
    test_vectors[41][2] = 128'heebafece675669ab7dcfa1d86e692f93;
end

// Task to run a single encryption test with proper pipeline handling
task run_encryption_test;
    input integer test_num;
    input [127:0] key;
    input [127:0] plaintext;
    input [127:0] expected;
    integer wait_cycles;
    reg [127:0] captured_output;
    integer pipeline_clear;
begin
    $display("============================================================");
    $display("Test #%0d:", test_num);
    $display("  Key:       %032h", key);
    $display("  Plaintext: %032h", plaintext);
    $display("  Expected:  %032h", expected);
    
    // Clear any existing data in pipeline by waiting
    // This is critical when changing keys!
    if (test_num > 1) begin
        $display("  Clearing pipeline before new key...");
        // Wait for pipeline to drain (PIPELINE_DEPTH cycles)
        for (pipeline_clear = 0; pipeline_clear < PIPELINE_DEPTH; pipeline_clear = pipeline_clear + 1) begin
            @(posedge clk);
            #1;
        end
    end
    
    // Set new key and enable
    Key_in = key;
    EN = 1;
    $display("  Key loaded, EN asserted at time %0t ns", $time);
    
    // Wait exactly 2 cycles for key expansion (as per your note)
    @(posedge clk);
    #1;
    @(posedge clk);
    #1;
    
    // Load plaintext
    Plain_text = plaintext;
    $display("  Plaintext loaded at time %0t ns", $time);
    
    // Wait for encryption to complete (PIPELINE_DEPTH cycles)
    for (wait_cycles = 0; wait_cycles < PIPELINE_DEPTH; wait_cycles = wait_cycles + 1) begin
        @(posedge clk);
        #1;
    end
    
    // Capture output
    captured_output = Cypher_text;
    $display("  Output captured at time %0t ns", $time);
    $display("  Output:    %032h", captured_output);
    
    // Compare with expected
    if (captured_output === expected) begin
        $display("  Result: ? PASSED");
        pass_count = pass_count + 1;
    end else begin
        $display("  Result: ? FAILED");
        $display("    Expected: %032h", expected);
        $display("    Got:      %032h", captured_output);
        fail_count = fail_count + 1;
        test_passed = 0;
    end
    
    // Deassert enable
    EN = 0;
    
    // Wait before next test
    #100;
end
endtask

// Main test procedure
initial begin
    // Initialize signals
    rst = 1;
    EN = 0;
    Plain_text = 128'h0;
    Key_in = 128'h0;
    test_passed = 1;
    pass_count = 0;
    fail_count = 0;
    test_count = 0;
    history_idx = 0;
    
    $display("============================================================");
    $display("AES Encryption Test Bench (CORRECTED)");
    $display("============================================================");
    $display("Parameters:");
    $display("  Clock period: %0d ns", CLK_PERIOD);
    $display("  Key setup cycles: %0d", KEY_SETUP_CYCLES);
    $display("  Pipeline depth: %0d cycles", PIPELINE_DEPTH);
    $display("  Number of test vectors: %0d", 42);
    $display("============================================================");
    
    // Reset the module
    #20;
    rst = 0;
    $display("Reset deasserted at time %0t ns", $time);
    #20;
    rst = 1;
    $display("Reset completed at time %0t ns", $time);
    
    // Wait for initial stabilization
    #200;
    
    // Run all individual tests
    $display("\n=== RUNNING INDIVIDUAL TESTS ===");
    for (i = 0; i < 42; i = i + 1) begin
        test_count = test_count + 1;
        run_encryption_test(test_count, 
                           test_vectors[i][0], 
                           test_vectors[i][1], 
                           test_vectors[i][2]);
        
        // Add extra delay between key changes
        #200;
    end
    
    // Summary
    $display("");
    $display("============================================================");
    $display("TEST SUMMARY");
    $display("============================================================");
    $display("Total tests:  %0d", test_count);
    $display("Passed:       %0d", pass_count);
    $display("Failed:       %0d", fail_count);
    $display("Success rate: %0.1f%%", (pass_count * 100.0) / test_count);
    $display("============================================================");
    
    if (test_passed) begin
        $display("===========Your Design Passed===========");
    end else begin
        $display("===========Error===========");
        $display("");
        $display("Possible issues to check:");
        $display("1. Key expansion module for key = 0xfc000000000000000000000000000000");
        $display("2. Pipeline initialization after reset");
        $display("3. Round key ordering (Key0 to Key10)");
        $display("4. initial_rnd, Round_Top, and final_rnd modules");
    end
    $display("============================================================");
    $display("Simulation completed at time %0t ns", $time);
    
    #100;
    $finish;
end


endmodule