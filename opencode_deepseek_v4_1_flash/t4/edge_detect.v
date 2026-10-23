module edge_detect (
    input  wire clk,
    input  wire rst_n,
    input  wire a,
    output reg  rise,
    output reg  down
);

    reg a_prev;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_prev <= 1'b0;
            rise   <= 1'b0;
            down   <= 1'b0;
        end else begin
            a_prev <= a;
            rise   <= (a == 1'b1) && (a_prev == 1'b0);
            down   <= (a == 1'b0) && (a_prev == 1'b1);
        end
    end

endmodule
