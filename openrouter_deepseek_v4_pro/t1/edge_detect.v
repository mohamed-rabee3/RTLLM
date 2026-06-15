module edge_detect (
    input  clk,
    input  rst_n,
    input  a,
    output reg rise,
    output reg down
);

    // Register to hold the previous value of a
    reg a_d;

    // Edge detection logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_d  <= 1'b0;
            rise <= 1'b0;
            down <= 1'b0;
        end else begin
            a_d  <= a;
            // Rising edge: a was 0 and is now 1
            rise <= ~a_d & a;
            // Falling edge: a was 1 and is now 0
            down <= a_d & ~a;
        end
    end

endmodule