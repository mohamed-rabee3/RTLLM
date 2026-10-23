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

    localparam [1:0] ST_IDLE  = 2'd0;
    localparam [1:0] ST_ROUND = 2'd1;
    localparam [1:0] ST_ADD   = 2'd2;

    reg [1:0] state;
    reg [5:0] round_ctr;

    reg [31:0] h0, h1, h2, h3, h4, h5, h6, h7;
    reg [31:0] a, b, c, d, e, f, g, h;
    reg [31:0] w_mem [0:15];

    wire [31:0] schedule_word;
    wire [31:0] round_word;
    wire [31:0] t1;
    wire [31:0] t2;

    integer i;

    function [31:0] small_sigma0;
        input [31:0] x;
        begin
            small_sigma0 = {x[6:0], x[31:7]} ^
                           {x[17:0], x[31:18]} ^
                           (x >> 3);
        end
    endfunction

    function [31:0] small_sigma1;
        input [31:0] x;
        begin
            small_sigma1 = {x[16:0], x[31:17]} ^
                           {x[18:0], x[31:19]} ^
                           (x >> 10);
        end
    endfunction

    function [31:0] big_sigma0;
        input [31:0] x;
        begin
            big_sigma0 = {x[1:0], x[31:2]} ^
                         {x[12:0], x[31:13]} ^
                         {x[21:0], x[31:22]};
        end
    endfunction

    function [31:0] big_sigma1;
        input [31:0] x;
        begin
            big_sigma1 = {x[5:0], x[31:6]} ^
                         {x[10:0], x[31:11]} ^
                         {x[24:0], x[31:25]};
        end
    endfunction

    function [31:0] k_constant;
        input [5:0] index;
        begin
            case (index)
                6'd0:  k_constant = 32'h428a2f98;
                6'd1:  k_constant = 32'h71374491;
                6'd2:  k_constant = 32'hb5c0fbcf;
                6'd3:  k_constant = 32'he9b5dba5;
                6'd4:  k_constant = 32'h3956c25b;
                6'd5:  k_constant = 32'h59f111f1;
                6'd6:  k_constant = 32'h923f82a4;
                6'd7:  k_constant = 32'hab1c5ed5;
                6'd8:  k_constant = 32'hd807aa98;
                6'd9:  k_constant = 32'h12835b01;
                6'd10: k_constant = 32'h243185be;
                6'd11: k_constant = 32'h550c7dc3;
                6'd12: k_constant = 32'h72be5d74;
                6'd13: k_constant = 32'h80deb1fe;
                6'd14: k_constant = 32'h9bdc06a7;
                6'd15: k_constant = 32'hc19bf174;
                6'd16: k_constant = 32'he49b69c1;
                6'd17: k_constant = 32'hefbe4786;
                6'd18: k_constant = 32'h0fc19dc6;
                6'd19: k_constant = 32'h240ca1cc;
                6'd20: k_constant = 32'h2de92c6f;
                6'd21: k_constant = 32'h4a7484aa;
                6'd22: k_constant = 32'h5cb0a9dc;
                6'd23: k_constant = 32'h76f988da;
                6'd24: k_constant = 32'h983e5152;
                6'd25: k_constant = 32'ha831c66d;
                6'd26: k_constant = 32'hb00327c8;
                6'd27: k_constant = 32'hbf597fc7;
                6'd28: k_constant = 32'hc6e00bf3;
                6'd29: k_constant = 32'hd5a79147;
                6'd30: k_constant = 32'h06ca6351;
                6'd31: k_constant = 32'h14292967;
                6'd32: k_constant = 32'h27b70a85;
                6'd33: k_constant = 32'h2e1b2138;
                6'd34: k_constant = 32'h4d2c6dfc;
                6'd35: k_constant = 32'h53380d13;
                6'd36: k_constant = 32'h650a7354;
                6'd37: k_constant = 32'h766a0abb;
                6'd38: k_constant = 32'h81c2c92e;
                6'd39: k_constant = 32'h92722c85;
                6'd40: k_constant = 32'ha2bfe8a1;
                6'd41: k_constant = 32'ha81a664b;
                6'd42: k_constant = 32'hc24b8b70;
                6'd43: k_constant = 32'hc76c51a3;
                6'd44: k_constant = 32'hd192e819;
                6'd45: k_constant = 32'hd6990624;
                6'd46: k_constant = 32'hf40e3585;
                6'd47: k_constant = 32'h106aa070;
                6'd48: k_constant = 32'h19a4c116;
                6'd49: k_constant = 32'h1e376c08;
                6'd50: k_constant = 32'h2748774c;
                6'd51: k_constant = 32'h34b0bcb5;
                6'd52: k_constant = 32'h391c0cb3;
                6'd53: k_constant = 32'h4ed8aa4a;
                6'd54: k_constant = 32'h5b9cca4f;
                6'd55: k_constant = 32'h682e6ff3;
                6'd56: k_constant = 32'h748f82ee;
                6'd57: k_constant = 32'h78a5636f;
                6'd58: k_constant = 32'h84c87814;
                6'd59: k_constant = 32'h8cc70208;
                6'd60: k_constant = 32'h90befffa;
                6'd61: k_constant = 32'ha4506ceb;
                6'd62: k_constant = 32'hbef9a3f7;
                6'd63: k_constant = 32'hc67178f2;
                default: k_constant = 32'h00000000;
            endcase
        end
    endfunction

    assign ready = (state == ST_IDLE);
    assign digest = {h0, h1, h2, h3, h4, h5, h6, h7};

    assign schedule_word = small_sigma1(w_mem[14]) +
                           w_mem[9] +
                           small_sigma0(w_mem[1]) +
                           w_mem[0];

    assign round_word = (round_ctr < 6'd16) ?
                        w_mem[round_ctr[3:0]] : schedule_word;

    assign t1 = h + big_sigma1(e) +
                ((e & f) ^ ((~e) & g)) +
                k_constant(round_ctr) + round_word;

    assign t2 = big_sigma0(a) +
                ((a & b) ^ (a & c) ^ (b & c));

    // This engine implements SHA-256 for either value of mode.
    // Blocks must already include the FIPS-180-4 message padding.
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            state        <= ST_IDLE;
            round_ctr    <= 6'd0;
            digest_valid <= 1'b0;

            h0 <= 32'd0;
            h1 <= 32'd0;
            h2 <= 32'd0;
            h3 <= 32'd0;
            h4 <= 32'd0;
            h5 <= 32'd0;
            h6 <= 32'd0;
            h7 <= 32'd0;

            a <= 32'd0;
            b <= 32'd0;
            c <= 32'd0;
            d <= 32'd0;
            e <= 32'd0;
            f <= 32'd0;
            g <= 32'd0;
            h <= 32'd0;

            for (i = 0; i < 16; i = i + 1)
                w_mem[i] <= 32'd0;
        end else begin
            case (state)
                ST_IDLE: begin
                    if (init || next) begin
                        digest_valid <= 1'b0;
                        round_ctr    <= 6'd0;
                        state        <= ST_ROUND;

                        for (i = 0; i < 16; i = i + 1)
                            w_mem[i] <= block[511 - 32*i -: 32];

                        if (init) begin
                            h0 <= 32'h6a09e667;
                            h1 <= 32'hbb67ae85;
                            h2 <= 32'h3c6ef372;
                            h3 <= 32'ha54ff53a;
                            h4 <= 32'h510e527f;
                            h5 <= 32'h9b05688c;
                            h6 <= 32'h1f83d9ab;
                            h7 <= 32'h5be0cd19;

                            a <= 32'h6a09e667;
                            b <= 32'hbb67ae85;
                            c <= 32'h3c6ef372;
                            d <= 32'ha54ff53a;
                            e <= 32'h510e527f;
                            f <= 32'h9b05688c;
                            g <= 32'h1f83d9ab;
                            h <= 32'h5be0cd19;
                        end else begin
                            a <= h0;
                            b <= h1;
                            c <= h2;
                            d <= h3;
                            e <= h4;
                            f <= h5;
                            g <= h6;
                            h <= h7;
                        end
                    end
                end

                ST_ROUND: begin
                    a <= t1 + t2;
                    b <= a;
                    c <= b;
                    d <= c;
                    e <= d + t1;
                    f <= e;
                    g <= f;
                    h <= g;

                    if (round_ctr >= 6'd16) begin
                        for (i = 0; i < 15; i = i + 1)
                            w_mem[i] <= w_mem[i + 1];
                        w_mem[15] <= schedule_word;
                    end

                    if (round_ctr == 6'd63)
                        state <= ST_ADD;
                    else
                        round_ctr <= round_ctr + 6'd1;
                end

                ST_ADD: begin
                    h0 <= h0 + a;
                    h1 <= h1 + b;
                    h2 <= h2 + c;
                    h3 <= h3 + d;
                    h4 <= h4 + e;
                    h5 <= h5 + f;
                    h6 <= h6 + g;
                    h7 <= h7 + h;
                    digest_valid <= 1'b1;
                    state <= ST_IDLE;
                end

                default: begin
                    state <= ST_IDLE;
                    digest_valid <= 1'b0;
                end
            endcase
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

    localparam [31:0] CORE_NAME0   = 32'h73686132;
    localparam [31:0] CORE_NAME1   = 32'h2d323536;
    localparam [31:0] CORE_VERSION = 32'h312e3830;

    reg [31:0] block_reg [0:15];
    reg init_reg;
    reg next_reg;
    reg mode_reg;

    wire [511:0] core_block;
    wire [255:0] core_digest;
    wire core_ready;
    wire core_digest_valid;

    integer j;
    genvar n;

    generate
        for (n = 0; n < 16; n = n + 1) begin : pack_block
            assign core_block[511 - 32*n -: 32] = block_reg[n];
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
        .digest_valid (core_digest_valid),
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
                end else if ((address >= 8'h10) &&
                             (address <= 8'h1f)) begin
                    block_reg[address[3:0]] <= write_data;
                end
            end
        end
    end

    always @* begin
        read_data = 32'd0;
        error = 1'b0;

        if (cs) begin
            if (we) begin
                if (!((address == 8'h08) ||
                      ((address >= 8'h10) && (address <= 8'h1f))))
                    error = 1'b1;
            end else begin
                case (address)
                    8'h00: read_data = CORE_NAME0;
                    8'h01: read_data = CORE_NAME1;
                    8'h02: read_data = CORE_VERSION;
                    8'h08: read_data = {29'd0, mode_reg, next_reg, init_reg};
                    8'h09: read_data = {30'd0, core_digest_valid, core_ready};

                    8'h20: read_data = core_digest[255:224];
                    8'h21: read_data = core_digest[223:192];
                    8'h22: read_data = core_digest[191:160];
                    8'h23: read_data = core_digest[159:128];
                    8'h24: read_data = core_digest[127:96];
                    8'h25: read_data = core_digest[95:64];
                    8'h26: read_data = core_digest[63:32];
                    8'h27: read_data = core_digest[31:0];

                    default: begin
                        if ((address >= 8'h10) && (address <= 8'h1f))
                            read_data = block_reg[address[3:0]];
                        else
                            error = 1'b1;
                    end
                endcase
            end
        end
    end

endmodule
