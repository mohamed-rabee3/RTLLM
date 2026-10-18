module freq_diveven #(
    parameter NUM_DIV = 4
)(
    input  clk,
    input  rst_n,
    output reg clk_div
);

    reg [3:0] cnt;

    localparam [3:0] LIMIT = (NUM_DIV / 2) - 1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt     <= 4'b0000;
            clk_div <= 1'b0;
        end else begin
            if (cnt < LIMIT) begin
                cnt <= cnt + 1'b1;
            end else begin
                cnt     <= 4'b0000;
                clk_div <= ~clk_div;
            end
        end
    end

endmodule
