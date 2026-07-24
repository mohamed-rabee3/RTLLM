`timescale 1ns/1ps

module tb_fir_interpolator();

parameter L = 8;
parameter NTAPS = 15;
parameter N_INPUT = 2;

logic clk;
logic rst;
logic valid_in;
logic valid_out;

logic signed [15:0] data_in;
logic signed [15:0] data_out;

/* DUT */
fir_interpolator dut(
    .clk(clk),
    .rst(rst),
    .valid_in(valid_in),
    .data_in(data_in),
    .valid_out(valid_out),
    .data_out(data_out)
);

//////////////////////////////////////////////////
// Clock
//////////////////////////////////////////////////

initial clk = 0;
always #5 clk = ~clk;

//////////////////////////////////////////////////
// Input Samples
//////////////////////////////////////////////////

logic signed [15:0] input_samples [0:N_INPUT-1] = '{
16'sh0014,   // 20
16'sh0050    // 80
};

//////////////////////////////////////////////////
// FIR Coefficients (Q8.8)
//////////////////////////////////////////////////

logic signed [15:0] coeffs [0:NTAPS-1] = '{
16'sh0020, //0.125
16'sh0040, //0.25
16'sh0060, //0.375
16'sh0080, //0.5
16'sh00A0, //0.625
16'sh00C0, //0.75
16'sh00E0, //0.875
16'sh0100, //1.0
16'sh00E0,
16'sh00C0,
16'sh00A0,
16'sh0080,
16'sh0060,
16'sh0040,
16'sh0020
};
///////////////////////////////////////////
logic [15:0] golden_out [0:8] = '{
16'h0014,
16'h001B,
16'h0023,
16'h002B,
16'h0032,
16'h003A,
16'h0041,
16'h0049,
16'h0050
};

///////////////////////////////////////////

integer final_comp;
 
initial
begin
   
    final_comp     = $fopen("../final_comp.txt","w"); // open file
	
 end
//////////////////////////////////////////////////
// Stimulus
//////////////////////////////////////////////////

initial begin

    rst = 1;
    valid_in = 0;

    #20;
    rst = 0;

    for(int i=0;i<N_INPUT;i++) begin
        @(posedge clk);
        valid_in = 1;
        data_in  = input_samples[i];
    end

    @(posedge clk);
    valid_in = 0;

end

//////////////////////////////////////////////////
//check
//////////////////////////////////////////////////

int out_index = 0;

always @(posedge clk) begin

    if(valid_out) begin

        if(data_out !== golden_out[out_index]) begin
            $fwrite(final_comp, "1 ");
        end
        else begin
           $fwrite(final_comp, "0 "); 
        end

        out_index++;

        if(out_index == (L+1)) begin
            $display("TEST PASSED");
            $finish;
        end
	$fclose(final_comp);
    end

end

endmodule