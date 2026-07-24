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

int errors = 0;

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
// Golden output: linear interpolation by factor L between the two
// input samples, using integer (truncating) division.
//   golden[m] = in0 + (in1-in0)*m/L , m = 0..L
//////////////////////////////////////////////////
logic signed [15:0] golden_out [0:L];

initial begin
    for (int m = 0; m <= L; m++)
        golden_out[m] = input_samples[0] +
                        ((input_samples[1] - input_samples[0]) * m) / L;
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
            $display("Mismatch at %0d Expected=%h Got=%h",
                     out_index, golden_out[out_index], data_out);
            errors++;
        end
        else begin
            $display("Match %0d : %h", out_index, data_out);
        end

        out_index++;

        if(out_index == (L+1)) begin
            if (errors == 0)
                $display("===========Your Design Passed===========");
            else
                $display("===========Error===========");
            $finish;
        end
    end

end

endmodule
