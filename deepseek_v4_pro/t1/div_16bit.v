module div_16bit (
    input  [15:0] A,
    input  [7:0]  B,
    output reg [15:0] result,
    output reg [15:0] odd
);
    // Internal registers as required by the specification
    reg [15:0] a_reg;
    reg [7:0]  b_reg;
    
    // Variables for the division algorithm
    reg [15:0] quotient;
    reg [15:0] remainder;
    integer i;

    // First always block: combinational, triggered by A or B.
    // Updates a_reg and b_reg with the input values.
    always @(A or B) begin
        a_reg = A;
        b_reg = B;
    end

    // Second always block: combinational, triggered by A or B.
    // Performs the 16-step restoring division algorithm.
    always @(A or B) begin
        quotient  = 16'b0;
        remainder = 16'b0;
        
        for (i = 15; i >= 0; i = i - 1) begin
            // Shift remainder left by 1 and bring in the next dividend bit (MSB first)
            remainder = {remainder[14:0], A[i]};
            
            if (remainder >= B) begin
                remainder   = remainder - B;
                quotient[i] = 1'b1;
            end else begin
                quotient[i] = 1'b0;
            end
        end
        
        result = quotient;
        odd    = remainder;
    end
endmodule