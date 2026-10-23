module AES_Encrypt(
    input clk,
    input rst,
    input [127:0] Plain_text,
    input EN,
    input [127:0] Key_in,
    output reg [127:0] Cypher_text
);

    // ------------------------------------------------------------
    // AES S-box
    // ------------------------------------------------------------
    function [7:0] sbox;
        input [7:0] a;
        begin
            case (a)
                8'h00: sbox = 8'h63;
                8'h01: sbox = 8'h7c;
                8'h02: sbox = 8'h77;
                8'h03: sbox = 8'h7b;
                8'h04: sbox = 8'hf2;
                8'h05: sbox = 8'h6b;
                8'h06: sbox = 8'h6f;
                8'h07: sbox = 8'hc5;
                8'h08: sbox = 8'h30;
                8'h09: sbox = 8'h01;
                8'h0a: sbox = 8'h67;
                8'h0b: sbox = 8'h2b;
                8'h0c: sbox = 8'hfe;
                8'h0d: sbox = 8'hd7;
                8'h0e: sbox = 8'hab;
                8'h0f: sbox = 8'h76;
                8'h10: sbox = 8'hca;
                8'h11: sbox = 8'h82;
                8'h12: sbox = 8'hc9;
                8'h13: sbox = 8'h7d;
                8'h14: sbox = 8'hfa;
                8'h15: sbox = 8'h59;
                8'h16: sbox = 8'h47;
                8'h17: sbox = 8'hf0;
                8'h18: sbox = 8'had;
                8'h19: sbox = 8'hd4;
                8'h1a: sbox = 8'ha2;
                8'h1b: sbox = 8'haf;
                8'h1c: sbox = 8'h9c;
                8'h1d: sbox = 8'ha4;
                8'h1e: sbox = 8'h72;
                8'h1f: sbox = 8'hc0;
                8'h20: sbox = 8'hb7;
                8'h21: sbox = 8'hfd;
                8'h22: sbox = 8'h93;
                8'h23: sbox = 8'h26;
                8'h24: sbox = 8'h36;
                8'h25: sbox = 8'h3f;
                8'h26: sbox = 8'hf7;
                8'h27: sbox = 8'hcc;
                8'h28: sbox = 8'h34;
                8'h29: sbox = 8'ha5;
                8'h2a: sbox = 8'he5;
                8'h2b: sbox = 8'hf1;
                8'h2c: sbox = 8'h71;
                8'h2d: sbox = 8'hd8;
                8'h2e: sbox = 8'h31;
                8'h2f: sbox = 8'h15;
                8'h30: sbox = 8'h04;
                8'h31: sbox = 8'hc7;
                8'h32: sbox = 8'h23;
                8'h33: sbox = 8'hc3;
                8'h34: sbox = 8'h18;
                8'h35: sbox = 8'h96;
                8'h36: sbox = 8'h05;
                8'h37: sbox = 8'h9a;
                8'h38: sbox = 8'h07;
                8'h39: sbox = 8'h12;
                8'h3a: sbox = 8'h80;
                8'h3b: sbox = 8'he2;
                8'h3c: sbox = 8'heb;
                8'h3d: sbox = 8'h27;
                8'h3e: sbox = 8'hb2;
                8'h3f: sbox = 8'h75;
                8'h40: sbox = 8'h09;
                8'h41: sbox = 8'h83;
                8'h42: sbox = 8'h2c;
                8'h43: sbox = 8'h1a;
                8'h44: sbox = 8'h1b;
                8'h45: sbox = 8'h6e;
                8'h46: sbox = 8'h5a;
                8'h47: sbox = 8'ha0;
                8'h48: sbox = 8'h52;
                8'h49: sbox = 8'h3b;
                8'h4a: sbox = 8'hd6;
                8'h4b: sbox = 8'hb3;
                8'h4c: sbox = 8'h29;
                8'h4d: sbox = 8'he3;
                8'h4e: sbox = 8'h2f;
                8'h4f: sbox = 8'h84;
                8'h50: sbox = 8'h53;
                8'h51: sbox = 8'hd1;
                8'h52: sbox = 8'h00;
                8'h53: sbox = 8'hed;
                8'h54: sbox = 8'h20;
                8'h55: sbox = 8'hfc;
                8'h56: sbox = 8'hb1;
                8'h57: sbox = 8'h5b;
                8'h58: sbox = 8'h6a;
                8'h59: sbox = 8'hcb;
                8'h5a: sbox = 8'hbe;
                8'h5b: sbox = 8'h39;
                8'h5c: sbox = 8'h4a;
                8'h5d: sbox = 8'h4c;
                8'h5e: sbox = 8'h58;
                8'h5f: sbox = 8'hcf;
                8'h60: sbox = 8'hd0;
                8'h61: sbox = 8'hef;
                8'h62: sbox = 8'haa;
                8'h63: sbox = 8'hfb;
                8'h64: sbox = 8'h43;
                8'h65: sbox = 8'h4d;
                8'h66: sbox = 8'h33;
                8'h67: sbox = 8'h85;
                8'h68: sbox = 8'h45;
                8'h69: sbox = 8'hf9;
                8'h6a: sbox = 8'h02;
                8'h6b: sbox = 8'h7f;
                8'h6c: sbox = 8'h50;
                8'h6d: sbox = 8'h3c;
                8'h6e: sbox = 8'h9f;
                8'h6f: sbox = 8'ha8;
                8'h70: sbox = 8'h51;
                8'h71: sbox = 8'ha3;
                8'h72: sbox = 8'h40;
                8'h73: sbox = 8'h8f;
                8'h74: sbox = 8'h92;
                8'h75: sbox = 8'h9d;
                8'h76: sbox = 8'h38;
                8'h77: sbox = 8'hf5;
                8'h78: sbox = 8'hbc;
                8'h79: sbox = 8'hb6;
                8'h7a: sbox = 8'hda;
                8'h7b: sbox = 8'h21;
                8'h7c: sbox = 8'h10;
                8'h7d: sbox = 8'hff;
                8'h7e: sbox = 8'hf3;
                8'h7f: sbox = 8'hd2;
                8'h80: sbox = 8'hcd;
                8'h81: sbox = 8'h0c;
                8'h82: sbox = 8'h13;
                8'h83: sbox = 8'hec;
                8'h84: sbox = 8'h5f;
                8'h85: sbox = 8'h97;
                8'h86: sbox = 8'h44;
                8'h87: sbox = 8'h17;
                8'h88: sbox = 8'hc4;
                8'h89: sbox = 8'ha7;
                8'h8a: sbox = 8'h7e;
                8'h8b: sbox = 8'h3d;
                8'h8c: sbox = 8'h64;
                8'h8d: sbox = 8'h5d;
                8'h8e: sbox = 8'h19;
                8'h8f: sbox = 8'h73;
                8'h90: sbox = 8'h60;
                8'h91: sbox = 8'h81;
                8'h92: sbox = 8'h4f;
                8'h93: sbox = 8'hdc;
                8'h94: sbox = 8'h22;
                8'h95: sbox = 8'h2a;
                8'h96: sbox = 8'h90;
                8'h97: sbox = 8'h88;
                8'h98: sbox = 8'h46;
                8'h99: sbox = 8'hee;
                8'h9a: sbox = 8'hb8;
                8'h9b: sbox = 8'h14;
                8'h9c: sbox = 8'hde;
                8'h9d: sbox = 8'h5e;
                8'h9e: sbox = 8'h0b;
                8'h9f: sbox = 8'hdb;
                8'ha0: sbox = 8'he0;
                8'ha1: sbox = 8'h32;
                8'ha2: sbox = 8'h3a;
                8'ha3: sbox = 8'h0a;
                8'ha4: sbox = 8'h49;
                8'ha5: sbox = 8'h06;
                8'ha6: sbox = 8'h24;
                8'ha7: sbox = 8'h5c;
                8'ha8: sbox = 8'hc2;
                8'ha9: sbox = 8'hd3;
                8'haa: sbox = 8'hac;
                8'hab: sbox = 8'h62;
                8'hac: sbox = 8'h91;
                8'had: sbox = 8'h95;
                8'hae: sbox = 8'he4;
                8'haf: sbox = 8'h79;
                8'hb0: sbox = 8'he7;
                8'hb1: sbox = 8'hc8;
                8'hb2: sbox = 8'h37;
                8'hb3: sbox = 8'h6d;
                8'hb4: sbox = 8'h8d;
                8'hb5: sbox = 8'hd5;
                8'hb6: sbox = 8'h4e;
                8'hb7: sbox = 8'ha9;
                8'hb8: sbox = 8'h6c;
                8'hb9: sbox = 8'h56;
                8'hba: sbox = 8'hf4;
                8'hbb: sbox = 8'hea;
                8'hbc: sbox = 8'h65;
                8'hbd: sbox = 8'h7a;
                8'hbe: sbox = 8'hae;
                8'hbf: sbox = 8'h08;
                8'hc0: sbox = 8'hba;
                8'hc1: sbox = 8'h78;
                8'hc2: sbox = 8'h25;
                8'hc3: sbox = 8'h2e;
                8'hc4: sbox = 8'h1c;
                8'hc5: sbox = 8'ha6;
                8'hc6: sbox = 8'hb4;
                8'hc7: sbox = 8'hc6;
                8'hc8: sbox = 8'he8;
                8'hc9: sbox = 8'hdd;
                8'hca: sbox = 8'h74;
                8'hcb: sbox = 8'h1f;
                8'hcc: sbox = 8'h4b;
                8'hcd: sbox = 8'hbd;
                8'hce: sbox = 8'h8b;
                8'hcf: sbox = 8'h8a;
                8'hd0: sbox = 8'h70;
                8'hd1: sbox = 8'h3e;
                8'hd2: sbox = 8'hb5;
                8'hd3: sbox = 8'h66;
                8'hd4: sbox = 8'h48;
                8'hd5: sbox = 8'h03;
                8'hd6: sbox = 8'hf6;
                8'hd7: sbox = 8'h0e;
                8'hd8: sbox = 8'h61;
                8'hd9: sbox = 8'h35;
                8'hda: sbox = 8'h57;
                8'hdb: sbox = 8'hb9;
                8'hdc: sbox = 8'h86;
                8'hdd: sbox = 8'hc1;
                8'hde: sbox = 8'h1d;
                8'hdf: sbox = 8'h9e;
                8'he0: sbox = 8'he1;
                8'he1: sbox = 8'hf8;
                8'he2: sbox = 8'h98;
                8'he3: sbox = 8'h11;
                8'he4: sbox = 8'h69;
                8'he5: sbox = 8'hd9;
                8'he6: sbox = 8'h8e;
                8'he7: sbox = 8'h94;
                8'he8: sbox = 8'h9b;
                8'he9: sbox = 8'h1e;
                8'hea: sbox = 8'h87;
                8'heb: sbox = 8'he9;
                8'hec: sbox = 8'hce;
                8'hed: sbox = 8'h55;
                8'hee: sbox = 8'h28;
                8'hef: sbox = 8'hdf;
                8'hf0: sbox = 8'h8c;
                8'hf1: sbox = 8'ha1;
                8'hf2: sbox = 8'h89;
                8'hf3: sbox = 8'h0d;
                8'hf4: sbox = 8'hbf;
                8'hf5: sbox = 8'he6;
                8'hf6: sbox = 8'h42;
                8'hf7: sbox = 8'h68;
                8'hf8: sbox = 8'h41;
                8'hf9: sbox = 8'h99;
                8'hfa: sbox = 8'h2d;
                8'hfb: sbox = 8'h0f;
                8'hfc: sbox = 8'hb0;
                8'hfd: sbox = 8'h54;
                8'hfe: sbox = 8'hbb;
                8'hff: sbox = 8'h16;
            endcase
        end
    endfunction

    // ------------------------------------------------------------
    // GF(2^8) multiply by 2
    // ------------------------------------------------------------
    function [7:0] xtime;
        input [7:0] x;
        begin
            xtime = {x[6:0], 1'b0} ^ (x[7] ? 8'h1B : 8'h00);
        end
    endfunction

    // ------------------------------------------------------------
    // SubBytes
    // ------------------------------------------------------------
    function [127:0] sub_bytes;
        input [127:0] s;
        begin
            sub_bytes = {
                sbox[s[127:120]], sbox[s[119:112]], sbox[s[111:104]], sbox[s[103:96]],
                sbox[s[95:88]],  sbox[s[87:80]],  sbox[s[79:72]],  sbox[s[71:64]],
                sbox[s[63:56]],  sbox[s[55:48]],  sbox[s[47:40]],  sbox[s[39:32]],
                sbox[s[31:24]],  sbox[s[23:16]],  sbox[s[15:8]],   sbox[s[7:0]]
            };
        end
    endfunction

    // ------------------------------------------------------------
    // ShiftRows
    // ------------------------------------------------------------
    function [127:0] shift_rows;
        input [127:0] s;
        begin
            shift_rows = {
                s[127:120], s[87:80],   s[47:40],   s[7:0],
                s[95:88],   s[55:48],   s[15:8],    s[103:96],
                s[63:56],   s[23:16],   s[111:104], s[71:64],
                s[31:24],   s[119:112], s[79:72],   s[39:32]
            };
        end
    endfunction

    // ------------------------------------------------------------
    // MixColumns
    // ------------------------------------------------------------
    function [127:0] mix_columns;
        input [127:0] s;
        reg [7:0] a0, a1, a2, a3, b0, b1, b2, b3;
        reg [127:0] tmp;
        begin
            // Column 0
            a0 = s[127:120];
            a1 = s[119:112];
            a2 = s[111:104];
            a3 = s[103:96];
            b0 = xtime(a0) ^ xtime(a1) ^ a1 ^ a2 ^ a3;
            b1 = a0 ^ xtime(a1) ^ xtime(a2) ^ a2 ^ a3;
            b2 = a0 ^ a1 ^ xtime(a2) ^ xtime(a3) ^ a3;
            b3 = xtime(a0) ^ a0 ^ a1 ^ a2 ^ xtime(a3);
            tmp[127:120] = b0;
            tmp[119:112] = b1;
            tmp[111:104] = b2;
            tmp[103:96]  = b3;

            // Column 1
            a0 = s[95:88];
            a1 = s[87:80];
            a2 = s[79:72];
            a3 = s[71:64];
            b0 = xtime(a0) ^ xtime(a1) ^ a1 ^ a2 ^ a3;
            b1 = a0 ^ xtime(a1) ^ xtime(a2) ^ a2 ^ a3;
            b2 = a0 ^ a1 ^ xtime(a2) ^ xtime(a3) ^ a3;
            b3 = xtime(a0) ^ a0 ^ a1 ^ a2 ^ xtime(a3);
            tmp[95:88]  = b0;
            tmp[87:80]  = b1;
            tmp[79:72]  = b2;
            tmp[71:64]  = b3;

            // Column 2
            a0 = s[63:56];
            a1 = s[55:48];
            a2 = s[47:40];
            a3 = s[39:32];
            b0 = xtime(a0) ^ xtime(a1) ^ a1 ^ a2 ^ a3;
            b1 = a0 ^ xtime(a1) ^ xtime(a2) ^ a2 ^ a3;
            b2 = a0 ^ a1 ^ xtime(a2) ^ xtime(a3) ^ a3;
            b3 = xtime(a0) ^ a0 ^ a1 ^ a2 ^ xtime(a3);
            tmp[63:56]  = b0;
            tmp[55:48]  = b1;
            tmp[47:40]  = b2;
            tmp[39:32]  = b3;

            // Column 3
            a0 = s[31:24];
            a1 = s[23:16];
            a2 = s[15:8];
            a3 = s[7:0];
            b0 = xtime(a0) ^ xtime(a1) ^ a1 ^ a2 ^ a3;
            b1 = a0 ^ xtime(a1) ^ xtime(a2) ^ a2 ^ a3;
            b2 = a0 ^ a1 ^ xtime(a2) ^ xtime(a3) ^ a3;
            b3 = xtime(a0) ^ a0 ^ a1 ^ a2 ^ xtime(a3);
            tmp[31:24]  = b0;
            tmp[23:16]  = b1;
            tmp[15:8]   = b2;
            tmp[7:0]    = b3;

            mix_columns = tmp;
        end
    endfunction

    // ------------------------------------------------------------
    // AES Rcon
    // ------------------------------------------------------------
    function [7:0] rcon;
        input [3:0] r;
        begin
            case (r)
                4'd1:  rcon = 8'h01;
                4'd2:  rcon = 8'h02;
                4'd3:  rcon = 8'h04;
                4'd4:  rcon = 8'h08;
                4'd5:  rcon = 8'h10;
                4'd6:  rcon = 8'h20;
                4'd7:  rcon = 8'h40;
                4'd8:  rcon = 8'h80;
                4'd9:  rcon = 8'h1B;
                4'd10: rcon = 8'h36;
                default: rcon = 8'h00;
            endcase
        end
    endfunction

    // ------------------------------------------------------------
    // Key expansion for one round
    // ------------------------------------------------------------
    function [127:0] key_expand;
        input [127:0] prev;
        input [3:0] rnd;
        reg [31:0] w0, w1, w2, w3, temp, w4, w5, w6, w7;
        begin
            w0 = prev[127:96];
            w1 = prev[95:64];
            w2 = prev[63:32];
            w3 = prev[31:0];

            temp = {sbox[w3[23:16]], sbox[w3[15:8]], sbox[w3[7:0]], sbox[w3[31:24]]}
                   ^ {rcon(rnd), 24'h000000};

            w4 = w0 ^ temp;
            w5 = w1 ^ w4;
            w6 = w2 ^ w5;
            w7 = w3 ^ w6;

            key_expand = {w4, w5, w6, w7};
        end
    endfunction

    // ------------------------------------------------------------
    // Full round: SubBytes, ShiftRows, MixColumns, AddRoundKey
    // ------------------------------------------------------------
    function [127:0] round_top;
        input [127:0] state;
        input [127:0] rkey;
        begin
            round_top = mix_columns(shift_rows(sub_bytes(state))) ^ rkey;
        end
    endfunction

    // ------------------------------------------------------------
    // Final round: SubBytes, ShiftRows, AddRoundKey
    // ------------------------------------------------------------
    function [127:0] final_round;
        input [127:0] state;
        input [127:0] rkey;
        begin
            final_round = shift_rows(sub_bytes(state)) ^ rkey;
        end
    endfunction

    // ------------------------------------------------------------
    // Pipeline registers
    // ------------------------------------------------------------
    reg [127:0] state [0:9];
    reg [127:0] rkey  [0:9];
    reg [9:0]   valid;

    integer i;

    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < 10; i = i + 1) begin
                state[i] <= 128'h0;
                rkey[i]  <= 128'h0;
            end
            valid <= 10'h0;
            Cypher_text <= 128'h0;
        end else begin
            // Stage 0: initial AddRoundKey
            if (EN) begin
                state[0] <= Plain_text ^ Key_in;
                rkey[0]  <= Key_in;
            end else begin
                state[0] <= 128'h0;
                rkey[0]  <= 128'h0;
            end
            valid[0] <= EN;

            // Stages 1..9: full AES rounds
            for (i = 1; i < 10; i = i + 1) begin
                state[i] <= round_top(state[i-1], key_expand(rkey[i-1], i));
                rkey[i]  <= key_expand(rkey[i-1], i);
                valid[i] <= valid[i-1];
            end

            // Final round
            if (valid[9]) begin
                Cypher_text <= final_round(state[9], key_expand(rkey[9], 4'd10));
            end
        end
    end

endmodule
