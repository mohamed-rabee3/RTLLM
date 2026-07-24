`timescale 1ns / 1ps


module FIR_tb();



parameter NTAPS = 4;
parameter NSAMPLES = 8;


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
/////////////////////////////////////////////////
// Clock
//////////////////////////////////////////////////

initial clk = 0;
always #5 clk = ~clk;

//////////////////////////////////////////////////
// Input Samples
//////////////////////////////////////////////////
logic signed [15:0] inputs [0:NSAMPLES-1] = '{
16'sd10,
16'sd20,
16'sd30,
16'sd40,
16'sd50,
16'sd60,
16'sd70,
16'sd80
};

//////////////////////////////////////////////////
// FIR Coefficients (Q8.8)
//////////////////////////////////////////////////
logic signed [15:0] coeffs [0:NTAPS-1] = '{
16'sh0040,  // 0.25
16'sh0080,  // 0.50
16'sh0080,  // 0.50
16'sh0040   // 0.25
};


///////////////////////////////////////////

integer final_comp;
 
initial
begin
   
    final_comp     = $fopen("../final_comp.txt","w"); // open file
	
 end
//////////////////////////////////////////////////
logic signed [15:0] golden_out [0:NSAMPLES-1];


/////////////////////////////////////////////////////
// Golden Reference Function
/////////////////////////////////////////////////////

function automatic logic signed [15:0] fir_golden
(
    input logic signed [15:0] x [ ],
    input logic signed [15:0] h [ ],
    input int n,
    input int NTAPS
);


    logic signed [31:0] acc;
    acc = 0;

    for(int k=0;k<NTAPS;k++) begin

        if((n-k)>=0)
            acc += inputs[n-k] * coeffs[k];

    end

    /* Q8.8 correction */

    acc = acc >>> 8;

    return acc[15:0];

endfunction

/////////////////////////////////////////////////////
initial begin

    for(int n=0; n<8; n++) begin
        golden_out[n] = fir_golden(inputs, coeffs, n, 4);
    end

end

initial begin

    rst = 1;
    valid_in = 0;

    #20;
    rst = 0;

    for(int i=0;i<8;i++) begin
        @(posedge clk);
        valid_in = 1;
        data_in  = inputs[i];
    end

    @(posedge clk);
    valid_in = 0;

end

//////////////////////////////////////////////////
//check
//////////////////////////////////////////////////

int index = 0;


always @(posedge clk) begin

    if(valid_out) begin

        if(data_out !== golden_out[index]) begin
            $error("Mismatch at %0d Expected=%h Got=%h",
                    index,
                    golden_out[index],
                    data_out);
             $fwrite(final_comp, "1 ");      
        end
        else begin
            $display("Match %0d : %h", index, data_out);
            $fwrite(final_comp, "0 "); 
        end

        index++;
        
        if(index == (NSAMPLES)) begin
            $display("===========Your Design Passed===========");
            $finish;
        end
	$fclose(final_comp);
    end

end


endmodule
