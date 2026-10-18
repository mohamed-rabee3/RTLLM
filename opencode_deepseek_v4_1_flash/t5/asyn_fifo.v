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

    reg [PTR_WIDTH-1:0] waddr_bin, raddr_bin;
    reg [PTR_WIDTH-1:0] wptr, rptr;
    reg [PTR_WIDTH-1:0] wq1, wq2, rq1, rq2;

    wire wen = winc & ~wfull;
    wire ren = rinc & ~rempty;

    // Write pointer and binary address update
    always @(posedge wclk or negedge wrstn) begin
        if (!wrstn) begin
            waddr_bin <= 0;
            wptr      <= 0;
        end else if (wen) begin
            waddr_bin <= waddr_bin + 1'b1;
            wptr      <= (waddr_bin + 1'b1) ^ ((waddr_bin + 1'b1) >> 1);
        end
    end

    // Read pointer and binary address update
    always @(posedge rclk or negedge rrstn) begin
        if (!rrstn) begin
            raddr_bin <= 0;
            rptr      <= 0;
        end else if (ren) begin
            raddr_bin <= raddr_bin + 1'b1;
            rptr      <= (raddr_bin + 1'b1) ^ ((raddr_bin + 1'b1) >> 1);
        end
    end

    // Synchronize write pointer to read clock domain
    always @(posedge rclk or negedge rrstn) begin
        if (!rrstn) begin
            wq1 <= 0;
            wq2 <= 0;
        end else begin
            wq1 <= wptr;
            wq2 <= wq1;
        end
    end

    // Synchronize read pointer to write clock domain
    always @(posedge wclk or negedge wrstn) begin
        if (!wrstn) begin
            rq1 <= 0;
            rq2 <= 0;
        end else begin
            rq1 <= rptr;
            rq2 <= rq1;
        end
    end

    // Full and empty flags
    assign rempty = (rptr == wq2);
    assign wfull  = (wptr == {~rq2[PTR_WIDTH-1], ~rq2[PTR_WIDTH-2], rq2[PTR_WIDTH-3:0]});

    // Dual-port RAM instantiation
    dual_port_RAM #(
        .WIDTH(WIDTH),
        .DEPTH(DEPTH)
    ) u_ram (
        .wclk  (wclk),
        .wenc  (wen),
        .waddr (waddr_bin[ADDR_WIDTH-1:0]),
        .wdata (wdata),
        .rclk  (rclk),
        .renc  (ren),
        .raddr (raddr_bin[ADDR_WIDTH-1:0]),
        .rdata (rdata)
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
        if (wenc) begin
            RAM_MEM[waddr] <= wdata;
        end
    end

    always @(posedge rclk) begin
        if (renc) begin
            rdata <= RAM_MEM[raddr];
        end
    end

endmodule
