//======================================================================
// SHA-256 core (sha256_core) and register-interface wrapper (sha256).
//======================================================================
`timescale 1ns / 1ps

module sha256_core(
    input              clk,
    input              reset_n,
    input              init,
    input              next,
    input              mode,        // accepted for compatibility; SHA-256 only
    input      [511:0] block,
    output reg         ready,
    output     [255:0] digest,
    output reg         digest_valid
);
    function [31:0] ror(input [31:0] x, input integer n);
        ror = (x >> n) | (x << (32-n));
    endfunction
    function [31:0] BSIG0(input [31:0] x); BSIG0 = ror(x,2)  ^ ror(x,13) ^ ror(x,22); endfunction
    function [31:0] BSIG1(input [31:0] x); BSIG1 = ror(x,6)  ^ ror(x,11) ^ ror(x,25); endfunction
    function [31:0] SSIG0(input [31:0] x); SSIG0 = ror(x,7)  ^ ror(x,18) ^ (x >> 3);  endfunction
    function [31:0] SSIG1(input [31:0] x); SSIG1 = ror(x,17) ^ ror(x,19) ^ (x >> 10); endfunction
    function [31:0] CH (input [31:0] e, input [31:0] f, input [31:0] g); CH  = (e & f) ^ (~e & g); endfunction
    function [31:0] MAJ(input [31:0] a, input [31:0] b, input [31:0] c); MAJ = (a & b) ^ (a & c) ^ (b & c); endfunction
    function [31:0] k_const(input [6:0] t);
        case (t)
            7'd0: k_const = 32'h428a2f98;
            7'd1: k_const = 32'h71374491;
            7'd2: k_const = 32'hb5c0fbcf;
            7'd3: k_const = 32'he9b5dba5;
            7'd4: k_const = 32'h3956c25b;
            7'd5: k_const = 32'h59f111f1;
            7'd6: k_const = 32'h923f82a4;
            7'd7: k_const = 32'hab1c5ed5;
            7'd8: k_const = 32'hd807aa98;
            7'd9: k_const = 32'h12835b01;
            7'd10: k_const = 32'h243185be;
            7'd11: k_const = 32'h550c7dc3;
            7'd12: k_const = 32'h72be5d74;
            7'd13: k_const = 32'h80deb1fe;
            7'd14: k_const = 32'h9bdc06a7;
            7'd15: k_const = 32'hc19bf174;
            7'd16: k_const = 32'he49b69c1;
            7'd17: k_const = 32'hefbe4786;
            7'd18: k_const = 32'h0fc19dc6;
            7'd19: k_const = 32'h240ca1cc;
            7'd20: k_const = 32'h2de92c6f;
            7'd21: k_const = 32'h4a7484aa;
            7'd22: k_const = 32'h5cb0a9dc;
            7'd23: k_const = 32'h76f988da;
            7'd24: k_const = 32'h983e5152;
            7'd25: k_const = 32'ha831c66d;
            7'd26: k_const = 32'hb00327c8;
            7'd27: k_const = 32'hbf597fc7;
            7'd28: k_const = 32'hc6e00bf3;
            7'd29: k_const = 32'hd5a79147;
            7'd30: k_const = 32'h06ca6351;
            7'd31: k_const = 32'h14292967;
            7'd32: k_const = 32'h27b70a85;
            7'd33: k_const = 32'h2e1b2138;
            7'd34: k_const = 32'h4d2c6dfc;
            7'd35: k_const = 32'h53380d13;
            7'd36: k_const = 32'h650a7354;
            7'd37: k_const = 32'h766a0abb;
            7'd38: k_const = 32'h81c2c92e;
            7'd39: k_const = 32'h92722c85;
            7'd40: k_const = 32'ha2bfe8a1;
            7'd41: k_const = 32'ha81a664b;
            7'd42: k_const = 32'hc24b8b70;
            7'd43: k_const = 32'hc76c51a3;
            7'd44: k_const = 32'hd192e819;
            7'd45: k_const = 32'hd6990624;
            7'd46: k_const = 32'hf40e3585;
            7'd47: k_const = 32'h106aa070;
            7'd48: k_const = 32'h19a4c116;
            7'd49: k_const = 32'h1e376c08;
            7'd50: k_const = 32'h2748774c;
            7'd51: k_const = 32'h34b0bcb5;
            7'd52: k_const = 32'h391c0cb3;
            7'd53: k_const = 32'h4ed8aa4a;
            7'd54: k_const = 32'h5b9cca4f;
            7'd55: k_const = 32'h682e6ff3;
            7'd56: k_const = 32'h748f82ee;
            7'd57: k_const = 32'h78a5636f;
            7'd58: k_const = 32'h84c87814;
            7'd59: k_const = 32'h8cc70208;
            7'd60: k_const = 32'h90befffa;
            7'd61: k_const = 32'ha4506ceb;
            7'd62: k_const = 32'hbef9a3f7;
            7'd63: k_const = 32'hc67178f2;
            default: k_const = 32'h0;
        endcase
    endfunction

    localparam IDLE=2'd0, WORK=2'd1, FIN=2'd2;
    reg [1:0]  state;
    reg [31:0] H0,H1,H2,H3,H4,H5,H6,H7;
    reg [31:0] a,b,c,d,e,f,g,h;
    reg [31:0] w [0:15];
    reg [6:0]  t;
    integer    idx;
    reg [31:0] T1, T2, nw;

    assign digest = {H0,H1,H2,H3,H4,H5,H6,H7};

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            state <= IDLE; ready <= 1'b1; digest_valid <= 1'b0; t <= 7'd0;
            H0<=0;H1<=0;H2<=0;H3<=0;H4<=0;H5<=0;H6<=0;H7<=0;
        end else begin
            case (state)
                IDLE: begin
                    ready <= 1'b1;
                    if (init || next) begin
                        for (idx=0; idx<16; idx=idx+1)
                            w[idx] <= block[511 - idx*32 -: 32];
                        if (init) begin
                            H0<=32'h6a09e667;H1<=32'hbb67ae85;H2<=32'h3c6ef372;H3<=32'ha54ff53a;H4<=32'h510e527f;H5<=32'h9b05688c;H6<=32'h1f83d9ab;H7<=32'h5be0cd19;
                            a<=32'h6a09e667;b<=32'hbb67ae85;c<=32'h3c6ef372;d<=32'ha54ff53a;e<=32'h510e527f;f<=32'h9b05688c;g<=32'h1f83d9ab;h<=32'h5be0cd19;
                        end else begin
                            a<=H0;b<=H1;c<=H2;d<=H3;e<=H4;f<=H5;g<=H6;h<=H7;
                        end
                        t <= 7'd0;
                        ready <= 1'b0;
                        digest_valid <= 1'b0;
                        state <= WORK;
                    end
                end
                WORK: begin
                    T1 = h + BSIG1(e) + CH(e,f,g) + k_const(t) + w[0];
                    T2 = BSIG0(a) + MAJ(a,b,c);
                    h <= g; g <= f; f <= e; e <= d + T1;
                    d <= c; c <= b; b <= a; a <= T1 + T2;
                    nw = SSIG1(w[14]) + w[9] + SSIG0(w[1]) + w[0];
                    for (idx=0; idx<15; idx=idx+1) w[idx] <= w[idx+1];
                    w[15] <= nw;
                    t <= t + 7'd1;
                    if (t == 7'd63) state <= FIN;
                end
                FIN: begin
                    H0<=H0+a;H1<=H1+b;H2<=H2+c;H3<=H3+d;H4<=H4+e;H5<=H5+f;H6<=H6+g;H7<=H7+h;
                    ready <= 1'b1;
                    digest_valid <= 1'b1;
                    state <= IDLE;
                end
                default: state <= IDLE;
            endcase
        end
    end
endmodule


module verified_sha256(
    input             clk,
    input             reset_n,
    input             cs,
    input             we,
    input      [7:0]  address,
    input      [31:0] write_data,
    output reg [31:0] read_data,
    output reg        error
);
    localparam ADDR_NAME0=8'h00, ADDR_NAME1=8'h01, ADDR_VERSION=8'h02;
    localparam ADDR_CTRL=8'h08, ADDR_STATUS=8'h09;
    localparam ADDR_BLOCK0=8'h10, ADDR_BLOCK15=8'h1f;
    localparam ADDR_DIGEST0=8'h20, ADDR_DIGEST7=8'h27;

    reg [31:0] block_reg [0:15];
    reg        init_reg, next_reg, mode_reg;
    integer    i;

    wire         core_ready, core_valid;
    wire [255:0] core_digest;
    wire [511:0] core_block =
        {block_reg[0],block_reg[1],block_reg[2],block_reg[3],
         block_reg[4],block_reg[5],block_reg[6],block_reg[7],
         block_reg[8],block_reg[9],block_reg[10],block_reg[11],
         block_reg[12],block_reg[13],block_reg[14],block_reg[15]};

    sha256_core core(
        .clk(clk), .reset_n(reset_n),
        .init(init_reg), .next(next_reg), .mode(mode_reg),
        .block(core_block),
        .ready(core_ready), .digest(core_digest), .digest_valid(core_valid)
    );

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            init_reg <= 1'b0; next_reg <= 1'b0; mode_reg <= 1'b0;
            for (i=0;i<16;i=i+1) block_reg[i] <= 32'h0;
        end else begin
            init_reg <= 1'b0;
            next_reg <= 1'b0;
            if (cs && we) begin
                if (address >= ADDR_BLOCK0 && address <= ADDR_BLOCK15)
                    block_reg[address - ADDR_BLOCK0] <= write_data;
                else if (address == ADDR_CTRL) begin
                    init_reg <= write_data[0];
                    next_reg <= write_data[1];
                    mode_reg <= write_data[2];
                end
            end
        end
    end

    always @* begin
        read_data = 32'h0;
        error     = 1'b0;
        if (cs && !we) begin
            if (address >= ADDR_DIGEST0 && address <= ADDR_DIGEST7)
                read_data = core_digest[255 - (address - ADDR_DIGEST0)*32 -: 32];
            else begin
                case (address)
                    ADDR_NAME0:   read_data = 32'h73686132; // "sha2"
                    ADDR_NAME1:   read_data = 32'h35362020; // "56  "
                    ADDR_VERSION: read_data = 32'h302e3830; // "0.80"
                    ADDR_STATUS:  read_data = {30'h0, core_valid, core_ready};
                    default:      error = 1'b1;
                endcase
            end
        end
    end
endmodule
