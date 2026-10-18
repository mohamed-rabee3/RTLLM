module dual_port_RAM #(
    parameter WIDTH = 8,
    parameter DEPTH = 16
)(
    input  wire                  wclk,
    input  wire                  wenc,
    input  wire [$clog2(DEPTH)-1:0] waddr,
    input  wire [WIDTH-1:0]      wdata,
    input  wire                  rclk,
    input  wire                  renc,
    input  wire [$clog2(DEPTH)-1:0] raddr,
    output reg  [WIDTH-1:0]      rdata
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
    input  wire             wclk,
    input  wire             rclk,
    input  wire             wrstn,
    input  wire             rrstn,
    input  wire             winc,
    input  wire             rinc,
    input  wire [WIDTH-1:0] wdata,
    output wire             wfull,
    output wire             rempty,
    output wire [WIDTH-1:0] rdata
);

    localparam ADDR_WIDTH = $clog2(DEPTH);
    localparam PTR_WIDTH  = ADDR_WIDTH + 1;

    wire [ADDR_WIDTH-1:0] waddr;
    wire [ADDR_WIDTH-1:0] raddr;
    wire                  wen;
    wire                  ren;

    reg  [PTR_WIDTH-1:0] waddr_bin;
    reg  [PTR_WIDTH-1:0] wptr;
    reg  [PTR_WIDTH-1:0] wptr_buff;
    wire [PTR_WIDTH-1:0] waddr_bin_next;
    wire [PTR_WIDTH-1:0] wptr_next;

    reg  [PTR_WIDTH-1:0] raddr_bin;
    reg  [PTR_WIDTH-1:0] rptr;
    reg  [PTR_WIDTH-1:0] rptr_buff;
    wire [PTR_WIDTH-1:0] raddr_bin_next;
    wire [PTR_WIDTH-1:0] rptr_next;

    reg  [PTR_WIDTH-1:0] rptr_syn1;
    reg  [PTR_WIDTH-1:0] rptr_syn2;
    reg  [PTR_WIDTH-1:0] wptr_syn1;
    reg  [PTR_WIDTH-1:0] wptr_syn2;

    wire [PTR_WIDTH-1:0] rptr_syn;
    wire [PTR_WIDTH-1:0] wptr_syn;

    assign rptr_syn = rptr_syn2;
    assign wptr_syn = wptr_syn2;

    assign waddr_bin_next = waddr_bin + (wen ? 1'b1 : 1'b0);
    assign raddr_bin_next = raddr_bin + (ren ? 1'b1 : 1'b0);

    assign wptr_next = (waddr_bin_next >> 1) ^ waddr_bin_next;
    assign rptr_next = (raddr_bin_next >> 1) ^ raddr_bin_next;

    function [PTR_WIDTH-1:0] full_compare;
        input [PTR_WIDTH-1:0] rptr_gray;
        begin
            full_compare = rptr_gray;
            full_compare[PTR_WIDTH-1] = ~rptr_gray[PTR_WIDTH-1];
            full_compare[PTR_WIDTH-2] = ~rptr_gray[PTR_WIDTH-2];
        end
    endfunction

    assign wfull  = (wptr == full_compare(rptr_syn));
    assign rempty = (rptr == wptr_syn);

    assign wen = winc && !wfull;
    assign ren = rinc && !rempty;

    assign waddr = waddr_bin[ADDR_WIDTH-1:0];
    assign raddr = raddr_bin[ADDR_WIDTH-1:0];

    always @(posedge wclk or negedge wrstn) begin
        if (!wrstn) begin
            waddr_bin <= {PTR_WIDTH{1'b0}};
            wptr      <= {PTR_WIDTH{1'b0}};
            wptr_buff <= {PTR_WIDTH{1'b0}};
        end else begin
            waddr_bin <= waddr_bin_next;
            wptr      <= wptr_next;
            wptr_buff <= wptr;
        end
    end

    always @(posedge rclk or negedge rrstn) begin
        if (!rrstn) begin
            raddr_bin <= {PTR_WIDTH{1'b0}};
            rptr      <= {PTR_WIDTH{1'b0}};
            rptr_buff <= {PTR_WIDTH{1'b0}};
        end else begin
            raddr_bin <= raddr_bin_next;
            rptr      <= rptr_next;
            rptr_buff <= rptr;
        end
    end

    always @(posedge wclk or negedge wrstn) begin
        if (!wrstn) begin
            rptr_syn1 <= {PTR_WIDTH{1'b0}};
            rptr_syn2 <= {PTR_WIDTH{1'b0}};
        end else begin
            rptr_syn1 <= rptr;
            rptr_syn2 <= rptr_syn1;
        end
    end

    always @(posedge rclk or negedge rrstn) begin
        if (!rrstn) begin
            wptr_syn1 <= {PTR_WIDTH{1'b0}};
            wptr_syn2 <= {PTR_WIDTH{1'b0}};
        end else begin
            wptr_syn1 <= wptr;
            wptr_syn2 <= wptr_syn1;
        end
    end

    dual_port_RAM #(
        .WIDTH(WIDTH),
        .DEPTH(DEPTH)
    ) dual_port_RAM_inst (
        .wclk (wclk),
        .wenc (wen),
        .waddr(waddr),
        .wdata(wdata),
        .rclk (rclk),
        .renc (ren),
        .raddr(raddr),
        .rdata(rdata)
    );

endmodule
