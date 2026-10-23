module sha256_core (
    input clk,
    input reset_n,
    input init,
    input next,
    input mode,
    input [511:0] block,
    output ready,
    output reg digest_valid,
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
        input [31:0] x;
        input [31:0] y;
        input [31:0] z;
        begin
            Ch = (x & y) ^ (~x & z);
        end
    endfunction

    function [31:0] Maj;
        input [31:0] x;
        input [31:0] y;
        input [31:0] z;
        begin
            Maj = (x & y) ^ (x & z) ^ (y & z);
        end
    endfunction

    function [31:0] K;
        input [5:0] t;
        begin
            case (t)
                6'd0:  K = 32'h428a2f98;
                6'd1:  K = 32'h71374491;
                6'd2:  K = 32'hb5c0fbcf;
                6'd3:  K = 32'he9b5dba5;
                6'd4:  K = 32'h3956c25b;
                6'd5:  K = 32'h59f111f1;
                6'd6:  K = 32'h923f82a4;
                6'd7:  K = 32'hab1c5ed5;
                6'd8:  K = 32'hd807aa98;
                6'd9:  K = 32'h12835b01;
                6'd10: K = 32'h243185be;
                6'd11: K = 32'h550c7dc3;
                6'd12: K = 32'h72be5d74;
                6'd13: K = 32'h80deb1fe;
                6'd14: K = 32'h9bdc06a7;
                6'd15: K = 32'hc19bf174;
                6'd16: K = 32'he49b69c1;
                6'd17: K = 32'hefbe4786;
                6'd18: K = 32'h0fc19dc6;
                6'd19: K = 32'h240ca1cc;
                6'd20: K = 32'h2de92c6f;
                6'd21: K = 32'h4a7484aa;
                6'd22: K = 32'h5cb0a9dc;
                6'd23: K = 32'h76f988da;
                6'd24: K = 32'h983e5152;
                6'd25: K = 32'ha831c66d;
                6'd26: K = 32'hb00327c8;
                6'd27: K = 32'hbf597fc7;
                6'd28: K = 32'hc6e00bf3;
                6'd29: K = 32'hd5a79147;
                6'd30: K = 32'h06ca6351;
                6'd31: K = 32'h14292967;
                6'd32: K = 32'h27b70a85;
                6'd33: K = 32'h2e1b2138;
                6'd34: K = 32'h4d2c6dfc;
                6'd35: K = 32'h53380d13;
                6'd36: K = 32'h650a7354;
                6'd37: K = 32'h766a0abb;
                6'd38: K = 32'h81c2c92e;
                6'd39: K = 32'h92722c85;
                6'd40: K = 32'ha2bfe8a1;
                6'd41: K = 32'ha81a664b;
                6'd42: K = 32'hc24b8b70;
                6'd43: K = 32'hc76c51a3;
                6'd44: K = 32'hd192e819;
                6'd45: K = 32'hd6990624;
                6'd46: K = 32'hf40e3585;
                6'd47: K = 32'h106aa070;
                6'd48: K = 32'h19a4c116;
                6'd49: K = 32'h1e376c08;
                6'd50: K = 32'h2748774c;
                6'd51: K = 32'h34b0bcb5;
                6'd52: K = 32'h391c0cb3;
                6'd53: K = 32'h4ed8aa4a;
                6'd54: K = 32'h5b9cca4f;
                6'd55: K = 32'h682e6ff3;
                6'd56: K = 32'h748f82ee;
                6'd57: K = 32'h78a5636f;
                6'd58: K = 32'h84c87814;
                6'd59: K = 32'h8cc70208;
                6'd60: K = 32'h90befffa;
                6'd61: K = 32'ha4506ceb;
                6'd62: K = 32'hbef9a3f7;
                6'd63: K = 32'hc67178f2;
                default: K = 32'h00000000;
            endcase
        end
    endfunction

    reg [31:0] W [0:63];
    reg [511:0] block_reg;
    integer i;

    always @* begin
        W[0]  = block_reg[511:480];
        W[1]  = block_reg[479:448];
        W[2]  = block_reg[447:416];
        W[3]  = block_reg[415:384];
        W[4]  = block_reg[383:352];
        W[5]  = block_reg[351:320];
        W[6]  = block_reg[319:288];
        W[7]  = block_reg[287:256];
        W[8]  = block_reg[255:224];
        W[9]  = block_reg[223:192];
        W[10] = block_reg[191:160];
        W[11] = block_reg[159:128];
        W[12] = block_reg[127:96];
        W[13] = block_reg[95:64];
        W[14] = block_reg[63:32];
        W[15] = block_reg[31:0];

        for (i = 16; i < 64; i = i + 1) begin
            W[i] = W[i-16] + sigma0(W[i-15]) + W[i-7] + sigma1(W[i-2]);
        end
    end

    localparam IDLE = 1'b0;
    localparam BUSY = 1'b1;

    reg state;
    reg [6:0] round;
    reg [31:0] a, b, c, d, e, f, g, h;
    reg [31:0] h0, h1, h2, h3, h4, h5, h6, h7;
    reg [31:0] saved_h0, saved_h1, saved_h2, saved_h3;
    reg [31:0] saved_h4, saved_h5, saved_h6, saved_h7;

    assign ready = (state == IDLE);
    assign digest = {h0, h1, h2, h3, h4, h5, h6, h7};

    wire [31:0] T1 = h + Sigma1(e) + Ch(e, f, g) + K(round[5:0]) + W[round[5:0]];
    wire [31:0] T2 = Sigma0(a) + Maj(a, b, c);

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            h0 <= IV0;
            h1 <= IV1;
            h2 <= IV2;
            h3 <= IV3;
            h4 <= IV4;
            h5 <= IV5;
            h6 <= IV6;
            h7 <= IV7;
            a <= 32'h00000000;
            b <= 32'h00000000;
            c <= 32'h00000000;
            d <= 32'h00000000;
            e <= 32'h00000000;
            f <= 32'h00000000;
            g <= 32'h00000000;
            h <= 32'h00000000;
            saved_h0 <= 32'h00000000;
            saved_h1 <= 32'h00000000;
            saved_h2 <= 32'h00000000;
            saved_h3 <= 32'h00000000;
            saved_h4 <= 32'h00000000;
            saved_h5 <= 32'h00000000;
            saved_h6 <= 32'h00000000;
            saved_h7 <= 32'h00000000;
            block_reg <= 512'h00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
            round <= 7'd0;
            state <= IDLE;
            digest_valid <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    if (init || next) begin
                        block_reg <= block;
                        if (init) begin
                            a <= IV0;
                            b <= IV1;
                            c <= IV2;
                            d <= IV3;
                            e <= IV4;
                            f <= IV5;
                            g <= IV6;
                            h <= IV7;
                            saved_h0 <= IV0;
                            saved_h1 <= IV1;
                            saved_h2 <= IV2;
                            saved_h3 <= IV3;
                            saved_h4 <= IV4;
                            saved_h5 <= IV5;
                            saved_h6 <= IV6;
                            saved_h7 <= IV7;
                        end else begin
                            a <= h0;
                            b <= h1;
                            c <= h2;
                            d <= h3;
                            e <= h4;
                            f <= h5;
                            g <= h6;
                            h <= h7;
                            saved_h0 <= h0;
                            saved_h1 <= h1;
                            saved_h2 <= h2;
                            saved_h3 <= h3;
                            saved_h4 <= h4;
                            saved_h5 <= h5;
                            saved_h6 <= h6;
                            saved_h7 <= h7;
                        end
                        round <= 7'd0;
                        state <= BUSY;
                        digest_valid <= 1'b0;
                    end
                end

                BUSY: begin
                    if (round < 7'd64) begin
                        h <= g;
                        g <= f;
                        f <= e;
                        e <= d + T1;
                        d <= c;
                        c <= b;
                        b <= a;
                        a <= T1 + T2;
                        round <= round + 7'd1;
                    end else begin
                        h0 <= saved_h0 + a;
                        h1 <= saved_h1 + b;
                        h2 <= saved_h2 + c;
                        h3 <= saved_h3 + d;
                        h4 <= saved_h4 + e;
                        h5 <= saved_h5 + f;
                        h6 <= saved_h6 + g;
                        h7 <= saved_h7 + h;
                        digest_valid <= 1'b1;
                        state <= IDLE;
                    end
                end
            endcase
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
    output reg [31:0] read_data,
    output error
);

    reg [31:0] block_words [0:15];
    reg [2:0] control_reg;
    reg init_pulse;
    reg next_pulse;

    wire [511:0] core_block;
    wire [255:0] core_digest;
    wire core_ready;
    wire core_valid;

    assign core_block = {
        block_words[0],  block_words[1],  block_words[2],  block_words[3],
        block_words[4],  block_words[5],  block_words[6],  block_words[7],
        block_words[8],  block_words[9],  block_words[10], block_words[11],
        block_words[12], block_words[13], block_words[14], block_words[15]
    };

    sha256_core u_core (
        .clk(clk),
        .reset_n(reset_n),
        .init(init_pulse),
        .next(next_pulse),
        .mode(control_reg[2]),
        .block(core_block),
        .ready(core_ready),
        .digest_valid(core_valid),
        .digest(core_digest)
    );

    integer j;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            for (j = 0; j < 16; j = j + 1) begin
                block_words[j] <= 32'h00000000;
            end
            control_reg <= 3'b000;
            init_pulse <= 1'b0;
            next_pulse <= 1'b0;
        end else begin
            init_pulse <= 1'b0;
            next_pulse <= 1'b0;

            if (cs && we) begin
                case (address)
                    8'h08: begin
                        if (write_data[0]) init_pulse <= 1'b1;
                        if (write_data[1]) next_pulse <= 1'b1;
                        control_reg[2] <= write_data[2];
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

    wire valid_addr;
    assign valid_addr = (address == 8'h00) || (address == 8'h01) || (address == 8'h02) ||
                        (address == 8'h08) || (address == 8'h09) ||
                        ((address >= 8'h10) && (address <= 8'h1f)) ||
                        ((address >= 8'h20) && (address <= 8'h27));

    assign error = cs && !valid_addr;

    always @* begin
        if (cs && !we) begin
            case (address)
                8'h00: read_data = 32'h53484132; // "SHA2"
                8'h01: read_data = 32'h35362020; // "56  "
                8'h02: read_data = 32'h00010000; // version 1.0
                8'h08: read_data = {29'b0, control_reg[2], 2'b00};
                8'h09: read_data = {30'b0, core_valid, core_ready};
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
                8'h1a: read_data = block_words[10];
                8'h1b: read_data = block_words[11];
                8'h1c: read_data = block_words[12];
                8'h1d: read_data = block_words[13];
                8'h1e: read_data = block_words[14];
                8'h1f: read_data = block_words[15];
                8'h20: read_data = core_digest[255:224];
                8'h21: read_data = core_digest[223:192];
                8'h22: read_data = core_digest[191:160];
                8'h23: read_data = core_digest[159:128];
                8'h24: read_data = core_digest[127:96];
                8'h25: read_data = core_digest[95:64];
                8'h26: read_data = core_digest[63:32];
                8'h27: read_data = core_digest[31:0];
                default: read_data = 32'h00000000;
            endcase
        end else begin
            read_data = 32'h00000000;
        end
    end

endmodule
