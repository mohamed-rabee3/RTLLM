`timescale 1ns/1ps

module tb_sorting_3_numbers();

    // DUT inputs
    logic [9:0] a1;
    logic [9:0] a2;
    logic [9:0] a3;

    // DUT outputs
    logic [9:0] max;
    logic [9:0] med;
    logic [9:0] min;

    // expected values
    logic [9:0] exp_max;
    logic [9:0] exp_med;
    logic [9:0] exp_min;

    // Instantiate VHDL DUT
    sorting_3_numbers dut (
        .a1(a1),
        .a2(a2),
        .a3(a3),
        .max(max),
        .med(med),
        .min(min)
    );

    // task to compute expected values
    task compute_expected(input [9:0] x1, x2, x3);
        logic [9:0] arr [2:0];
        logic [9:0] temp;
        int i,j;

        begin
            arr[0] = x1;
            arr[1] = x2;
            arr[2] = x3;

            // simple bubble sort
            for(i=0;i<3;i++) begin
                for(j=i+1;j<3;j++) begin
                    if(arr[i] > arr[j]) begin
                        temp = arr[i];
                        arr[i] = arr[j];
                        arr[j] = temp;
                    end
                end
            end

            exp_min = arr[0];
            exp_med = arr[1];
            exp_max = arr[2];
        end
    endtask


    initial begin
        int i;

        for(i=0;i<10;i++) begin

            // random inputs
            a1 = $urandom_range(0,1023);
            a2 = $urandom_range(0,1023);
            a3 = $urandom_range(0,1023);

            #1;

            compute_expected(a1,a2,a3);

            // self check
            if(max !== exp_max || med !== exp_med || min !== exp_min) begin
                $display("ERROR:");
                $display("Inputs: a1=%0d a2=%0d a3=%0d",a1,a2,a3);
                $display("Expected max=%0d med=%0d min=%0d",
                          exp_max,exp_med,exp_min);
                $display("Got max=%0d med=%0d min=%0d",
                          max,med,min);
            end
            else begin
                $display("PASS: a1=%0d a2=%0d a3=%0d",a1,a2,a3);
            end

        end

        $display("TEST FINISHED");
        $finish;
    end

endmodule