module freq_divbyodd #(parameter NUM_DIV = 5) (
    input wire clk,
    input wire rst_n,
    output wire clk_div
);

    // Compute required counter width
    localparam CNT_WIDTH = (NUM_DIV <= 1) ? 1 : $clog2(NUM_DIV);
    // Half-point of the counter (integer division, works for odd NUM_DIV as (NUM_DIV-1)/2)
    localparam HALF = NUM_DIV / 2;

    reg [CNT_WIDTH-1:0] cnt1, cnt2;
    reg clk_div1, clk_div2;

    // Counter 1: increments on rising edge of clk
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt1 <= {CNT_WIDTH{1'b0}};
        end else begin
            if (cnt1 == NUM_DIV - 1)
                cnt1 <= {CNT_WIDTH{1'b0}};
            else
                cnt1 <= cnt1 + 1'b1;
        end
    end

    // Counter 2: increments on falling edge of clk
    always @(negedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt2 <= {CNT_WIDTH{1'b0}};
        end else begin
            if (cnt2 == NUM_DIV - 1)
                cnt2 <= {CNT_WIDTH{1'b0}};
            else
                cnt2 <= cnt2 + 1'b1;
        end
    end

    // clk_div1 toggles on rising edge when counter reaches HALF or NUM_DIV-1
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            clk_div1 <= 1'b0;
        end else begin
            if ((cnt1 == HALF) || (cnt1 == NUM_DIV - 1))
                clk_div1 <= ~clk_div1;
        end
    end

    // clk_div2 toggles on falling edge when counter reaches HALF or NUM_DIV-1
    always @(negedge clk or negedge rst_n) begin
        if (!rst_n) begin
            clk_div2 <= 1'b0;
        end else begin
            if ((cnt2 == HALF) || (cnt2 == NUM_DIV - 1))
                clk_div2 <= ~clk_div2;
        end
    end

    // Final divided clock output is the OR of the two edge-aligned dividers
    assign clk_div = clk_div1 | clk_div2;

endmodule