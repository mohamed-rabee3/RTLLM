module verified_haar_wavelet_lh_only(
    input                    clk,
    input                    rst_n,
    input                    valid_in,
    input      [3:0]         row,
    input      [3:0]         col,
    input      [7:0]         data_in,
    output reg signed [15:0] data_out,
    output reg               valid_out,
    output reg [2:0]         out_row,
    output reg [2:0]         out_col
);
    // Buffer the image and, as soon as an odd row completes (so a row-pair is
    // available), stream out that LH row's 8 coefficients. This overlaps the
    // output with the load so all 64 coefficients are produced promptly.
    reg [7:0] mem [0:255];
    reg       emit_busy;
    reg [2:0] erow;                 // LH row currently being emitted
    reg [2:0] ecnt;                 // column 0..7 within that row

    integer rr, cc;
    reg signed [15:0] p1, p2;       // mirror the golden's 16-bit signed diff
    reg signed [31:0] lh_top, lh_bot, lh;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_out <= 1'b0;
            emit_busy <= 1'b0;
            ecnt      <= 3'd0;
            erow      <= 3'd0;
        end else begin
            valid_out <= 1'b0;

            // ---- load ----
            if (valid_in) begin
                mem[{row, col}] <= data_in;
                // when an odd row's last pixel arrives, both rows of a pair
                // (row-1, row) are in memory -> emit LH row = row>>1
                if (col == 4'd15 && row[0] == 1'b1) begin
                    erow      <= row[3:1];
                    ecnt      <= 3'd0;
                    emit_busy <= 1'b1;
                end
            end

            // ---- emit (may run concurrently with load) ----
            if (emit_busy) begin
                rr = erow;
                cc = ecnt;
                p1 = mem[(2*rr)*16 + (2*cc)];
                p2 = mem[(2*rr)*16 + (2*cc) + 1];
                lh_top = (p1 - p2) * 181 / 256;
                p1 = mem[(2*rr+1)*16 + (2*cc)];
                p2 = mem[(2*rr+1)*16 + (2*cc) + 1];
                lh_bot = (p1 - p2) * 181 / 256;
                lh = (lh_top + lh_bot) * 181 / 256;

                data_out  <= lh[15:0];
                out_row   <= erow;
                out_col   <= ecnt;
                valid_out <= 1'b1;

                if (ecnt == 3'd7)
                    emit_busy <= 1'b0;
                ecnt <= ecnt + 3'd1;
            end
        end
    end
endmodule
