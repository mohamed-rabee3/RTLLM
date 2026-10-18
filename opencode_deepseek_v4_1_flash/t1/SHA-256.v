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

    function [31:0] rotr;
        input [31:0] x;
        input [5:0] n;
        begin
            rotr = (x >> n) | (x << (32 - n));
        end
    endfunction

    function [31:0] Sigma0;
        input [31:0] x;
        begin
            Sigma0 = rotr(x, 6'd2) ^ rotr(x, 6'd13) ^ rotr(x, 6'd22);
        end
    endfunction

    function [31:0] Sigma1;
        input [31:0] x;
        begin
            Sigma1 = rotr(x, 6'd6) ^ rotr(x, 6'd11) ^ rotr(x, 6'd25);
        end
    endfunction

    function [31:0] sigma0;
        input [31:0] x;
        begin
            sigma0 = rotr(x, 6'd7) ^ rotr(x, 6'd18) ^ (x >> 3);
        end
    endfunction

    function [31:0] sigma1;
        input [31:0] x;
        begin
            sigma1 = rotr(x, 6'd17) ^ rotr(x, 6'd19) ^ (x >> 10);
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

    function [31:0] Kconst;
        input [5:0] idx;
        begin
            case (idx)
                6'd0:  Kconst = 32'h428a2f98;
                6'd1:  Kconst = 32'h71374491;
                6'd2:  Kconst = 32'hb5c0fbcf;
                6'd3:  Kconst = 32'he9b5dba5;
                6'd4:  Kconst = 32'h3956c25b;
                6'd5:  Kconst = 32'h59f111f1;
                6'd6:  Kconst = 32'h923f82a4;
                6'd7:  Kconst = 32'hab1c5ed5;
                6'd8:  Kconst = 32'hd807aa98;
                6'd9:  Kconst = 32'h12835b01;
                6'd10: Kconst = 32'h243185be;
                6'd11: Kconst = 32'h550c7dc3;
                6'd12: Kconst = 32'h72be5d74;
                6'd13: Kconst = 32'h80deb1fe;
                6'd14: Kconst = 32'h9bdc06a7;
                6'd15: Kconst = 32'hc19bf174;
                6'd16: Kconst = 32'he49b69c1;
                6'd17: Kconst = 32'hefbe4786;
                6'd18: Kconst = 32'h0fc19dc6;
                6'd19: Kconst = 32'h240ca1cc;
                6'd20: Kconst = 32'h2de92c6f;
                6'd21: Kconst = 32'h4a7484aa;
                6'd22: Kconst = 32'h5cb0a9dc;
                6'd23: Kconst = 32'h76f988da;
                6'd24: Kconst = 32'h983e5152;
                6'd25: Kconst = 32'ha831c66d;
                6'd26: Kconst = 32'hb00327c8;
                6'd27: Kconst = 32'hbf597fc7;
                6'd28: Kconst = 32'hc6e00bf3;
                6'd29: Kconst = 32'hd5a79147;
                6'd30: Kconst = 32'h06ca6351;
                6'd31: Kconst = 32'h14292967;
                6'd32: Kconst = 32'h27b70a85;
                6'd33: Kconst = 32'h2e1b2138;
                6'd34: Kconst = 32'h4d2c6dfc;
                6'd35: Kconst = 32'h53380d13;
                6'd36: Kconst = 32'h650a7354;
                6'd37: Kconst = 32'h766a0abb;
                6'd38: Kconst = 32'h81c2c92e;
                6'd39: Kconst = 32'h92722c85;
                6'd40: Kconst = 32'ha2bfe8a1;
                6'd41: Kconst = 32'ha81a664b;
                6'd42: Kconst = 32'hc24b8b70;
                6'd43: Kconst = 32'hc76c51a3;
                6'd44: Kconst = 32'hd192e819;
                6'd45: Kconst = 32'hd6990624;
                6'd46: Kconst = 32'hf40e3585;
                6'd47: Kconst = 32'h106aa070;
                6'd48: Kconst = 32'h19a4c116;
                6'd49: Kconst = 32'h1e376c08;
                6'd50: Kconst = 32'h2748774c;
                6'd51: Kconst = 32'h34b0bcb5;
                6'd52: Kconst = 32'h391c0cb3;
                6'd53: Kconst = 32'h4ed8aa4a;
                6'd54: Kconst = 32'h5b9cca4f;
                6'd55: Kconst = 32'h682e6ff3;
                6'd56: Kconst = 32'h748f82ee;
                6'd57: Kconst = 32'h78a5636f;
                6'd58: Kconst = 32'h84c87814;
                6'd59: Kconst = 32'h8cc70208;
                6'd60: Kconst = 32'h90befffa;
                6'd61: Kconst = 32'ha4506ceb;
                6'd62: Kconst = 32'hbef9a3f7;
                6'd63: Kconst = 32'hc67178f2;
                default: Kconst = 32'h00000000;
            endcase
        end
    endfunction

    localparam [31:0] IV0 = 32'h6a09e667;
    localparam [31:0] IV1 = 32'hbb67ae85;
    localparam [31:0] IV2 = 32'h3c6ef372;
    localparam [31:0] IV3 = 32'ha54ff53a;
    localparam [31:0] IV4 = 32'h510e527f;
    localparam [31:0] IV5 = 32'h9b05688c;
    localparam [31:0] IV6 = 32'h1f83d9ab;
    localparam [31:0] IV7 = 32'h5be0cd19;

    localparam IDLE = 1'b0;
    localparam PROCESS = 1'b1;

    reg state;
    reg [5:0] t;
    reg [31:0] a, b, c, d, e, f, g, h;
    reg [31:0] H0, H1, H2, H3, H4, H5, H6, H7;
    reg [255:0] digest_reg;
    reg ready_reg;
    reg valid_reg;
    reg [31:0] w [0:63];
    integer i;

    wire [31:0] T1;
    wire [31:0] T2;
    wire [31:0] new_a;
    wire [31:0] new_e;

    assign ready = ready_reg;
    assign digest_valid = valid_reg;
    assign digest = digest_reg;

    assign T1 = h + Sigma1(e) + Ch(e, f, g) + Kconst(t) + w[t];
    assign T2 = Sigma0(a) + Maj(a, b, c);
    assign new_a = T1 + T2;
    assign new_e = d + T1;

    always @* begin
        w[0]  = block[511:480];
        w[1]  = block[479:448];
        w[2]  = block[447:416];
        w[3]  = block[415:384];
        w[4]  = block[383:352];
        w[5]  = block[351:320];
        w[6]  = block[319:288];
        w[7]  = block[287:256];
        w[8]  = block[255:224];
        w[9]  = block[223:192];
        w[10] = block[191:160];
        w[11] = block[159:128];
        w[12] = block[127:96];
        w[13] = block[95:64];
        w[14] = block[63:32];
        w[15] = block[31:0];

        for (i = 16; i < 64; i = i + 1) begin
            w[i] = w[i-16] + sigma0(w[i-15]) + w[i-7] + sigma1(w[i-2]);
        end
    end

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            state <= IDLE;
            t <= 6'd0;
            a <= 32'd0;
            b <= 32'd0;
            c <= 32'd0;
            d <= 32'd0;
            e <= 32'd0;
            f <= 32'd0;
            g <= 32'd0;
            h <= 32'd0;
            H0 <= 32'd0;
            H1 <= 32'd0;
            H2 <= 32'd0;
            H3 <= 32'd0;
            H4 <= 32'd0;
            H5 <= 32'd0;
            H6 <= 32'd0;
            H7 <= 32'd0;
            digest_reg <= 256'd0;
            ready_reg <= 1'b1;
            valid_reg <= 1'b0;
        end else begin
            valid_reg <= 1'b0;

            if (state == IDLE) begin
                if (init) begin
                    H0 <= IV0;
                    H1 <= IV1;
                    H2 <= IV2;
                    H3 <= IV3;
                    H4 <= IV4;
                    H5 <= IV5;
                    H6 <= IV6;
                    H7 <= IV7;
                    a <= IV0;
                    b <= IV1;
                    c <= IV2;
                    d <= IV3;
                    e <= IV4;
                    f <= IV5;
                    g <= IV6;
                    h <= IV7;
                    t <= 6'd0;
                    state <= PROCESS;
                    ready_reg <= 1'b0;
                end else if (next) begin
                    a <= H0;
                    b <= H1;
                    c <= H2;
                    d <= H3;
                    e <= H4;
                    f <= H5;
                    g <= H6;
                    h <= H7;
                    t <= 6'd0;
                    state <= PROCESS;
                    ready_reg <= 1'b0;
                end
            end else begin
                if (t == 6'd63) begin
                    H0 <= H0 + new_a;
                    H1 <= H1 + a;
                    H2 <= H2 + b;
                    H3 <= H3 + c;
                    H4 <= H4 + new_e;
                    H5 <= H5 + e;
                    H6 <= H6 + f;
                    H7 <= H7 + g;
                    digest_reg <= {H0 + new_a, H1 + a, H2 + b, H3 + c,
                                   H4 + new_e, H5 + e, H6 + f, H7 + g};
                    ready_reg <= 1'b1;
                    valid_reg <= 1'b1;
                    state <= IDLE;
                end else begin
                    a <= new_a;
                    b <= a;
                    c <= b;
                    d <= c;
                    e <= new_e;
                    f <= e;
                    g <= f;
                    h <= g;
                    t <= t + 6'd1;
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

    reg [31:0] name0;
    reg [31:0] name1;
    reg [31:0] version;
    reg [2:0] control_reg;
    reg [31:0] block_words [0:15];
    reg [31:0] digest_reg [0:7];
    reg valid_reg;
    reg [31:0] read_data_reg;
    reg error_reg;
    integer i;

    wire core_ready;
    wire core_digest_valid;
    wire [255:0] core_digest;
    wire init_pulse;
    wire next_pulse;

    assign init_pulse = cs && we && (address == 8'h08) && write_data[0];
    assign next_pulse = cs && we && (address == 8'h08) && write_data[1];
    assign read_data = read_data_reg;
    assign error = error_reg;

    sha256_core u_core (
        .clk(clk),
        .reset_n(reset_n),
        .init(init_pulse),
        .next(next_pulse),
        .mode(control_reg[2]),
        .block({block_words[0], block_words[1], block_words[2], block_words[3],
                block_words[4], block_words[5], block_words[6], block_words[7],
                block_words[8], block_words[9], block_words[10], block_words[11],
                block_words[12], block_words[13], block_words[14], block_words[15]}),
        .ready(core_ready),
        .digest_valid(core_digest_valid),
        .digest(core_digest)
    );

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            name0 <= 32'h53484132;
            name1 <= 32'h35360000;
            version <= 32'h00000001;
            control_reg <= 3'b000;
            valid_reg <= 1'b0;
            for (i = 0; i < 16; i = i + 1) begin
                block_words[i] <= 32'h00000000;
            end
            for (i = 0; i < 8; i = i + 1) begin
                digest_reg[i] <= 32'h00000000;
            end
        end else begin
            if (core_digest_valid) begin
                digest_reg[0] <= core_digest[255:224];
                digest_reg[1] <= core_digest[223:192];
                digest_reg[2] <= core_digest[191:160];
                digest_reg[3] <= core_digest[159:128];
                digest_reg[4] <= core_digest[127:96];
                digest_reg[5] <= core_digest[95:64];
                digest_reg[6] <= core_digest[63:32];
                digest_reg[7] <= core_digest[31:0];
                valid_reg <= 1'b1;
            end

            if (cs && we) begin
                case (address)
                    8'h08: begin
                        control_reg <= write_data[2:0];
                        if (write_data[0] || write_data[1]) begin
                            valid_reg <= 1'b0;
                        end
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

    always @* begin
        read_data_reg = 32'h00000000;
        error_reg = 1'b0;

        if (cs) begin
            if (address == 8'h00) begin
                read_data_reg = name0;
            end else if (address == 8'h01) begin
                read_data_reg = name1;
            end else if (address == 8'h02) begin
                read_data_reg = version;
            end else if (address == 8'h08) begin
                read_data_reg = {29'b0, control_reg};
            end else if (address == 8'h09) begin
                read_data_reg = {30'b0, valid_reg, core_ready};
            end else if (address >= 8'h10 && address <= 8'h1f) begin
                case (address[3:0])
                    4'h0: read_data_reg = block_words[0];
                    4'h1: read_data_reg = block_words[1];
                    4'h2: read_data_reg = block_words[2];
                    4'h3: read_data_reg = block_words[3];
                    4'h4: read_data_reg = block_words[4];
                    4'h5: read_data_reg = block_words[5];
                    4'h6: read_data_reg = block_words[6];
                    4'h7: read_data_reg = block_words[7];
                    4'h8: read_data_reg = block_words[8];
                    4'h9: read_data_reg = block_words[9];
                    4'hA: read_data_reg = block_words[10];
                    4'hB: read_data_reg = block_words[11];
                    4'hC: read_data_reg = block_words[12];
                    4'hD: read_data_reg = block_words[13];
                    4'hE: read_data_reg = block_words[14];
                    4'hF: read_data_reg = block_words[15];
                    default: read_data_reg = 32'h00000000;
                endcase
            end else if (address >= 8'h20 && address <= 8'h27) begin
                case (address[2:0])
                    3'h0: read_data_reg = digest_reg[0];
                    3'h1: read_data_reg = digest_reg[1];
                    3'h2: read_data_reg = digest_reg[2];
                    3'h3: read_data_reg = digest_reg[3];
                    3'h4: read_data_reg = digest_reg[4];
                    3'h5: read_data_reg = digest_reg[5];
                    3'h6: read_data_reg = digest_reg[6];
                    3'h7: read_data_reg = digest_reg[7];
                    default: read_data_reg = 32'h00000000;
                endcase
            end else begin
                read_data_reg = 32'h00000000;
                error_reg = 1'b1;
            end
        end
    end

endmodule
