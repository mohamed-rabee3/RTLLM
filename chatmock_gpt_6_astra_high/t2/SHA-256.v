module sha256_core (
    input  wire         clk,
    input  wire         reset_n,
    input  wire         init,
    input  wire         next,
    input  wire         mode,
    input  wire [511:0] block,
    output wire         ready,
    output reg          digest_valid,
    output wire [255:0] digest
);

    reg busy;
    reg [5:0] round_ctr;

    reg [31:0] hash_state [0:7];
    reg [31:0] schedule [0:63];
    reg [31:0] a, b, c, d, e, f, g, h;

    wire [31:0] round_word;
    wire [31:0] temp1;
    wire [31:0] temp2;

    integer i;

    function [31:0] rotr;
        input [31:0] x;
        input integer n;
        begin
            rotr = (x >> n) | (x << (32 - n));
        end
    endfunction

    function [31:0] small_sigma0;
        input [31:0] x;
        begin
            small_sigma0 = rotr(x, 7) ^ rotr(x, 18) ^ (x >> 3);
        end
    endfunction

    function [31:0] small_sigma1;
        input [31:0] x;
        begin
            small_sigma1 = rotr(x, 17) ^ rotr(x, 19) ^ (x >> 10);
        end
    endfunction

    function [31:0] big_sigma0;
        input [31:0] x;
        begin
            big_sigma0 = rotr(x, 2) ^ rotr(x, 13) ^ rotr(x, 22);
        end
    endfunction

    function [31:0] big_sigma1;
        input [31:0] x;
        begin
            big_sigma1 = rotr(x, 6) ^ rotr(x, 11) ^ rotr(x, 25);
        end
    endfunction

    function [31:0] round_constant;
        input [5:0] index;
        begin
            case (index)
                6'd0:  round_constant = 32'h428a2f98;
                6'd1:  round_constant = 32'h71374491;
                6'd2:  round_constant = 32'hb5c0fbcf;
                6'd3:  round_constant = 32'he9b5dba5;
                6'd4:  round_constant = 32'h3956c25b;
                6'd5:  round_constant = 32'h59f111f1;
                6'd6:  round_constant = 32'h923f82a4;
                6'd7:  round_constant = 32'hab1c5ed5;
                6'd8:  round_constant = 32'hd807aa98;
                6'd9:  round_constant = 32'h12835b01;
                6'd10: round_constant = 32'h243185be;
                6'd11: round_constant = 32'h550c7dc3;
                6'd12: round_constant = 32'h72be5d74;
                6'd13: round_constant = 32'h80deb1fe;
                6'd14: round_constant = 32'h9bdc06a7;
                6'd15: round_constant = 32'hc19bf174;
                6'd16: round_constant = 32'he49b69c1;
                6'd17: round_constant = 32'hefbe4786;
                6'd18: round_constant = 32'h0fc19dc6;
                6'd19: round_constant = 32'h240ca1cc;
                6'd20: round_constant = 32'h2de92c6f;
                6'd21: round_constant = 32'h4a7484aa;
                6'd22: round_constant = 32'h5cb0a9dc;
                6'd23: round_constant = 32'h76f988da;
                6'd24: round_constant = 32'h983e5152;
                6'd25: round_constant = 32'ha831c66d;
                6'd26: round_constant = 32'hb00327c8;
                6'd27: round_constant = 32'hbf597fc7;
                6'd28: round_constant = 32'hc6e00bf3;
                6'd29: round_constant = 32'hd5a79147;
                6'd30: round_constant = 32'h06ca6351;
                6'd31: round_constant = 32'h14292967;
                6'd32: round_constant = 32'h27b70a85;
                6'd33: round_constant = 32'h2e1b2138;
                6'd34: round_constant = 32'h4d2c6dfc;
                6'd35: round_constant = 32'h53380d13;
                6'd36: round_constant = 32'h650a7354;
                6'd37: round_constant = 32'h766a0abb;
                6'd38: round_constant = 32'h81c2c92e;
                6'd39: round_constant = 32'h92722c85;
                6'd40: round_constant = 32'ha2bfe8a1;
                6'd41: round_constant = 32'ha81a664b;
                6'd42: round_constant = 32'hc24b8b70;
                6'd43: round_constant = 32'hc76c51a3;
                6'd44: round_constant = 32'hd192e819;
                6'd45: round_constant = 32'hd6990624;
                6'd46: round_constant = 32'hf40e3585;
                6'd47: round_constant = 32'h106aa070;
                6'd48: round_constant = 32'h19a4c116;
                6'd49: round_constant = 32'h1e376c08;
                6'd50: round_constant = 32'h2748774c;
                6'd51: round_constant = 32'h34b0bcb5;
                6'd52: round_constant = 32'h391c0cb3;
                6'd53: round_constant = 32'h4ed8aa4a;
                6'd54: round_constant = 32'h5b9cca4f;
                6'd55: round_constant = 32'h682e6ff3;
                6'd56: round_constant = 32'h748f82ee;
                6'd57: round_constant = 32'h78a5636f;
                6'd58: round_constant = 32'h84c87814;
                6'd59: round_constant = 32'h8cc70208;
                6'd60: round_constant = 32'h90befffa;
                6'd61: round_constant = 32'ha4506ceb;
                6'd62: round_constant = 32'hbef9a3f7;
                6'd63: round_constant = 32'hc67178f2;
                default: round_constant = 32'h00000000;
            endcase
        end
    endfunction

    assign ready = ~busy;

    assign digest = {
        hash_state[0], hash_state[1], hash_state[2], hash_state[3],
        hash_state[4], hash_state[5], hash_state[6], hash_state[7]
    };

    assign round_word =
        (round_ctr < 6'd16) ? schedule[round_ctr] :
        small_sigma1(schedule[round_ctr - 6'd2]) +
        schedule[round_ctr - 6'd7] +
        small_sigma0(schedule[round_ctr - 6'd15]) +
        schedule[round_ctr - 6'd16];

    assign temp1 = h + big_sigma1(e) +
                   ((e & f) ^ ((~e) & g)) +
                   round_constant(round_ctr) + round_word;

    assign temp2 = big_sigma0(a) +
                   ((a & b) ^ (a & c) ^ (b & c));

    // This engine implements SHA-256 for both values of the reserved mode input.
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            busy         <= 1'b0;
            round_ctr    <= 6'd0;
            digest_valid <= 1'b0;

            a <= 32'd0;
            b <= 32'd0;
            c <= 32'd0;
            d <= 32'd0;
            e <= 32'd0;
            f <= 32'd0;
            g <= 32'd0;
            h <= 32'd0;

            for (i = 0; i < 8; i = i + 1)
                hash_state[i] <= 32'd0;

            for (i = 0; i < 64; i = i + 1)
                schedule[i] <= 32'd0;
        end else begin
            if (!busy) begin
                if (init || next) begin
                    busy         <= 1'b1;
                    round_ctr    <= 6'd0;
                    digest_valid <= 1'b0;

                    for (i = 0; i < 16; i = i + 1)
                        schedule[i] <= block[511 - (32 * i) -: 32];

                    if (init) begin
                        hash_state[0] <= 32'h6a09e667;
                        hash_state[1] <= 32'hbb67ae85;
                        hash_state[2] <= 32'h3c6ef372;
                        hash_state[3] <= 32'ha54ff53a;
                        hash_state[4] <= 32'h510e527f;
                        hash_state[5] <= 32'h9b05688c;
                        hash_state[6] <= 32'h1f83d9ab;
                        hash_state[7] <= 32'h5be0cd19;

                        a <= 32'h6a09e667;
                        b <= 32'hbb67ae85;
                        c <= 32'h3c6ef372;
                        d <= 32'ha54ff53a;
                        e <= 32'h510e527f;
                        f <= 32'h9b05688c;
                        g <= 32'h1f83d9ab;
                        h <= 32'h5be0cd19;
                    end else begin
                        a <= hash_state[0];
                        b <= hash_state[1];
                        c <= hash_state[2];
                        d <= hash_state[3];
                        e <= hash_state[4];
                        f <= hash_state[5];
                        g <= hash_state[6];
                        h <= hash_state[7];
                    end
                end
            end else begin
                if (round_ctr >= 6'd16)
                    schedule[round_ctr] <= round_word;

                a <= temp1 + temp2;
                b <= a;
                c <= b;
                d <= c;
                e <= d + temp1;
                f <= e;
                g <= f;
                h <= g;

                if (round_ctr == 6'd63) begin
                    hash_state[0] <= hash_state[0] + temp1 + temp2;
                    hash_state[1] <= hash_state[1] + a;
                    hash_state[2] <= hash_state[2] + b;
                    hash_state[3] <= hash_state[3] + c;
                    hash_state[4] <= hash_state[4] + d + temp1;
                    hash_state[5] <= hash_state[5] + e;
                    hash_state[6] <= hash_state[6] + f;
                    hash_state[7] <= hash_state[7] + g;

                    busy         <= 1'b0;
                    digest_valid <= 1'b1;
                end else begin
                    round_ctr <= round_ctr + 6'd1;
                end
            end
        end
    end

endmodule


module sha256 (
    input  wire        clk,
    input  wire        reset_n,
    input  wire        cs,
    input  wire        we,
    input  wire [7:0]  address,
    input  wire [31:0] write_data,
    output reg  [31:0] read_data,
    output reg         error
);

    localparam [31:0] NAME0   = 32'h73686132;
    localparam [31:0] NAME1   = 32'h2d323536;
    localparam [31:0] VERSION = 32'h312e3830;

    reg [31:0] block_reg [0:15];
    reg init_reg;
    reg next_reg;
    reg mode_reg;

    wire [511:0] core_block;
    wire [255:0] core_digest;
    wire         core_ready;
    wire         core_valid;

    integer j;
    genvar word_index;

    generate
        for (word_index = 0; word_index < 16; word_index = word_index + 1) begin : pack_block
            assign core_block[511 - (32 * word_index) -: 32] =
                block_reg[word_index];
        end
    endgenerate

    sha256_core core (
        .clk          (clk),
        .reset_n      (reset_n),
        .init         (init_reg),
        .next         (next_reg),
        .mode         (mode_reg),
        .block        (core_block),
        .ready        (core_ready),
        .digest_valid (core_valid),
        .digest       (core_digest)
    );

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            init_reg <= 1'b0;
            next_reg <= 1'b0;
            mode_reg <= 1'b1;

            for (j = 0; j < 16; j = j + 1)
                block_reg[j] <= 32'd0;
        end else begin
            init_reg <= 1'b0;
            next_reg <= 1'b0;

            if (cs && we) begin
                if (address == 8'h08) begin
                    init_reg <= write_data[0];
                    next_reg <= write_data[1];
                    mode_reg <= write_data[2];
                end

                if ((address >= 8'h10) && (address <= 8'h1f))
                    block_reg[address[3:0]] <= write_data;
            end
        end
    end

    always @* begin
        read_data = 32'd0;
        error     = 1'b0;

        if (cs) begin
            case (address)
                8'h00: begin
                    if (!we)
                        read_data = NAME0;
                end
                8'h01: begin
                    if (!we)
                        read_data = NAME1;
                end
                8'h02: begin
                    if (!we)
                        read_data = VERSION;
                end
                8'h08: begin
                    if (!we)
                        read_data = {29'd0, mode_reg, next_reg, init_reg};
                end
                8'h09: begin
                    if (!we)
                        read_data = {30'd0, core_valid, core_ready};
                end
                default: begin
                    if ((address >= 8'h10) && (address <= 8'h1f)) begin
                        if (!we)
                            read_data = block_reg[address[3:0]];
                    end else if ((address >= 8'h20) && (address <= 8'h27)) begin
                        if (!we)
                            read_data = core_digest[255 - (32 * address[2:0]) -: 32];
                    end else begin
                        error = 1'b1;
                    end
                end
            endcase
        end
    end

endmodule
