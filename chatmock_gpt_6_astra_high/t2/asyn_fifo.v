module asyn_fifo #(
    parameter DEPTH = 16,
    parameter WIDTH = 8
) (
    input                  wclk,
    input                  rclk,
    input                  wrstn,
    input                  rrstn,
    input                  winc,
    input                  rinc,
    input      [WIDTH-1:0]  wdata,
    output reg             wfull,
    output reg             rempty,
    output     [WIDTH-1:0]  rdata
);

    // Gray-pointer asynchronous FIFOs require a power-of-two DEPTH >= 2.
    localparam ADDR_WIDTH = $clog2(DEPTH);
    localparam PTR_WIDTH  = ADDR_WIDTH + 1;

    // Invert the two most significant Gray-code bits for full detection.
    localparam [PTR_WIDTH-1:0] FULL_MASK =
        {PTR_WIDTH{1'b1}} << (PTR_WIDTH - 2);

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
    wire                wfull_next;
    wire                rempty_next;

    assign wen = wrstn && winc && !wfull;
    assign ren = rrstn && rinc && !rempty;

    assign waddr_bin_next = waddr_bin + {{(PTR_WIDTH-1){1'b0}}, wen};
    assign raddr_bin_next = raddr_bin + {{(PTR_WIDTH-1){1'b0}}, ren};

    assign wptr_next = (waddr_bin_next >> 1) ^ waddr_bin_next;
    assign rptr_next = (raddr_bin_next >> 1) ^ raddr_bin_next;

    assign wfull_next  = (wptr_next == (rptr_syn ^ FULL_MASK));
    assign rempty_next = (rptr_next == wptr_syn);

    // Write-domain pointer and full flag.
    always @(posedge wclk or negedge wrstn) begin
        if (!wrstn) begin
            waddr_bin <= {PTR_WIDTH{1'b0}};
            wptr      <= {PTR_WIDTH{1'b0}};
            wfull     <= 1'b0;
        end else begin
            waddr_bin <= waddr_bin_next;
            wptr      <= wptr_next;
            wfull     <= wfull_next;
        end
    end

    // Read-domain pointer and empty flag.
    always @(posedge rclk or negedge rrstn) begin
        if (!rrstn) begin
            raddr_bin <= {PTR_WIDTH{1'b0}};
            rptr      <= {PTR_WIDTH{1'b0}};
            rempty    <= 1'b1;
        end else begin
            raddr_bin <= raddr_bin_next;
            rptr      <= rptr_next;
            rempty    <= rempty_next;
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
    input                          wclk,
    input                          wenc,
    input      [$clog2(DEPTH)-1:0]  waddr,
    input      [WIDTH-1:0]          wdata,
    input                          rclk,
    input                          renc,
    input      [$clog2(DEPTH)-1:0]  raddr,
    output reg [WIDTH-1:0]          rdata
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
