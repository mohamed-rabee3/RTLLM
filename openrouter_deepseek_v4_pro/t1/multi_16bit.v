module multi_16bit (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        start,
    input  wire [15:0] ain,
    input  wire [15:0] bin,
    output wire [31:0] yout,
    output wire        done
);

    // Internal registers
    reg [4:0]  i;
    reg        done_r;
    reg [15:0] areg, breg;
    reg [31:0] yout_r;

    // Shift count register (i) update
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            i <= 5'd0;
        end else begin
            if (!start) begin
                i <= 5'd0;
            end else if (i < 17) begin
                i <= i + 1'b1;
            end
        end
    end

    // Multiplication completion flag generation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            done_r <= 1'b0;
        end else begin
            if (i == 5'd16) begin
                done_r <= 1'b1;
            end else if (i == 5'd17) begin
                done_r <= 1'b0;
            end
        end
    end

    // Shift and accumulate operation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            areg   <= 16'd0;
            breg   <= 16'd0;
            yout_r <= 32'd0;
        end else if (start) begin
            if (i == 5'd0) begin
                // Load multiplicand and multiplier, clear product
                areg   <= ain;
                breg   <= bin;
                yout_r <= 32'd0;
            end else if (i < 17) begin
                // For shift counts 1 to 16: check multiplicand bit i-1
                if (areg[i-1]) begin
                    // Add shifted multiplier to product
                    yout_r <= yout_r + ({16'd0, breg} << (i-1));
                end
            end
        end
    end

    // Output assignments
    assign yout = yout_r;
    assign done = done_r;

endmodule