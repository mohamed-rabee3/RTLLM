module freq_divbyodd #(
    parameter integer NUM_DIV = 5
) (
    input  wire clk,
    input  wire rst_n,
    output wire clk_div
);

    localparam integer CNT_WIDTH = (NUM_DIV > 1) ? $clog2(NUM_DIV) : 1;

    reg [CNT_WIDTH-1:0] cnt1;
    reg [CNT_WIDTH-1:0] cnt2;
    reg clk_div1;
    reg clk_div2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt1     <= {CNT_WIDTH{1'b0}};
            clk_div1 <= 1'b0;
        end else begin
            if (cnt1 == NUM_DIV - 1)
                cnt1 <= {CNT_WIDTH{1'b0}};
            else
                cnt1 <= cnt1 + 1'b1;

            if (cnt1 == (NUM_DIV - 1) / 2)
                clk_div1 <= 1'b1;
            else if (cnt1 == NUM_DIV - 1)
                clk_div1 <= 1'b0;
        end
    end

    always @(negedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt2     <= {CNT_WIDTH{1'b0}};
            clk_div2 <= 1'b0;
        end else begin
            if (cnt2 == NUM_DIV - 1)
                cnt2 <= {CNT_WIDTH{1'b0}};
            else
                cnt2 <= cnt2 + 1'b1;

            if (cnt2 == (NUM_DIV - 1) / 2)
                clk_div2 <= 1'b1;
            else if (cnt2 == NUM_DIV - 1)
                clk_div2 <= 1'b0;
        end
    end

    generate
        if (NUM_DIV == 1) begin : gen_divide_by_one
            assign clk_div = clk & rst_n;
        end else begin : gen_odd_divider
            assign clk_div = clk_div1 | clk_div2;
        end
    endgenerate

endmodule
