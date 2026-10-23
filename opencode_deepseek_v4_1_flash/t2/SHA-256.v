module sha256_core (
    input clk,
    input reset_n,
    input init,
    input next,
    input mode,
    input [511:0] block,
    output reg ready,
    output reg digest_valid,
    output reg [255:0] digest
);

    localparam IDLE = 2'b00;
    localparam COMPUTE = 2'b01;
    localparam DONE = 2'b10;

    reg [1:0] state;
    reg [6:0] t;
    reg [31:0] H [0:7];
    reg [31:0] W [0:63];
    reg [31:0] a, b, c, d, e, f, g, h;
    reg [31:0] w_cur, T1, T2;
    reg start_block;

    function [31:0] K_func;
        input [5:0] t;
        begin
            case (t)
                6'd0: K_func = 32'h428a2f98;
                6'd1: K_func = 32'h71374491;
                6'd2: K_func = 32'hb5c0fbcf;
                6'd3: K_func = 32'he9b5dba5;
                6'd4: K_func = 32'h3956c25b;
                6'd5: K_func = 32'h59f111f1;
                6'd6: K_func = 32'h923f82a4;
                6'd7: K_func = 32'hab1c5ed5;
                6'd8: K_func = 32'hd807aa98;
                6'd9: K_func = 32'h12835b01;
                6'd10: K_func = 32'h243185be;
                6'd11: K_func = 32'h550c7dc3;
                6'd12: K_func = 32'h72be5d74;
                6'd13: K_func = 32'h80deb1fe;
                6'd14: K_func = 32'h9bdc06a7;
                6'd15: K_func = 32'hc19bf174;
                6'd16: K_func = 32'he49b69c1;
                6'd17: K_func = 32'hefbe4786;
                6'd18: K_func = 32'h0fc19dc6;
                6'd19: K_func = 32'h240ca1cc;
                6'd20: K_func = 32'h2de92c6f;
                6'd21: K_func = 32'h4a7484aa;
                6'd22: K_func = 32'h5cb0a9dc;
                6'd23: K_func = 32'h76f988da;
                6'd24: K_func = 32'h983e5152;
                6'd25: K_func = 32'ha831c66d;
                6'd26: K_func = 32'hb00327c8;
                6'd27: K_func = 32'hbf597fc7;
                6'd28: K_func = 32'hc6e00bf3;
                6'd29: K_func = 32'hd5a79147;
                6'd30: K_func = 32'h06ca6351;
                6'd31: K_func = 32'h14292967;
                6'd32: K_func = 32'h27b70a85;
                6'd33: K_func = 32'h2e1b2138;
                6'd34: K_func = 32'h4d2c6dfc;
                6'd35: K_func = 32'h53380d13;
                6'd36: K_func = 32'h650a7354;
                6'd37: K_func = 32'h766a0abb;
                6'd38: K_func = 32'h81c2c92e;
                6'd39: K_func = 32'h92722c85;
                6'd40: K_func = 32'ha2bfe8a1;
                6'd41: K_func = 32'ha81a664b;
                6'd42: K_func = 32'hc24b8b70;
                6'd43: K_func = 32'hc76c51a3;
                6'd44: K_func = 32'hd192e819;
                6'd45: K_func = 32'hd6990624;
                6'd46: K_func = 32'hf40e3585;
                6'd47: K_func = 32'h106aa070;
                6'd48: K_func = 32'h19a4c116;
                6'd49: K_func = 32'h1e376c08;
                6'd50: K_func = 32'h2748774c;
                6'd51: K_func = 32'h34b0bcb5;
                6'd52: K_func = 32'h391c0cb3;
                6'd53: K_func = 32'h4ed8aa4a;
                6'd54: K_func = 32'h5b9cca4f;
                6'd55: K_func = 32'h682e6ff3;
                6'd56: K_func = 32'h748f82ee;
                6'd57: K_func = 32'h78a5636f;
                6'd58: K_func = 32'h84c87814;
                6'd59: K_func = 32'h8cc70208;
                6'd60: K_func = 32'h90befffa;
                6'd61: K_func = 32'ha4506ceb;
                6'd62: K_func = 32'hbef9a3f7;
                6'd63: K_func = 32'hc67178f2;
                default: K_func = 32'h0;
            endcase
        end
    endfunction

    function [31:0] Sigma0;
        input [31:0] x;
        begin
            Sigma0 = {x[1:0], x[31:2]} ^ {x[12:0], x[31:13]} ^ {x[21:0], x[31:22]};
        end
    endfunction

    function [31:0] Sigma1;
        input [31:0] x;
        begin
            Sigma1 = {x[5:0], x[31:6]} ^ {x[10:0], x[31:11]} ^ {x[24:0], x[31:25]};
        end
    endfunction

    function [31:0] sigma0;
        input [31:0] x;
        begin
            sigma0 = {x[6:0], x[31:7]} ^ {x[17:0], x[31:18]} ^ (x >> 3);
        end
    endfunction

    function [31:0] sigma1;
        input [31:0] x;
        begin
            sigma1 = {x[16:0], x[31:17]} ^ {x[18:0], x[31:19]} ^ (x >> 10);
        end
    endfunction

    function [31:0] Ch;
        input [31:0] x, y, z;
        begin
            Ch = (x & y) ^ ((~x) & z);
        end
    endfunction

    function [31:0] Maj;
        input [31:0] x, y, z;
        begin
            Maj = (x & y) ^ (x & z) ^ (y & z);
        end
    endfunction

    always @* begin
        start_block = 1'b0;
        if ((state == IDLE || state == DONE) && (init || next))
            start_block = 1'b1;
    end

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            state <= IDLE;
            t <= 7'd0;
            ready <= 1'b1;
            digest_valid <= 1'b0;
            H[0] <= 32'h6a09e667;
            H[1] <= 32'hbb67ae85;
            H[2] <= 32'h3c6ef372;
            H[3] <= 32'ha54ff53a;
            H[4] <= 32'h510e527f;
            H[5] <= 32'h9b05688c;
            H[6] <= 32'h1f83d9ab;
            H[7] <= 32'h5be0cd19;
            a <= 32'h0; b <= 32'h0; c <= 32'h0; d <= 32'h0;
            e <= 32'h0; f <= 32'h0; g <= 32'h0; h <= 32'h0;
            digest <= 256'h0;
        end else begin
            if (start_block) begin
                W[0] <= block[511:480];
                W[1] <= block[479:448];
                W[2] <= block[447:416];
                W[3] <= block[415:384];
                W[4] <= block[383:352];
                W[5] <= block[351:320];
                W[6] <= block[319:288];
                W[7] <= block[287:256];
                W[8] <= block[255:224];
                W[9] <= block[223:192];
                W[10] <= block[191:160];
                W[11] <= block[159:128];
                W[12] <= block[127:96];
                W[13] <= block[95:64];
                W[14] <= block[63:32];
                W[15] <= block[31:0];

                if (init) begin
                    H[0] <= 32'h6a09e667;
                    H[1] <= 32'hbb67ae85;
                    H[2] <= 32'h3c6ef372;
                    H[3] <= 32'ha54ff53a;
                    H[4] <= 32'h510e527f;
                    H[5] <= 32'h9b05688c;
                    H[6] <= 32'h1f83d9ab;
                    H[7] <= 32'h5be0cd19;
                    a <= 32'h6a09e667;
                    b <= 32'hbb67ae85;
                    c <= 32'h3c6ef372;
                    d <= 32'ha54ff53a;
                    e <= 32'h510e527f;
                    f <= 32'h9b05688c;
                    g <= 32'h1f83d9ab;
                    h <= 32'h5be0cd19;
                end else begin
                    a <= H[0];
                    b <= H[1];
                    c <= H[2];
                    d <= H[3];
                    e <= H[4];
                    f <= H[5];
                    g <= H[6];
                    h <= H[7];
                end
                t <= 7'd0;
                state <= COMPUTE;
                ready <= 1'b0;
                digest_valid <= 1'b0;
            end else begin
                case (state)
                    IDLE: begin
                        ready <= 1'b1;
                        digest_valid <= 1'b0;
                    end
                    COMPUTE: begin
                        if (t < 7'd16)
                            w_cur = W[t];
                        else
                            w_cur = sigma1(W[t-2]) + W[t-7] + sigma0(W[t-15]) + W[t-16];
                        if (t >= 7'd16)
                            W[t] <= w_cur;

                        T1 = h + Sigma1(e) + Ch(e,f,g) + K_func(t[5:0]) + w_cur;
                        T2 = Sigma0(a) + Maj(a,b,c);

                        h <= g;
                        g <= f;
                        f <= e;
                        e <= d + T1;
                        d <= c;
                        c <= b;
                        b <= a;
                        a <= T1 + T2;

                        if (t == 7'd63) begin
                            H[0] <= H[0] + (T1 + T2);
                            H[1] <= H[1] + a;
                            H[2] <= H[2] + b;
                            H[3] <= H[3] + c;
                            H[4] <= H[4] + (d + T1);
                            H[5] <= H[5] + e;
                            H[6] <= H[6] + f;
                            H[7] <= H[7] + g;
                            state <= DONE;
                            ready <= 1'b1;
                            digest_valid <= 1'b1;
                        end else begin
                            t <= t + 1'b1;
                        end
                    end
                    DONE: begin
                        ready <= 1'b1;
                    end
                endcase
            end
        end
    end

    always @* begin
        digest = {H[0], H[1], H[2], H[3], H[4], H[5], H[6], H[7]};
    end

endmodule


module sha256 (
    input clk,
    input reset_n,
    input cs,
    input we,
    input [7:0] address,
    input [31:0] write_data,
    output reg [31:0] read_data,
    output reg error
);

    wire core_ready;
    wire core_digest_valid;
    wire [255:0] core_digest;
    wire [511:0] core_block;
    reg mode_reg;

    reg [31:0] block_words [0:15];
    reg init_pulse, next_pulse;
    integer i;

    sha256_core u_core (
        .clk(clk),
        .reset_n(reset_n),
        .init(init_pulse),
        .next(next_pulse),
        .mode(mode_reg),
        .block(core_block),
        .ready(core_ready),
        .digest_valid(core_digest_valid),
        .digest(core_digest)
    );

    assign core_block = {block_words[0], block_words[1], block_words[2], block_words[3],
                         block_words[4], block_words[5], block_words[6], block_words[7],
                         block_words[8], block_words[9], block_words[10], block_words[11],
                         block_words[12], block_words[13], block_words[14], block_words[15]};

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            init_pulse <= 1'b0;
            next_pulse <= 1'b0;
            mode_reg <= 1'b0;
            for (i = 0; i < 16; i = i + 1) begin
                block_words[i] <= 32'h0;
            end
        end else begin
            init_pulse <= 1'b0;
            next_pulse <= 1'b0;
            if (cs && we) begin
                case (address)
                    8'h08: begin
                        mode_reg <= write_data[2];
                        if (write_data[0]) init_pulse <= 1'b1;
                        else if (write_data[1]) next_pulse <= 1'b1;
                    end
                    default: begin
                        if (address >= 8'h10 && address <= 8'h1F)
                            block_words[address[3:0]] <= write_data;
                    end
                endcase
            end
        end
    end

    always @* begin
        read_data = 32'h0;
        if (cs && !we) begin
            case (address)
                8'h00: read_data = 32'h53484132;
                8'h01: read_data = 32'h35360000;
                8'h02: read_data = 32'h00000001;
                8'h08: read_data = {29'd0, mode_reg, 2'b00};
                8'h09: read_data = {30'd0, core_digest_valid, core_ready};
                8'h10: read_data = block_words[0];
                8'h11: read_data = block_words[1];
                8'h12: read_data = block_words[2];
                8'h13: read_data = block_words[3];
                8'h14: read_data = block_words[4];
                8'h15: read_data = block_words[5];
                8'h16: read_data = block_words[6];
                8'h17: read_data = block_words[7];
                8'h18: read_data = block_words[8];
                8'h19: read_data = block_words[9];
                8'h1A: read_data = block_words[10];
                8'h1B: read_data = block_words[11];
                8'h1C: read_data = block_words[12];
                8'h1D: read_data = block_words[13];
                8'h1E: read_data = block_words[14];
                8'h1F: read_data = block_words[15];
                8'h20: read_data = core_digest[255:224];
                8'h21: read_data = core_digest[223:192];
                8'h22: read_data = core_digest[191:160];
                8'h23: read_data = core_digest[159:128];
                8'h24: read_data = core_digest[127:96];
                8'h25: read_data = core_digest[95:64];
                8'h26: read_data = core_digest[63:32];
                8'h27: read_data = core_digest[31:0];
                default: read_data = 32'h0;
            endcase
        end
    end

    always @* begin
        error = 1'b0;
        if (cs) begin
            case (address)
                8'h00, 8'h01, 8'h02, 8'h08, 8'h09,
                8'h10, 8'h11, 8'h12, 8'h13, 8'h14, 8'h15, 8'h16, 8'h17,
                8'h18, 8'h19, 8'h1A, 8'h1B, 8'h1C, 8'h1D, 8'h1E, 8'h1F,
                8'h20, 8'h21, 8'h22, 8'h23, 8'h24, 8'h25, 8'h26, 8'h27:
                    error = 1'b0;
                default: error = 1'b1;
            endcase
        end
    end

endmodule
