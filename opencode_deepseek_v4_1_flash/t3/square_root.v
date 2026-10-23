module SQRT(
    input [15:0] value,
    output [7:0] result
);

    reg [17:0] rem;
    reg [8:0] root;
    reg [17:0] trial;

    always @* begin
        rem = 18'd0;
        root = 9'd0;

        // Step 7: process value[15:14]
        rem = (rem << 2) | {16'd0, value[15:14]};
        root = root << 1;
        trial = (root << 1) | 18'd1;
        if (rem >= trial) begin
            rem = rem - trial;
            root = root | 9'd1;
        end

        // Step 6: process value[13:12]
        rem = (rem << 2) | {16'd0, value[13:12]};
        root = root << 1;
        trial = (root << 1) | 18'd1;
        if (rem >= trial) begin
            rem = rem - trial;
            root = root | 9'd1;
        end

        // Step 5: process value[11:10]
        rem = (rem << 2) | {16'd0, value[11:10]};
        root = root << 1;
        trial = (root << 1) | 18'd1;
        if (rem >= trial) begin
            rem = rem - trial;
            root = root | 9'd1;
        end

        // Step 4: process value[9:8]
        rem = (rem << 2) | {16'd0, value[9:8]};
        root = root << 1;
        trial = (root << 1) | 18'd1;
        if (rem >= trial) begin
            rem = rem - trial;
            root = root | 9'd1;
        end

        // Step 3: process value[7:6]
        rem = (rem << 2) | {16'd0, value[7:6]};
        root = root << 1;
        trial = (root << 1) | 18'd1;
        if (rem >= trial) begin
            rem = rem - trial;
            root = root | 9'd1;
        end

        // Step 2: process value[5:4]
        rem = (rem << 2) | {16'd0, value[5:4]};
        root = root << 1;
        trial = (root << 1) | 18'd1;
        if (rem >= trial) begin
            rem = rem - trial;
            root = root | 9'd1;
        end

        // Step 1: process value[3:2]
        rem = (rem << 2) | {16'd0, value[3:2]};
        root = root << 1;
        trial = (root << 1) | 18'd1;
        if (rem >= trial) begin
            rem = rem - trial;
            root = root | 9'd1;
        end

        // Step 0: process value[1:0]
        rem = (rem << 2) | {16'd0, value[1:0]};
        root = root << 1;
        trial = (root << 1) | 18'd1;
        if (rem >= trial) begin
            rem = rem - trial;
            root = root | 9'd1;
        end
    end

    assign result = root[7:0];

endmodule
