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

    reg [PTR_WIDTH-1:0] rptr_buff;
    reg [PTR_WIDTH-1:0] rptr_syn;
    reg [PTR_WIDTH-1:0] wptr_buff;
    reg [PTR_WIDTH-1:0] wptr_syn;

    wire [ADDR_WIDTH-1:0] waddr;
    wire [ADDR_WIDTH-1:0] raddr;
    wire wen;
    wire ren;

    assign waddr = waddr_bin[ADDR_WIDTH-1:0];
    assign raddr = raddr_bin[ADDR_WIDTH-1:0];

    assign wen = winc && !wfull;
    assign ren = rinc && !rempty;

    always @(posedge wclk or negedge wrstn) begin
        if (!wrstn) begin
            waddr_bin <= {PTR_WIDTH{1'b0}};
            wptr      <= {PTR_WIDTH{1'b0}};
        end
        else if (winc && !wfull) begin
            waddr_bin <= waddr_bin + 1'b1;
            wptr      <= (waddr_bin + 1'b1) ^ ((waddr_bin + 1'b1) >> 1);
        end
    end

    always @(posedge rclk or negedge rrstn) begin
        if (!rrstn) begin
            raddr_bin <= {PTR_WIDTH{1'b0}};
            rptr      <= {PTR_WIDTH{1'b0}};
        end
        else if (rinc && !rempty) begin
            raddr_bin <= raddr_bin + 1'b1;
            rptr      <= (raddr_bin + 1'b1) ^ ((raddr_bin + 1'b1) >> 1);
        end
    end

    always @(posedge wclk or negedge wrstn) begin
        if (!wrstn) begin
            rptr_buff <= {PTR_WIDTH{1'b0}};
            rptr_syn  <= {PTR_WIDTH{1'b0}};
        end
        else begin
            rptr_buff <= rptr;
            rptr_syn  <= rptr_buff;
        end
    end

    always @(posedge rclk or negedge rrstn) begin
        if (!rrstn) begin
            wptr_buff <= {PTR_WIDTH{1'b0}};
            wptr_syn  <= {PTR_WIDTH{1'b0}};
        end
        else begin
            wptr_buff <= wptr;
            wptr_syn  <= wptr_buff;
        end
    end

    assign rempty = (rptr == wptr_syn);
    assign wfull  = (wptr == {~rptr_syn[PTR_WIDTH-1:PTR_WIDTH-2], rptr_syn[PTR_WIDTH-3:0]});

    dual_port_RAM #(
        .WIDTH(WIDTH),
        .DEPTH(DEPTH)
    ) u_dual_port_RAM (
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
