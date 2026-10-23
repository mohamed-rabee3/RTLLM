module dual_port_RAM #(
    parameter WIDTH = 8,
    parameter DEPTH = 16
)(
    input wclk,
    input wenc,
    input [$clog2(DEPTH)-1:0] waddr,
    input [WIDTH-1:0] wdata,
    input rclk,
    input renc,
    input [$clog2(DEPTH)-1:0] raddr,
    output reg [WIDTH-1:0] rdata
);
    reg [WIDTH-1:0] RAM_MEM [0:DEPTH-1];

    always @(posedge wclk) begin
        if (wenc)
            RAM_MEM[waddr] <= wdata;
    end

    always @(posedge rclk) begin
        if (renc)
            rdata <= RAM_MEM[raddr];
    end
endmodule

module asyn_fifo #(
    parameter WIDTH = 8,
    parameter DEPTH = 16
)(
    input wclk,
    input rclk,
    input wrstn,
    input rrstn,
    input winc,
    input rinc,
    input [WIDTH-1:0] wdata,
    output wfull,
    output rempty,
    output [WIDTH-1:0] rdata
);

    localparam ADDR_WIDTH = $clog2(DEPTH);
    localparam PTR_WIDTH  = ADDR_WIDTH + 1;

    reg [PTR_WIDTH-1:0] waddr_bin;
    reg [PTR_WIDTH-1:0] raddr_bin;
    reg [PTR_WIDTH-1:0] wptr;
    reg [PTR_WIDTH-1:0] rptr;

    reg [PTR_WIDTH-1:0] rptr_buff1;
    reg [PTR_WIDTH-1:0] rptr_buff;
    reg [PTR_WIDTH-1:0] wptr_buff1;
    reg [PTR_WIDTH-1:0] wptr_buff;

    reg wfull_reg;
    reg rempty_reg;

    wire [PTR_WIDTH-1:0] waddr_bin_next;
    wire [PTR_WIDTH-1:0] raddr_bin_next;
    wire [PTR_WIDTH-1:0] wptr_next;
    wire [PTR_WIDTH-1:0] rptr_next;

    wire winc_en;
    wire rinc_en;

    assign winc_en = winc && !wfull_reg;
    assign rinc_en = rinc && !rempty_reg;

    assign waddr_bin_next = waddr_bin + winc_en;
    assign raddr_bin_next = raddr_bin + rinc_en;

    assign wptr_next = (waddr_bin_next >> 1) ^ waddr_bin_next;
    assign rptr_next = (raddr_bin_next >> 1) ^ raddr_bin_next;

    wire wfull_val;
    wire rempty_val;

    assign wfull_val = (wptr_next == {~rptr_buff[PTR_WIDTH-1:PTR_WIDTH-2], rptr_buff[PTR_WIDTH-3:0]});
    assign rempty_val = (rptr_next == wptr_buff);

    always @(posedge wclk or negedge wrstn) begin
        if (!wrstn) begin
            waddr_bin <= {PTR_WIDTH{1'b0}};
            wptr      <= {PTR_WIDTH{1'b0}};
            wfull_reg <= 1'b0;
            rptr_buff1 <= {PTR_WIDTH{1'b0}};
            rptr_buff  <= {PTR_WIDTH{1'b0}};
        end else begin
            waddr_bin <= waddr_bin_next;
            wptr      <= wptr_next;
            wfull_reg <= wfull_val;
            rptr_buff1 <= rptr;
            rptr_buff  <= rptr_buff1;
        end
    end

    always @(posedge rclk or negedge rrstn) begin
        if (!rrstn) begin
            raddr_bin  <= {PTR_WIDTH{1'b0}};
            rptr       <= {PTR_WIDTH{1'b0}};
            rempty_reg <= 1'b1;
            wptr_buff1 <= {PTR_WIDTH{1'b0}};
            wptr_buff  <= {PTR_WIDTH{1'b0}};
        end else begin
            raddr_bin  <= raddr_bin_next;
            rptr       <= rptr_next;
            rempty_reg <= rempty_val;
            wptr_buff1 <= wptr;
            wptr_buff  <= wptr_buff1;
        end
    end

    assign wfull = wfull_reg;
    assign rempty = rempty_reg;

    wire wen = winc && !wfull_reg;
    wire ren = rinc && !rempty_reg;

    dual_port_RAM #(
        .WIDTH(WIDTH),
        .DEPTH(DEPTH)
    ) u_dual_port_RAM (
        .wclk(wclk),
        .wenc(wen),
        .waddr(waddr_bin[ADDR_WIDTH-1:0]),
        .wdata(wdata),
        .rclk(rclk),
        .renc(ren),
        .raddr(raddr_bin[ADDR_WIDTH-1:0]),
        .rdata(rdata)
    );

endmodule
