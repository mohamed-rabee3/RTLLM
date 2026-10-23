module asyn_fifo #(
    parameter WIDTH = 8,
    parameter DEPTH = 16
) (
    input  wire                 wclk,
    input  wire                 rclk,
    input  wire                 wrstn,
    input  wire                 rrstn,
    input  wire                 winc,
    input  wire                 rinc,
    input  wire [WIDTH-1:0]     wdata,
    output wire                 wfull,
    output wire                 rempty,
    output wire [WIDTH-1:0]     rdata
);

    // The Gray-pointer FIFO requires a power-of-two DEPTH of at least 2.
    localparam ADDR_WIDTH = $clog2(DEPTH);
    localparam PTR_WIDTH  = ADDR_WIDTH + 1;
    localparam [PTR_WIDTH-1:0] FULL_MASK =
        {2'b11, {(ADDR_WIDTH-1){1'b0}}};

    reg [PTR_WIDTH-1:0] waddr_bin;
    reg [PTR_WIDTH-1:0] raddr_bin;
    reg [PTR_WIDTH-1:0] wptr;
    reg [PTR_WIDTH-1:0] rptr;

    (* ASYNC_REG = "TRUE" *) reg [PTR_WIDTH-1:0] rptr_buff;
    (* ASYNC_REG = "TRUE" *) reg [PTR_WIDTH-1:0] rptr_syn;
    (* ASYNC_REG = "TRUE" *) reg [PTR_WIDTH-1:0] wptr_buff;
    (* ASYNC_REG = "TRUE" *) reg [PTR_WIDTH-1:0] wptr_syn;

    wire wen;
    wire ren;
    wire [PTR_WIDTH-1:0] waddr_bin_next;
    wire [PTR_WIDTH-1:0] raddr_bin_next;
    wire [PTR_WIDTH-1:0] wptr_next;
    wire [PTR_WIDTH-1:0] rptr_next;

    assign wfull  = (wptr == (rptr_syn ^ FULL_MASK));
    assign rempty = (rptr == wptr_syn);

    assign wen = wrstn && winc && !wfull;
    assign ren = rrstn && rinc && !rempty;

    assign waddr_bin_next =
        waddr_bin + {{(PTR_WIDTH-1){1'b0}}, wen};
    assign raddr_bin_next =
        raddr_bin + {{(PTR_WIDTH-1){1'b0}}, ren};

    assign wptr_next = (waddr_bin_next >> 1) ^ waddr_bin_next;
    assign rptr_next = (raddr_bin_next >> 1) ^ raddr_bin_next;

    // Write-domain pointer controller.
    always @(posedge wclk or negedge wrstn) begin
        if (!wrstn) begin
            waddr_bin <= {PTR_WIDTH{1'b0}};
            wptr      <= {PTR_WIDTH{1'b0}};
        end else begin
            waddr_bin <= waddr_bin_next;
            wptr      <= wptr_next;
        end
    end

    // Read-domain pointer controller.
    always @(posedge rclk or negedge rrstn) begin
        if (!rrstn) begin
            raddr_bin <= {PTR_WIDTH{1'b0}};
            rptr      <= {PTR_WIDTH{1'b0}};
        end else begin
            raddr_bin <= raddr_bin_next;
            rptr      <= rptr_next;
        end
    end

    // Synchronize the read Gray pointer into the write clock domain.
    always @(posedge wclk or negedge wrstn) begin
        if (!wrstn) begin
            rptr_buff <= {PTR_WIDTH{1'b0}};
            rptr_syn  <= {PTR_WIDTH{1'b0}};
        end else begin
            rptr_buff <= rptr;
            rptr_syn  <= rptr_buff;
        end
    end

    // Synchronize the write Gray pointer into the read clock domain.
    always @(posedge rclk or negedge rrstn) begin
        if (!rrstn) begin
            wptr_buff <= {PTR_WIDTH{1'b0}};
            wptr_syn  <= {PTR_WIDTH{1'b0}};
        end else begin
            wptr_buff <= wptr;
            wptr_syn  <= wptr_buff;
        end
    end

    dual_port_RAM #(
        .DEPTH (DEPTH),
        .WIDTH (WIDTH)
    ) u_dual_port_RAM (
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
    parameter DEPTH = 16,
    parameter WIDTH = 8
) (
    input  wire                         wclk,
    input  wire                         wenc,
    input  wire [$clog2(DEPTH)-1:0]     waddr,
    input  wire [WIDTH-1:0]             wdata,
    input  wire                         rclk,
    input  wire                         renc,
    input  wire [$clog2(DEPTH)-1:0]     raddr,
    output reg  [WIDTH-1:0]             rdata
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
