module dual_port_RAM #(
    parameter WIDTH = 8,
    parameter DEPTH = 16
) (
    input                       wclk,
    input                       wenc,
    input  [$clog2(DEPTH)-1:0]  waddr,
    input  [WIDTH-1:0]          wdata,
    input                       rclk,
    input                       renc,
    input  [$clog2(DEPTH)-1:0]  raddr,
    output reg [WIDTH-1:0]      rdata
);
    reg [WIDTH-1:0] mem [0:DEPTH-1];

    // Write operation
    always @(posedge wclk) begin
        if (wenc)
            mem[waddr] <= wdata;
    end

    // Read operation
    always @(posedge rclk) begin
        if (renc)
            rdata <= mem[raddr];
    end
endmodule

module asyn_fifo #(
    parameter WIDTH = 8,
    parameter DEPTH = 16
) (
    input                       wclk,
    input                       rclk,
    input                       wrstn,
    input                       rrstn,
    input                       winc,
    input                       rinc,
    input  [WIDTH-1:0]          wdata,
    output                      wfull,
    output                      rempty,
    output [WIDTH-1:0]          rdata
);
    localparam ADDR_WIDTH = $clog2(DEPTH);
    localparam PTR_WIDTH  = ADDR_WIDTH + 1;

    // Full condition mask: two MSBs of the pointer XOR result
    localparam [PTR_WIDTH-1:0] FULL_MASK = (PTR_WIDTH >= 2) ?
        ((1 << (PTR_WIDTH-1)) | (1 << (PTR_WIDTH-2))) : 0;

    // Binary pointers (extra MSB for full/empty distinction)
    reg  [PTR_WIDTH-1:0] waddr_bin, raddr_bin;

    // Gray‑coded pointers (registered)
    reg  [PTR_WIDTH-1:0] wptr, rptr;

    // Two‑stage synchronizer registers
    reg  [PTR_WIDTH-1:0] rptr_buff, rptr_syn;   // in write clock domain
    reg  [PTR_WIDTH-1:0] wptr_buff, wptr_syn;   // in read clock domain

    // Internal enables
    wire wenc, renc;

    // Full and empty generation
    wire wfull_comb, rempty_comb;

    assign wfull_comb = ((wptr ^ rptr_syn) == FULL_MASK);
    assign rempty_comb = (rptr == wptr_syn);

    assign wfull  = wfull_comb;
    assign rempty = rempty_comb;

    // Write/read enables (inhibit when full/empty)
    assign wenc = winc & ~wfull;
    assign renc = rinc & ~rempty;

    // ----- Write pointer logic (write domain) -----
    always @(posedge wclk or negedge wrstn) begin
        if (!wrstn) begin
            waddr_bin <= {PTR_WIDTH{1'b0}};
        end else if (wenc) begin
            waddr_bin <= waddr_bin + 1'b1;
        end
    end

    always @(posedge wclk or negedge wrstn) begin
        if (!wrstn) begin
            wptr <= {PTR_WIDTH{1'b0}};
        end else begin
            wptr <= waddr_bin ^ {1'b0, waddr_bin[PTR_WIDTH-1:1]};
        end
    end

    // ----- Read pointer logic (read domain) -----
    always @(posedge rclk or negedge rrstn) begin
        if (!rrstn) begin
            raddr_bin <= {PTR_WIDTH{1'b0}};
        end else if (renc) begin
            raddr_bin <= raddr_bin + 1'b1;
        end
    end

    always @(posedge rclk or negedge rrstn) begin
        if (!rrstn) begin
            rptr <= {PTR_WIDTH{1'b0}};
        end else begin
            rptr <= raddr_bin ^ {1'b0, raddr_bin[PTR_WIDTH-1:1]};
        end
    end

    // ----- Read pointer synchronizer (write domain) -----
    always @(posedge wclk or negedge wrstn) begin
        if (!wrstn) begin
            {rptr_syn, rptr_buff} <= {PTR_WIDTH*2{1'b0}};
        end else begin
            {rptr_syn, rptr_buff} <= {rptr_buff, rptr};
        end
    end

    // ----- Write pointer synchronizer (read domain) -----
    always @(posedge rclk or negedge rrstn) begin
        if (!rrstn) begin
            {wptr_syn, wptr_buff} <= {PTR_WIDTH*2{1'b0}};
        end else begin
            {wptr_syn, wptr_buff} <= {wptr_buff, wptr};
        end
    end

    // ----- RAM address generation -----
    wire [ADDR_WIDTH-1:0] waddr = waddr_bin[ADDR_WIDTH-1:0];
    wire [ADDR_WIDTH-1:0] raddr = raddr_bin[ADDR_WIDTH-1:0];

    // ----- Dual‑port RAM instantiation -----
    dual_port_RAM #(
        .WIDTH(WIDTH),
        .DEPTH(DEPTH)
    ) u_ram (
        .wclk (wclk),
        .wenc (wenc),
        .waddr(waddr),
        .wdata(wdata),
        .rclk (rclk),
        .renc (renc),
        .raddr(raddr),
        .rdata(rdata)
    );

endmodule