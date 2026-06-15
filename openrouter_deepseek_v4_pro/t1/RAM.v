module RAM #(
    parameter WIDTH = 6,
    parameter DEPTH = 8
) (
    input  wire                clk,
    input  wire                rst_n,
    input  wire                write_en,
    input  wire [2:0]          write_addr,   // 3-bit address for depth of 8
    input  wire [WIDTH-1:0]    write_data,
    input  wire                read_en,
    input  wire [2:0]          read_addr,    // 3-bit address for depth of 8
    output reg  [WIDTH-1:0]    read_data
);
    // Memory array: 8 locations of 6-bit data
    // (Note: The original spec had a typo in the array definition;
    //  this matches the stated depth=8 and bit width=6.)
    reg [WIDTH-1:0] RAM [0:DEPTH-1];

    integer i;

    // Write operation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < DEPTH; i = i + 1) begin
                RAM[i] <= {WIDTH{1'b0}};
            end
        end else if (write_en) begin
            RAM[write_addr] <= write_data;
        end
    end

    // Read operation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            read_data <= {WIDTH{1'b0}};
        end else if (read_en) begin
            read_data <= RAM[read_addr];
        end else begin
            read_data <= {WIDTH{1'b0}};
        end
    end

endmodule