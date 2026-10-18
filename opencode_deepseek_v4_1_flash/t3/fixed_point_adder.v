module fixed_point_adder #(
    parameter Q = 8,
    parameter N = 16
)(
    input  [N-1:0] a,
    input  [N-1:0] b,
    output [N-1:0] c
);

    reg [N-1:0] res;
    reg [N-1:0] sum_mag;
    reg [N-1:0] diff_mag;

    always @(*) begin
        res      = {N{1'b0}};
        sum_mag  = {N{1'b0}};
        diff_mag = {N{1'b0}};

        if (a[N-1] == b[N-1]) begin
            // Same sign: add absolute values
            sum_mag = {1'b0, a[N-2:0]} + {1'b0, b[N-2:0]};

            if (sum_mag[N-1]) begin
                // Overflow: saturate to maximum magnitude with the same sign
                if (a[N-1] == 1'b0)
                    res = {1'b0, {N-1{1'b1}}};
                else
                    res = {1'b1, {N-1{1'b1}}};
            end else begin
                res = {a[N-1], sum_mag[N-2:0]};
            end
        end else begin
            // Different signs: subtract smaller magnitude from larger
            if (a[N-2:0] > b[N-2:0]) begin
                diff_mag = {1'b0, a[N-2:0]} - {1'b0, b[N-2:0]};
                res      = {a[N-1], diff_mag[N-2:0]};
            end else if (b[N-2:0] > a[N-2:0]) begin
                diff_mag = {1'b0, b[N-2:0]} - {1'b0, a[N-2:0]};
                res      = {b[N-1], diff_mag[N-2:0]};
            end else begin
                res = {N{1'b0}};
            end
        end
    end

    assign c = res;

endmodule
