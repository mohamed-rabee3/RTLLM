module RAM (
    clk,
    rst_n,
    write_en,
    write_addr,
    write_data,
    read_en,
    read_addr,
    read_data
);

parameter WIDTH = 6;
parameter DEPTH = 8;
localparam ADDR_WIDTH = $clog2(DEPTH);

input clk;
input rst_n;
input write_en;
input [ADDR_WIDTH-1:0] write_addr;
input [WIDTH-1:0] write_data;
input read_en;
input [ADDR_WIDTH-1:0] read_addr;
output reg [WIDTH-1:0] read_data;

reg [WIDTH-1:0] RAM [0:DEPTH-1];
integer i;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (i = 0; i < DEPTH; i = i + 1) begin
            RAM[i] <= {WIDTH{1'b0}};
        end
    end
    else if (write_en) begin
        RAM[write_addr] <= write_data;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        read_data <= {WIDTH{1'b0}};
    end
    else if (read_en) begin
        read_data <= RAM[read_addr];
    end
    else begin
        read_data <= {WIDTH{1'b0}};
    end
end

endmodule
