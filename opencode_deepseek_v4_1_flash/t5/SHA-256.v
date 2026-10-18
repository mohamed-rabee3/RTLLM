module sha256_core(
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

    // SHA-256 helper functions
    function [31:0] rotr;
        input [31:0] x;
        input [4:0] n;
        begin
            rotr = (x >> n) | (x << (32 - n));
        end
    endfunction

    function [31:0] ch;
        input [31:0] x, y, z;
        begin
            ch = (x & y) ^ (~x & z);
        end
    endfunction

    function [31:0] maj;
        input [31:0] x, y, z;
        begin
            maj = (x & y) ^ (x & z) ^ (y & z);
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

    // SHA-256 round constants
    wire [31:0] K [0:63];
    assign K[0]  = 32'h428a2f98;
    assign K[1]  = 32'h71374491;
    assign K[2]  = 32'hb5c0fbcf;
    assign K[3]  = 32'he9b5dba5;
    assign K[4]  = 32'h3956c25b;
    assign K[5]  = 32'h59f111f1;
    assign K[6]  = 32'h923f82a4;
    assign K[7]  = 32'hab1c5ed5;
    assign K[8]  = 32'hd807aa98;
    assign K[9]  = 32'h12835b01;
    assign K[10] = 32'h243185be;
    assign K[11] = 32'h550c7dc3;
    assign K[12] = 32'h72be5d74;
    assign K[13] = 32'h80deb1fe;
    assign K[14] = 32'h9bdc06a7;
    assign K[15] = 32'hc19bf174;
    assign K[16] = 32'he49b69c1;
    assign K[17] = 32'hefbe4786;
    assign K[18] = 32'h0fc19dc6;
    assign K[19] = 32'h240ca1cc;
    assign K[20] = 32'h2de92c6f;
    assign K[21] = 32'h4a7484aa;
    assign K[22] = 32'h5cb0a9dc;
    assign K[23] = 32'h76f988da;
    assign K[24] = 32'h983e5152;
    assign K[25] = 32'ha831c66d;
    assign K[26] = 32'hb00327c8;
    assign K[27] = 32'hbf597fc7;
    assign K[28] = 32'hc6e00bf3;
    assign K[29] = 32'hd5a79147;
    assign K[30] = 32'h06ca6351;
    assign K[31] = 32'h14292967;
    assign K[32] = 32'h27b70a85;
    assign K[33] = 32'h2e1b2138;
    assign K[34] = 32'h4d2c6dfc;
    assign K[35] = 32'h53380d13;
    assign K[36] = 32'h650a7354;
    assign K[37] = 32'h766a0abb;
    assign K[38] = 32'h81c2c92e;
    assign K[39] = 32'h92722c85;
    assign K[40] = 32'ha2bfe8a1;
    assign K[41] = 32'ha81a664b;
    assign K[42] = 32'hc24b8b70;
    assign K[43] = 32'hc76c51a3;
    assign K[44] = 32'hd192e819;
    assign K[45] = 32'hd6990624;
    assign K[46] = 32'hf40e3585;
    assign K[47] = 32'h106aa070;
    assign K[48] = 32'h19a4c116;
    assign K[49] = 32'h1e376c08;
    assign K[50] = 32'h2748774c;
    assign K[51] = 32'h34b0bcb5;
    assign K[52] = 32'h391c0cb3;
    assign K[53] = 32'h4ed8aa4a;
    assign K[54] = 32'h5b9cca4f;
    assign K[55] = 32'h682e6ff3;
    assign K[56] = 32'h748f82ee;
    assign K[57] = 32'h78a5636f;
    assign K[58] = 32'h84c87814;
    assign K[59] = 32'h8cc70208;
    assign K[60] = 32'h90befffa;
    assign K[61] = 32'ha4506ceb;
    assign K[62] = 32'hbef9a3f7;
    assign K[63] = 32'hc67178f2;

    // Internal registers
    reg [31:0] w [0:63];
    reg [31:0] a, b, c, d, e, f, g, h;
    reg [31:0] h0_t, h1_t, h2_t, h3_t, h4_t, h5_t, h6_t, h7_t;
    reg [31:0] T1, T2;
    reg [255:0] new_digest;
    integer i;

    reg busy;
    reg init_latched;
    reg next_latched;
    reg [511:0] block_latched;

    // Combinational SHA-256 compression
    always @* begin
        // Message schedule
        w[0]  = block_latched[511:480];
        w[1]  = block_latched[479:448];
        w[2]  = block_latched[447:416];
        w[3]  = block_latched[415:384];
        w[4]  = block_latched[383:352];
        w[5]  = block_latched[351:320];
        w[6]  = block_latched[319:288];
        w[7]  = block_latched[287:256];
        w[8]  = block_latched[255:224];
        w[9]  = block_latched[223:192];
        w[10] = block_latched[191:160];
        w[11] = block_latched[159:128];
        w[12] = block_latched[127:96];
        w[13] = block_latched[95:64];
        w[14] = block_latched[63:32];
        w[15] = block_latched[31:0];

        for (i = 16; i < 64; i = i + 1) begin
            w[i] = sigma1(w[i-2]) + w[i-7] + sigma0(w[i-15]) + w[i-16];
        end

        // Initial hash values
        if (init_latched) begin
            h0_t = 32'h6a09e667;
            h1_t = 32'hbb67ae85;
            h2_t = 32'h3c6ef372;
            h3_t = 32'ha54ff53a;
            h4_t = 32'h510e527f;
            h5_t = 32'h9b05688c;
            h6_t = 32'h1f83d9ab;
            h7_t = 32'h5be0cd19;
        end else begin
            h0_t = digest[255:224];
            h1_t = digest[223:192];
            h2_t = digest[191:160];
            h3_t = digest[159:128];
            h4_t = digest[127:96];
            h5_t = digest[95:64];
            h6_t = digest[63:32];
            h7_t = digest[31:0];
        end

        a = h0_t;
        b = h1_t;
        c = h2_t;
        d = h3_t;
        e = h4_t;
        f = h5_t;
        g = h6_t;
        h = h7_t;

        // 64 rounds
        for (i = 0; i < 64; i = i + 1) begin
            T1 = h + Sigma1(e) + ch(e, f, g) + K[i] + w[i];
            T2 = Sigma0(a) + maj(a, b, c);
            h = g;
            g = f;
            f = e;
            e = d + T1;
            d = c;
            c = b;
            b = a;
            a = T1 + T2;
        end

        new_digest[255:224] = h0_t + a;
        new_digest[223:192] = h1_t + b;
        new_digest[191:160] = h2_t + c;
        new_digest[159:128] = h3_t + d;
        new_digest[127:96]  = h4_t + e;
        new_digest[95:64]   = h5_t + f;
        new_digest[63:32]   = h6_t + g;
        new_digest[31:0]    = h7_t + h;
    end

    // Sequential control
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            digest <= 256'h0;
            ready <= 1'b1;
            digest_valid <= 1'b0;
            busy <= 1'b0;
            init_latched <= 1'b0;
            next_latched <= 1'b0;
            block_latched <= 512'h0;
        end else begin
            digest_valid <= 1'b0;
            if (!busy) begin
                if (init || next) begin
                    init_latched <= init;
                    next_latched <= next;
                    block_latched <= block;
                    busy <= 1'b1;
                    ready <= 1'b0;
                end
            end else begin
                digest <= new_digest;
                busy <= 1'b0;
                ready <= 1'b1;
                digest_valid <= 1'b1;
            end
        end
    end

endmodule


module sha256(
    input clk,
    input reset_n,
    input cs,
    input we,
    input [7:0] address,
    input [31:0] write_data,
    output [31:0] read_data,
    output error
);

    // Identification registers
    localparam [31:0] NAME0   = 32'h5348412D; // "SHA-"
    localparam [31:0] NAME1   = 32'h32353600; // "256\0"
    localparam [31:0] VERSION = 32'h00000001;

    // Core signals
    wire core_init;
    wire core_next;
    wire core_mode;
    wire core_ready;
    wire core_digest_valid;
    wire [255:0] core_digest;

    // Wrapper registers
    reg [31:0] control_reg;
    reg mode_reg;
    reg [31:0] block_words [0:15];
    reg valid_sticky;
    reg init_pulse;
    reg next_pulse;

    integer j;

    // Assemble 512-bit block from block_words
    wire [511:0] block;
    assign block[511:480] = block_words[0];
    assign block[479:448] = block_words[1];
    assign block[447:416] = block_words[2];
    assign block[415:384] = block_words[3];
    assign block[383:352] = block_words[4];
    assign block[351:320] = block_words[5];
    assign block[319:288] = block_words[6];
    assign block[287:256] = block_words[7];
    assign block[255:224] = block_words[8];
    assign block[223:192] = block_words[9];
    assign block[191:160] = block_words[10];
    assign block[159:128] = block_words[11];
    assign block[127:96]  = block_words[12];
    assign block[95:64]   = block_words[13];
    assign block[63:32]   = block_words[14];
    assign block[31:0]    = block_words[15];

    // Digest words from core
    wire [31:0] digest_word0 = core_digest[255:224];
    wire [31:0] digest_word1 = core_digest[223:192];
    wire [31:0] digest_word2 = core_digest[191:160];
    wire [31:0] digest_word3 = core_digest[159:128];
    wire [31:0] digest_word4 = core_digest[127:96];
    wire [31:0] digest_word5 = core_digest[95:64];
    wire [31:0] digest_word6 = core_digest[63:32];
    wire [31:0] digest_word7 = core_digest[31:0];

    // Address validity
    wire address_valid = (address == 8'h00) || (address == 8'h01) || (address == 8'h02) ||
                         (address == 8'h08) || (address == 8'h09) ||
                         (address >= 8'h10 && address <= 8'h1f) ||
                         (address >= 8'h20 && address <= 8'h27);

    assign error = cs && !address_valid;

    // Read mux
    reg [31:0] read_data_reg;
    always @* begin
        read_data_reg = 32'h0;
        if (cs && !we) begin
            case (address)
                8'h00: read_data_reg = NAME0;
                8'h01: read_data_reg = NAME1;
                8'h02: read_data_reg = VERSION;
                8'h08: read_data_reg = control_reg;
                8'h09: read_data_reg = {30'b0, (valid_sticky | core_digest_valid), core_ready};
                8'h10: read_data_reg = block_words[0];
                8'h11: read_data_reg = block_words[1];
                8'h12: read_data_reg = block_words[2];
                8'h13: read_data_reg = block_words[3];
                8'h14: read_data_reg = block_words[4];
                8'h15: read_data_reg = block_words[5];
                8'h16: read_data_reg = block_words[6];
                8'h17: read_data_reg = block_words[7];
                8'h18: read_data_reg = block_words[8];
                8'h19: read_data_reg = block_words[9];
                8'h1a: read_data_reg = block_words[10];
                8'h1b: read_data_reg = block_words[11];
                8'h1c: read_data_reg = block_words[12];
                8'h1d: read_data_reg = block_words[13];
                8'h1e: read_data_reg = block_words[14];
                8'h1f: read_data_reg = block_words[15];
                8'h20: read_data_reg = digest_word0;
                8'h21: read_data_reg = digest_word1;
                8'h22: read_data_reg = digest_word2;
                8'h23: read_data_reg = digest_word3;
                8'h24: read_data_reg = digest_word4;
                8'h25: read_data_reg = digest_word5;
                8'h26: read_data_reg = digest_word6;
                8'h27: read_data_reg = digest_word7;
                default: read_data_reg = 32'h0;
            endcase
        end
    end
    assign read_data = read_data_reg;

    // Write logic and control pulse generation
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            for (j = 0; j < 16; j = j + 1) block_words[j] <= 32'h0;
            control_reg <= 32'h0;
            mode_reg <= 1'b0;
            valid_sticky <= 1'b0;
            init_pulse <= 1'b0;
            next_pulse <= 1'b0;
        end else begin
            init_pulse <= 1'b0;
            next_pulse <= 1'b0;
            if (core_digest_valid) valid_sticky <= 1'b1;
            if (cs && we) begin
                case (address)
                    8'h08: begin
                        init_pulse <= write_data[0];
                        next_pulse <= write_data[1];
                        control_reg <= write_data;
                        mode_reg <= write_data[2];
                        valid_sticky <= 1'b0;
                    end
                    8'h10: block_words[0]  <= write_data;
                    8'h11: block_words[1]  <= write_data;
                    8'h12: block_words[2]  <= write_data;
                    8'h13: block_words[3]  <= write_data;
                    8'h14: block_words[4]  <= write_data;
                    8'h15: block_words[5]  <= write_data;
                    8'h16: block_words[6]  <= write_data;
                    8'h17: block_words[7]  <= write_data;
                    8'h18: block_words[8]  <= write_data;
                    8'h19: block_words[9]  <= write_data;
                    8'h1a: block_words[10] <= write_data;
                    8'h1b: block_words[11] <= write_data;
                    8'h1c: block_words[12] <= write_data;
                    8'h1d: block_words[13] <= write_data;
                    8'h1e: block_words[14] <= write_data;
                    8'h1f: block_words[15] <= write_data;
                    default: ;
                endcase
            end
        end
    end

    assign core_init = init_pulse;
    assign core_next = next_pulse;
    assign core_mode = mode_reg;

    // Core instance
    sha256_core u_sha256_core (
        .clk(clk),
        .reset_n(reset_n),
        .init(core_init),
        .next(core_next),
        .mode(core_mode),
        .block(block),
        .ready(core_ready),
        .digest_valid(core_digest_valid),
        .digest(core_digest)
    );

endmodule
