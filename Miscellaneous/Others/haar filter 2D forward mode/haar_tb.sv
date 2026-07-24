`timescale 1ns / 1ps

module tb_haar_wavelet_lh_output();


int block_r ;
int block_c ;

int col_idx;
logic signed [15:0] p1;
logic signed [15:0] p2 ;
int row_idx ;
            
int r ;
int c ;
int lh_matches ;
int lh_mismatches ;
int zero_coeffs ;
int positive_coeffs ;
int negative_coeffs ;            
/////////////////////////////////////////////////
// Parameters
/////////////////////////////////////////////////
parameter DATA_WIDTH = 8;            // 8-bit grayscale pixel values
parameter INTERNAL_WIDTH = 16;        // 16-bit coefficient output
parameter IMAGE_SIZE = 16;            // 16x16 image
parameter TOTAL_PIXELS = 256;         // 16 * 16

// String representations
string pattern_names[10] = '{
    "Flat Gray", 
    "Horizontal Gradient",
    "Vertical Gradient",
    "Checkerboard",
    "Horizontal Stripes",
    "Vertical Stripes",
    "Center Square",
    "Horizontal Edge",
    "Vertical Edge",
    "Diagonal Edge"
};

/////////////////////////////////////////////////
// DUT Signals 
/////////////////////////////////////////////////
logic clk;
logic rst_n;
logic valid_in;
logic [3:0] row;                       // 4-bit row (0-15)
logic [3:0] col;                       // 4-bit column (0-15)
logic [DATA_WIDTH-1:0] data_in;        // 8-bit grayscale input
logic signed [INTERNAL_WIDTH-1:0] data_out; // 16-bit LH coefficient
logic valid_out;
logic [2:0] out_row;                    // 3-bit output row (0-7)
logic [2:0] out_col;                    // 3-bit output column (0-7)

/////////////////////////////////////////////////
// DUT Instantiation
/////////////////////////////////////////////////
haar_wavelet_lh_only dut (
    .clk(clk),
    .rst_n(rst_n),
    .valid_in(valid_in),
    .row(row),
    .col(col),
    .data_in(data_in),
    .data_out(data_out),
    .valid_out(valid_out),
    .out_row(out_row),
    .out_col(out_col)
);

/////////////////////////////////////////////////
// Clock Generation
/////////////////////////////////////////////////
parameter CLK_PERIOD = 10; // 100MHz
initial clk = 0;
always #(CLK_PERIOD/2) clk = ~clk;

/////////////////////////////////////////////////
// Test control variables
/////////////////////////////////////////////////
int errors = 0;
int tests_run = 0;
int tests_passed = 0;
int file_handle;
int pattern_id = 0;

// Test image (16x16 grayscale)
logic [DATA_WIDTH-1:0] test_image [0:15][0:15];  // 16x16 array

// Expected LH coefficients (computed by golden model)
logic signed [31:0] expected_lh [0:7][0:7];      // 8x8 LH band

// DUT output LH coefficients
logic signed [INTERNAL_WIDTH-1:0] dut_lh [0:7][0:7];
int coeff_count_lh = 0;

// Statistics
int total_coeffs = 64;  // 8x8 = 64 coefficients in LH band



/////////////////////////////////////////////////
// Grayscale image pattern generation
/////////////////////////////////////////////////
task generate_grayscale_pattern(input int pattern);
    pattern_id = pattern;
    $display("\n========================================");
    $display("Pattern %0d: %s", pattern, pattern_names[pattern-1]);
    $display("========================================");
    
    case(pattern)
        1: begin // Flat gray (constant)
            for(int r=0; r<16; r++) begin
                for(int c=0; c<16; c++) begin
                    test_image[r][c] = 128;  // Mid-gray
                end
            end
        end
        
        2: begin // Horizontal gradient (varies vertically)
            for(int r=0; r<16; r++) begin
                for(int c=0; c<16; c++) begin
                    test_image[r][c] = (r * 255) / 15;  // 0 to 255 across rows
                end
            end
        end
        
        3: begin // Vertical gradient (varies horizontally)
            for(int r=0; r<16; r++) begin
                for(int c=0; c<16; c++) begin
                    test_image[r][c] = (c * 255) / 15;  // 0 to 255 across columns
                end
            end
        end
        
        4: begin // Checkerboard (4x4 blocks)
            for(int r=0; r<16; r++) begin
                for(int c=0; c<16; c++) begin
                    block_r = r / 4;
                    block_c = c / 4;
                    test_image[r][c] = ((block_r + block_c) % 2) ? 255 : 0;
                end
            end
        end
        
        5: begin // Horizontal stripes
            for(int r=0; r<16; r++) begin
                for(int c=0; c<16; c++) begin
                    test_image[r][c] = (r % 8 < 4) ? 200 : 50;
                end
            end
        end
        
        6: begin // Vertical stripes
            for(int r=0; r<16; r++) begin
                for(int c=0; c<16; c++) begin
                    test_image[r][c] = (c % 8 < 4) ? 200 : 50;
                end
            end
        end
        
        7: begin // Center square
            for(int r=0; r<16; r++) begin
                for(int c=0; c<16; c++) begin
                    if (r >= 4 && r <= 11 && c >= 4 && c <= 11)
                        test_image[r][c] = 255;  // White square
                    else
                        test_image[r][c] = 0;    // Black background
                end
            end
        end
        
        8: begin // Horizontal edge
            for(int r=0; r<16; r++) begin
                for(int c=0; c<16; c++) begin
                    test_image[r][c] = (r < 8) ? 0 : 255;
                end
            end
        end
        
        9: begin // Vertical edge
            for(int r=0; r<16; r++) begin
                for(int c=0; c<16; c++) begin
                    test_image[r][c] = (c < 8) ? 0 : 255;
                end
            end
        end
        
        10: begin // Diagonal edge
            for(int r=0; r<16; r++) begin
                for(int c=0; c<16; c++) begin
                    test_image[r][c] = (r < c) ? 255 : 0;
                end
            end
        end
        
        default: begin // Default to gradient
            for(int r=0; r<16; r++) begin
                for(int c=0; c<16; c++) begin
                    test_image[r][c] = (r * 16 + c) % 256;
                end
            end
        end
    endcase
    
    // Display image preview
    display_image_preview();
endtask

/////////////////////////////////////////////////
// Compute LH coefficients (Horizontal Details) golden
/////////////////////////////////////////////////
task compute_lh_coefficients();
    logic signed [31:0] row_lh [0:15][0:7];  // 16 rows x 8 columns after horizontal transform
    
 
    // Step 1: Apply 1D Haar horizontally to each row
    // LH band comes from the high-pass filter applied horizontally
    for(int r=0; r<16; r++) begin
        for(int c=0; c<8; c++) begin
            col_idx = 2*c;
            // Horizontal high-pass: (a - b) / âˆš2
            p1 = test_image[r][col_idx];
            p2 = test_image[r][col_idx+1];
            
            row_lh[r][c] = (p1 - p2) * 181 / 256;  // 181/256 â‰ˆ 1/âˆš2
        end
    end
    
    // Step 2: Apply low-pass filter vertically to the row_lh results
    // LH = low-pass vertically on horizontally high-passed data
    for(int r=0; r<8; r++) begin
        for(int c=0; c<8; c++) begin
            row_idx = 2*r;
            expected_lh[r][c] = (row_lh[row_idx][c] + row_lh[row_idx+1][c]) * 181 / 256;
        end
    end
    

endtask

/////////////////////////////////////////////////
// Load image into DUT with simplified addressing
/////////////////////////////////////////////////
task load_image_to_dut();
    $display("\n[%0t] Loading 16x16 grayscale image into DUT...", $time);
    $display("Input addressing: row[3:0], col[3:0] (4-bit each)");
    
    for(int r=0; r<16; r++) begin
        for(int c=0; c<16; c++) begin
            @(posedge clk);
            valid_in = 1;
            row = r[3:0];        // 4-bit row address
            col = c[3:0];        // 4-bit column address
            data_in = test_image[r][c];
        end
    end
    @(posedge clk);
    valid_in = 0;
    
    $display("[%0t] Image load complete", $time);
endtask

/////////////////////////////////////////////////
// Collect LH coefficients from DUT with simplified output
/////////////////////////////////////////////////
always @(posedge clk) begin
    if (valid_out) begin
        // out_row and out_col are 3-bit (0-7)
        r = out_row;
        c = out_col;
        
        dut_lh[r][c] = data_out;
        coeff_count_lh++;
        
        // Real-time display of LH coefficients as they arrive
        $display("[%0t] LH[%0d][%0d] = %0d", $time, r, c, data_out);
    end
end

/////////////////////////////////////////////////
// Verify LH coefficients
/////////////////////////////////////////////////
task verify_lh_coefficients();
    lh_matches = 0;
    lh_mismatches = 0;
    zero_coeffs = 0;
    positive_coeffs = 0;
    negative_coeffs = 0;
    
        
    // Wait for all coefficients to be collected
    #(CLK_PERIOD * 50);
    
    $display("\nLH Coefficient Count: %0d/%0d", coeff_count_lh, total_coeffs);
    
    if (coeff_count_lh != total_coeffs) begin
        $error("Missing LH coefficients! Expected %0d, got %0d", total_coeffs, coeff_count_lh);
        errors++;
        return;
    end
    
    // Verify each LH coefficient
   
    
    for(int r=0; r<8; r++) begin
        $write("  %0d  | ", r);
        for(int c=0; c<8; c++) begin
            if (dut_lh[r][c] == expected_lh[r][c]) begin
                $write("%3d(M) ", dut_lh[r][c]);
                lh_matches++;
                
                if (dut_lh[r][c] == 0) zero_coeffs++;
                else if (dut_lh[r][c] > 0) positive_coeffs++;
                else negative_coeffs++;
            end
            else begin
                $write("%3d(%0d) ", dut_lh[r][c], expected_lh[r][c]);
                lh_mismatches++;
            end
        end
        $display("");
    end
    
    $display("\nLH Band Statistics:");
    $display("  Matches: %0d/%0d", lh_matches, total_coeffs);
    $display("  Mismatches: %0d", lh_mismatches);
    $display("  Zero coefficients: %0d", zero_coeffs);
    $display("  Positive coefficients: %0d", positive_coeffs);
    $display("  Negative coefficients: %0d", negative_coeffs);

    
       
    if (lh_mismatches == 0) begin
        $display("\nâœ“ LH Band verification PASSED for %s", pattern_names[pattern_id-1]);
        $fwrite(file_handle, "0 ");
        tests_passed++;
    end
    else begin
        $display("\nâœ— LH Band verification FAILED for %s", pattern_names[pattern_id-1]);
        $fwrite(file_handle, "1 ");
        errors++;
    end
    tests_run++;
endtask



/////////////////////////////////////////////////
// Compare LH bands across patterns
/////////////////////////////////////////////////
task compare_lh_patterns();
    
    case(pattern_id)
        1: $display("Flat Gray: LH band should be ALL ZERO");
        2: $display("Horizontal Gradient: LH band should be ZERO (vertical variation only)");
        3: $display("Vertical Gradient: LH band should be NON-ZERO (horizontal variation)");
        4: $display("Checkerboard: LH band should show alternating pattern");
        5: $display("Horizontal Stripes: LH band should be ZERO (horizontal edges only)");
        6: $display("Vertical Stripes: LH band should be NON-ZERO (vertical edges)");
        7: $display("Center Square: LH band should show edges at square boundaries");
        8: $display("Horizontal Edge: LH band should be ZERO (horizontal edge only)");
        9: $display("Vertical Edge: LH band should show STRONG vertical edge");
        10: $display("Diagonal Edge: LH band should show diagonal pattern");
    endcase
endtask

/////////////////////////////////////////////////
// Reset counters for new pattern
/////////////////////////////////////////////////
task reset_counters();
    coeff_count_lh = 0;
    
    // Clear coefficient array
    for(int r=0; r<8; r++) begin
        for(int c=0; c<8; c++) begin
            dut_lh[r][c] = 0;
        end
    end
endtask


/////////////////////////////////////////////////
// Main test sequence
/////////////////////////////////////////////////
initial begin
    // Open results file
    file_handle = $fopen("../haar_wavelet_lh_results.txt", "w");
    if (file_handle == 0) begin
        $error("Failed to open results file");
        $finish;
    end
        
    // Initial reset
    rst_n = 0;
    valid_in = 0;
    
    #100;
    @(posedge clk);
    rst_n = 1;
    
    $display("[%0t] Reset complete, starting LH band tests...\n", $time);
    
    // Test multiple grayscale patterns for LH band
    for(int p=1; p<=10; p++) begin
        // Generate test pattern
        generate_grayscale_pattern(p);
        
        // Explain expected LH behavior
        compare_lh_patterns();
        
        // Compute expected LH coefficients
        compute_lh_coefficients();
        
        // Load image into DUT
        load_image_to_dut();
        
        // Verify LH coefficients
        verify_lh_coefficients();
        
       
        // Reset for next pattern
        reset_counters();
        #(CLK_PERIOD * 50);
    end
    
    // Wait for any remaining operations
    #(CLK_PERIOD * 100);
    
    // Close results file
    $fclose(file_handle);
    
    // Summary report
    $display("\n=================================================================");
    $display("TEST SUMMARY - LH Band Output");
    $display("=================================================================");
    $display("Test Patterns Run : %0d", tests_run);
    $display("Patterns Passed   : %0d", tests_passed);
    $display("Patterns Failed   : %0d", errors);
    $display("=================================================================");
    
    if (errors == 0) begin
        $display("STATUS: âœ“ ALL LH BAND PATTERNS PASSED");
    end
    else begin
        $display("STATUS: âœ— %0d PATTERNS FAILED", errors);
    end
    $display("=================================================================\n");
    
    $finish;
end


endmodule