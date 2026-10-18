module fixed_point_adder #(
    parameter Q = 4,
    parameter N = 8
) (
    input [N-1:0] a,
    input [N-1:0] b,
    output [N-1:0] c
);

    reg [N-1:0] res;

    generate
        if (N > 1) begin : g_adder
            localparam MAGW = N - 1;
            wire sign_a = a[N-1];
            wire sign_b = b[N-1];
            wire [MAGW-1:0] mag_a = a[MAGW-1:0];
            wire [MAGW-1:0] mag_b = b[MAGW-1:0];

            reg [MAGW-1:0] mag_res;
            reg sign_res;
            reg [MAGW:0] mag_sum;

            always @(*) begin
                if (sign_a == sign_b) begin
                    mag_sum = {1'b0, mag_a} + {1'b0, mag_b};
                    if (mag_sum[MAGW]) begin
                        mag_res = {MAGW{1'b1}};
                    end else begin
                        mag_res = mag_sum[MAGW-1:0];
                    end
                    sign_res = sign_a;
                end else begin
                    if (mag_a >= mag_b) begin
                        mag_res = mag_a - mag_b;
                        if (mag_a == mag_b)
                            sign_res = 1'b0;
                        else
                            sign_res = sign_a;
                    end else begin
                        mag_res = mag_b - mag_a;
                        sign_res = sign_b;
                    end
                end
                res = {sign_res, mag_res};
            end
        end else begin : g_single
            always @(*) begin
                if (a[0] == b[0]) begin
                    res = a[0];
                end else begin
                    res = 1'b0;
                end
            end
        end
    endgenerate

    assign c = res;

endmodule
