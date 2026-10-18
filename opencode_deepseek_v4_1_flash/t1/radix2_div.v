module radix2_div (
    input clk,
    input rst,
    input sign,
    input [7:0] dividend,
    input [7:0] divisor,
    input opn_valid,
    output reg res_valid,
    output reg [15:0] result
);

    reg busy;
    reg [3:0] cnt;
    reg [8:0] A;
    reg [7:0] Q;
    reg [7:0] M;
    reg sign_q;
    reg sign_r;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            busy <= 1'b0;
            res_valid <= 1'b0;
            cnt <= 4'd0;
            A <= 9'd0;
            Q <= 8'd0;
            M <= 8'd0;
            sign_q <= 1'b0;
            sign_r <= 1'b0;
            result <= 16'd0;
        end else begin
            if (!busy) begin
                if (opn_valid) begin
                    busy <= 1'b1;
                    res_valid <= 1'b0;
                    cnt <= 4'd0;
                    A <= 9'd0;
                    Q <= (sign && dividend[7]) ? -dividend : dividend;
                    M <= (sign && divisor[7]) ? -divisor : divisor;
                    sign_q <= sign && (dividend[7] ^ divisor[7]);
                    sign_r <= sign && dividend[7];
                end
            end else begin
                if (cnt < 4'd8) begin
                    if ({A[7:0], Q[7]} >= {1'b0, M}) begin
                        A <= {A[7:0], Q[7]} - {1'b0, M};
                        Q <= {Q[6:0], 1'b1};
                    end else begin
                        A <= {A[7:0], Q[7]};
                        Q <= {Q[6:0], 1'b0};
                    end
                    cnt <= cnt + 1'b1;
                end else begin
                    busy <= 1'b0;
                    res_valid <= 1'b1;
                    result <= { sign_r ? -A[7:0] : A[7:0],
                                sign_q ? -Q : Q };
                end
            end
        end
    end

endmodule
