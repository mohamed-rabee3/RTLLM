module freq_divbyodd #(
    parameter NUM_DIV = 5
)(
    input  clk,
    input  rst_n,
    output clk_div
);

    function integer clog2;
        input integer value;
        integer i;
        begin
            value = value - 1;
            for (i = 0; value > 0; i = i + 1) begin
                value = value >> 1;
            end
            clog2 = i;
        end
    endfunction

    localparam CNT_WIDTH = (NUM_DIV > 1) ? clog2(NUM_DIV) : 1;
    localparam HALF_DIV  = NUM_DIV / 2;

    reg [CNT_WIDTH-1:0] cnt1;
    reg [CNT_WIDTH-1:0] cnt2;
    reg clk_div1;
    reg clk_div2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt1     <= {CNT_WIDTH{1'b0}};
            clk_div1 <= 1'b0;
        end
        else if (cnt1 == NUM_DIV - 1) begin
            cnt1     <= {CNT_WIDTH{1'b0}};
            clk_div1 <= ~clk_div1;
        end
        else begin
            cnt1 <= cnt1 + 1'b1;
            if (cnt1 == HALF_DIV)
                clk_div1 <= ~clk_div1;
        end
    end

    always @(negedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt2     <= {CNT_WIDTH{1'b0}};
            clk_div2 <= 1'b0;
        end
        else if (cnt2 == NUM_DIV - 1) begin
            cnt2     <= {CNT_WIDTH{1'b0}};
            clk_div2 <= ~clk_div2;
        end
        else begin
            cnt2 <= cnt2 + 1'b1;
            if (cnt2 == HALF_DIV)
                clk_div2 <= ~clk_div2;
        end
    end

    assign clk_div = clk_div1 | clk_div2;

endmodule
