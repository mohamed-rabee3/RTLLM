module sha256_core (
    input clk,
    input reset_n,
    input init,
    input next,
    input mode,
    input [511:0] block,
    output ready,
    output digest_valid,
    output [255:0] digest
);

    localparam [31:0] IV0 = 32'h6a09e667;
    localparam [31:0] IV1 = 32'hbb67ae85;
    localparam [31:0] IV2 = 32'h3c6ef372;
    localparam [31:0] IV3 = 32'ha54ff53a;
    localparam [31:0] IV4 = 32'h510e527f;
    localparam [31:0] IV5 = 32'h9b05688c;
    localparam [31:0] IV6 = 32'h1f83d9ab;
    localparam [31:0] IV7 = 32'h5be0cd19;

    function [31:0] K;
        input [6:0] t;
        begin
            case (t)
                7'd0: K = 32'h428a2f98;
                7'd1: K = 32'h71374491;
                7'd2: K = 32'hb5c0fbcf;
                7'd3: K = 32'he9b5dba5;
                7'd4: K = 32'h3956c25b;
                7'd5: K = 32'h59f111f1;
                7'd6: K = 32'h923f82a4;
                7'd7: K = 32'hab1c5ed5;
                7'd8: K = 32'hd807aa98;
                7'd9: K = 32'h12835b01;
                7'd10: K = 32'h243185be;
                7'd11: K = 32'h550c7dc3;
                7'd12: K = 32'h72be5d74;
                7'd13: K = 32'h80deb1fe;
                7'd14: K = 32'h9bdc06a7;
                7'd15: K = 32'hc19bf174;
                7'd16: K = 32'he49b69c1;
                7'd17: K = 32'hefbe4786;
                7'd18: K = 32'h0fc19dc6;
                7'd19: K = 32'h240ca1cc;
                7'd20: K = 32'h2de92c6f;
                7'd21: K = 32'h4a7484aa;
                7'd22: K = 32'h5cb0a9dc;
                7'd23: K = 32'h76f988da;
                7'd24: K = 32'h983e5152;
                7'd25: K = 32'ha831c66d;
                7'd26: K = 32'hb00327c8;
                7'd27: K = 32'hbf597fc7;
                7'd28: K = 32'hc6e00bf3;
                7'd29: K = 32'hd5a79147;
                7'd30: K = 32'h06ca6351;
                7'd31: K = 32'h14292967;
                7'd32: K = 32'h27b70a85;
                7'd33: K = 32'h2e1b2138;
                7'd34: K = 32'h4d2c6dfc;
                7'd35: K = 32'h53380d13;
                7'd36: K = 32'h650a7354;
                7'd37: K = 32'h766a0abb;
                7'd38: K = 32'h81c2c92e;
                7'd39: K = 32'h92722c85;
                7'd40: K = 32'ha2bfe8a1;
                7'd41: K = 32'ha81a664b;
                7'd42: K = 32'hc24b8b70;
                7'd43: K = 32'hc76c51a3;
                7'd44: K = 32'hd192e819;
                7'd45: K = 32'hd6990624;
                7'd46: K = 32'hf40e3585;
                7'd47: K = 32'h106aa070;
                7'd48: K = 32'h19a4c116;
                7'd49: K = 32'h1e376c08;
                7'd50: K = 32'h2748774c;
                7'd51: K = 32'h34b0bcb5;
                7'd52: K = 32'h391c0cb3;
                7'd53: K = 32'h4ed8aa4a;
                7'd54: K = 32'h5b9cca4f;
                7'd55: K = 32'h682e6ff3;
                7'd56: K = 32'h748f82ee;
                7'd57: K = 32'h78a5636f;
                7'd58: K = 32'h84c87814;
                7'd59: K = 32'h8cc70208;
                7'd60: K = 32'h90befffa;
                7'd61: K = 32'ha4506ceb;
                7'd62: K = 32'hbef9a3f7;
                7'd63: K = 32'hc67178f2;
                default: K = 32'h00000000;
            endcase
        end
    endfunction

    function [31:0] rotr;
        input [31:0] x;
        input [4:0] n;
        begin
            rotr = (x >> n) | (x << (32 - n));
        end
    endfunction

    function [31:0] sigma0;
        input [31:0] x;
        begin
            sigma0 = rotr(x, 7) ^ rotr(x, 18) ^ (x >> 3);
        end
    endfunction

    function [31:0] sigma1;
        input [31:0] x;
        begin
            sigma1 = rotr(x, 17) ^ rotr(x, 19) ^ (x >> 10);
        end
    endfunction

    function [31:0] Sigma0;
        input [31:0] x;
        begin
            Sigma0 = rotr(x, 2) ^ rotr(x, 13) ^ rotr(x, 22);
        end
    endfunction

    function [31:0] Sigma1;
        input [31:0] x;
        begin
            Sigma1 = rotr(x, 6) ^ rotr(x, 11) ^ rotr(x, 25);
        end
    endfunction

    function [31:0] Ch;
        input [31:0] x, y, z;
        begin
            Ch = (x & y) ^ (~x & z);
        end
    endfunction

    function [31:0] Maj;
        input [31:0] x, y, z;
        begin
            Maj = (x & y) ^ (x & z) ^ (y & z);
        end
    endfunction

    reg [31:0] H [0:7];
    reg [31:0] W [0:63];
    reg [31:0] a, b, c, d, e, f, g, h;
    reg [6:0] t;
    reg busy;
    reg digest_valid_reg;

    integer i;

    wire [5:0] t_minus_2 = t[5:0] - 6'd2;
    wire [5:0] t_minus_7 = t[5:0] - 6'd7;
    wire [5:0] t_minus_15 = t[5:0] - 6'd15;
    wire [5:0] t_minus_16 = t[5:0] - 6'd16;
    wire [31:0] w_t = (t < 16) ? W[t[5:0]] : (sigma1(W[t_minus_2]) + W[t_minus_7] + sigma0(W[t_minus_15]) + W[t_minus_16]);

    wire [31:0] T1 = h + Sigma1(e) + Ch(e, f, g) + K(t) + w_t;
    wire [31:0] T2 = Sigma0(a) + Maj(a, b, c);

    assign ready = ~busy;
    assign digest_valid = digest_valid_reg;
    assign digest = {H[0], H[1], H[2], H[3], H[4], H[5], H[6], H[7]};

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            busy <= 1'b0;
            t <= 7'd0;
            digest_valid_reg <= 1'b0;
            H[0] <= IV0;
            H[1] <= IV1;
            H[2] <= IV2;
            H[3] <= IV3;
            H[4] <= IV4;
            H[5] <= IV5;
            H[6] <= IV6;
            H[7] <= IV7;
            a <= 32'b0;
            b <= 32'b0;
            c <= 32'b0;
            d <= 32'b0;
            e <= 32'b0;
            f <= 32'b0;
            g <= 32'b0;
            h <= 32'b0;
        end else begin
            digest_valid_reg <= 1'b0;
            if (!busy) begin
                if (init || next) begin
                    busy <= 1'b1;
                    t <= 7'd0;
                    for (i = 0; i < 16; i = i + 1) begin
                        W[i] <= block[511 - 32*i -: 32];
                    end
                    if (init) begin
                        H[0] <= IV0; H[1] <= IV1; H[2] <= IV2; H[3] <= IV3;
                        H[4] <= IV4; H[5] <= IV5; H[6] <= IV6; H[7] <= IV7;
                        a <= IV0; b <= IV1; c <= IV2; d <= IV3;
                        e <= IV4; f <= IV5; g <= IV6; h <= IV7;
                    end else begin
                        a <= H[0]; b <= H[1]; c <= H[2]; d <= H[3];
                        e <= H[4]; f <= H[5]; g <= H[6]; h <= H[7];
                    end
                end
            end else begin
                if (t < 7'd64) begin
                    if (t >= 16) begin
                        W[t[5:0]] <= w_t;
                    end
                    a <= T1 + T2;
                    b <= a;
                    c <= b;
                    d <= c;
                    e <= d + T1;
                    f <= e;
                    g <= f;
                    h <= g;
                    if (t == 7'd63) begin
                        H[0] <= H[0] + (T1 + T2);
                        H[1] <= H[1] + a;
                        H[2] <= H[2] + b;
                        H[3] <= H[3] + c;
                        H[4] <= H[4] + (d + T1);
                        H[5] <= H[5] + e;
                        H[6] <= H[6] + f;
                        H[7] <= H[7] + g;
                        busy <= 1'b0;
                        digest_valid_reg <= 1'b1;
                        t <= 7'd0;
                    end else begin
                        t <= t + 1;
                    end
                end
            end
        end
    end

endmodule

module sha256 (
    input clk,
    input reset_n,
    input cs,
    input we,
    input [7:0] address,
    input [31:0] write_data,
    output [31:0] read_data,
    output error
);

    reg [511:0] block_reg;
    reg mode_reg;
    reg init_pulse_reg;
    reg next_pulse_reg;

    wire ready;
    wire digest_valid;
    wire [255:0] digest;

    sha256_core u_core (
        .clk(clk),
        .reset_n(reset_n),
        .init(init_pulse_reg),
        .next(next_pulse_reg),
        .mode(mode_reg),
        .block(block_reg),
        .ready(ready),
        .digest_valid(digest_valid),
        .digest(digest)
    );

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            block_reg <= 512'b0;
            mode_reg <= 1'b0;
            init_pulse_reg <= 1'b0;
            next_pulse_reg <= 1'b0;
        end else begin
            init_pulse_reg <= 1'b0;
            next_pulse_reg <= 1'b0;
            if (cs && we) begin
                if (address == 8'h08) begin
                    init_pulse_reg <= write_data[0];
                    next_pulse_reg <= write_data[1];
                    mode_reg <= write_data[2];
                end else if (address >= 8'h10 && address <= 8'h1f) begin
                    block_reg[511 - 32*address[3:0] -: 32] <= write_data;
                end
            end
        end
    end

    reg [31:0] read_data_reg;
    reg error_reg;

    always @(*) begin
        read_data_reg = 32'h0;
        error_reg = 1'b0;
        if (cs) begin
            case (address)
                8'h00: read_data_reg = 32'h53484132; // "SHA2"
                8'h01: read_data_reg = 32'h35362020; // "56  "
                8'h02: read_data_reg = 32'h00000001; // version
                8'h08: read_data_reg = {29'b0, mode_reg, 2'b00};
                8'h09: read_data_reg = {30'b0, digest_valid, ready};
                default: begin
                    if (address >= 8'h10 && address <= 8'h1f) begin
                        read_data_reg = block_reg[511 - 32*address[3:0] -: 32];
                    end else if (address >= 8'h20 && address <= 8'h27) begin
                        read_data_reg = digest[255 - 32*address[2:0] -: 32];
                    end else begin
                        error_reg = 1'b1;
                    end
                end
            endcase
        end
    end

    assign read_data = read_data_reg;
    assign error = error_reg;

endmodule
