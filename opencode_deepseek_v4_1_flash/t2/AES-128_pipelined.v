module AES_Encrypt(
    input clk,
    input rst,
    input [127:0] Plain_text,
    input EN,
    input [127:0] Key_in,
    output reg [127:0] Cypher_text
);

    // ------------------------------------------------------------------------
    // AES S-Box
    // ------------------------------------------------------------------------
    function [7:0] sbox;
        input [7:0] in;
        begin
            case (in)
                8'h00: sbox = 8'h63; 8'h01: sbox = 8'h7c; 8'h02: sbox = 8'h77; 8'h03: sbox = 8'h7b;
                8'h04: sbox = 8'hf2; 8'h05: sbox = 8'h6b; 8'h06: sbox = 8'h6f; 8'h07: sbox = 8'hc5;
                8'h08: sbox = 8'h30; 8'h09: sbox = 8'h01; 8'h0a: sbox = 8'h67; 8'h0b: sbox = 8'h2b;
                8'h0c: sbox = 8'hfe; 8'h0d: sbox = 8'hd7; 8'h0e: sbox = 8'hab; 8'h0f: sbox = 8'h76;
                8'h10: sbox = 8'hca; 8'h11: sbox = 8'h82; 8'h12: sbox = 8'hc9; 8'h13: sbox = 8'h7d;
                8'h14: sbox = 8'hfa; 8'h15: sbox = 8'h59; 8'h16: sbox = 8'h47; 8'h17: sbox = 8'hf0;
                8'h18: sbox = 8'had; 8'h19: sbox = 8'hd4; 8'h1a: sbox = 8'ha2; 8'h1b: sbox = 8'haf;
                8'h1c: sbox = 8'h9c; 8'h1d: sbox = 8'ha4; 8'h1e: sbox = 8'h72; 8'h1f: sbox = 8'hc0;
                8'h20: sbox = 8'hb7; 8'h21: sbox = 8'hfd; 8'h22: sbox = 8'h93; 8'h23: sbox = 8'h26;
                8'h24: sbox = 8'h36; 8'h25: sbox = 8'h3f; 8'h26: sbox = 8'hf7; 8'h27: sbox = 8'hcc;
                8'h28: sbox = 8'h34; 8'h29: sbox = 8'ha5; 8'h2a: sbox = 8'he5; 8'h2b: sbox = 8'hf1;
                8'h2c: sbox = 8'h71; 8'h2d: sbox = 8'hd8; 8'h2e: sbox = 8'h31; 8'h2f: sbox = 8'h15;
                8'h30: sbox = 8'h04; 8'h31: sbox = 8'hc7; 8'h32: sbox = 8'h23; 8'h33: sbox = 8'hc3;
                8'h34: sbox = 8'h18; 8'h35: sbox = 8'h96; 8'h36: sbox = 8'h05; 8'h37: sbox = 8'h9a;
                8'h38: sbox = 8'h07; 8'h39: sbox = 8'h12; 8'h3a: sbox = 8'h80; 8'h3b: sbox = 8'he2;
                8'h3c: sbox = 8'heb; 8'h3d: sbox = 8'h27; 8'h3e: sbox = 8'hb2; 8'h3f: sbox = 8'h75;
                8'h40: sbox = 8'h09; 8'h41: sbox = 8'h83; 8'h42: sbox = 8'h2c; 8'h43: sbox = 8'h1a;
                8'h44: sbox = 8'h1b; 8'h45: sbox = 8'h6e; 8'h46: sbox = 8'h5a; 8'h47: sbox = 8'ha0;
                8'h48: sbox = 8'h52; 8'h49: sbox = 8'h3b; 8'h4a: sbox = 8'hd6; 8'h4b: sbox = 8'hb3;
                8'h4c: sbox = 8'h29; 8'h4d: sbox = 8'he3; 8'h4e: sbox = 8'h2f; 8'h4f: sbox = 8'h84;
                8'h50: sbox = 8'h53; 8'h51: sbox = 8'hd1; 8'h52: sbox = 8'h00; 8'h53: sbox = 8'hed;
                8'h54: sbox = 8'h20; 8'h55: sbox = 8'hfc; 8'h56: sbox = 8'hb1; 8'h57: sbox = 8'h5b;
                8'h58: sbox = 8'h6a; 8'h59: sbox = 8'hcb; 8'h5a: sbox = 8'hbe; 8'h5b: sbox = 8'h39;
                8'h5c: sbox = 8'h4a; 8'h5d: sbox = 8'h4c; 8'h5e: sbox = 8'h58; 8'h5f: sbox = 8'hcf;
                8'h60: sbox = 8'hd0; 8'h61: sbox = 8'hef; 8'h62: sbox = 8'haa; 8'h63: sbox = 8'hfb;
                8'h64: sbox = 8'h43; 8'h65: sbox = 8'h4d; 8'h66: sbox = 8'h33; 8'h67: sbox = 8'h85;
                8'h68: sbox = 8'h45; 8'h69: sbox = 8'hf9; 8'h6a: sbox = 8'h02; 8'h6b: sbox = 8'h7f;
                8'h6c: sbox = 8'h50; 8'h6d: sbox = 8'h3c; 8'h6e: sbox = 8'h9f; 8'h6f: sbox = 8'ha8;
                8'h70: sbox = 8'h51; 8'h71: sbox = 8'ha3; 8'h72: sbox = 8'h40; 8'h73: sbox = 8'h8f;
                8'h74: sbox = 8'h92; 8'h75: sbox = 8'h9d; 8'h76: sbox = 8'h38; 8'h77: sbox = 8'hf5;
                8'h78: sbox = 8'hbc; 8'h79: sbox = 8'hb6; 8'h7a: sbox = 8'hda; 8'h7b: sbox = 8'h21;
                8'h7c: sbox = 8'h10; 8'h7d: sbox = 8'hff; 8'h7e: sbox = 8'hf3; 8'h7f: sbox = 8'hd2;
                8'h80: sbox = 8'hcd; 8'h81: sbox = 8'h0c; 8'h82: sbox = 8'h13; 8'h83: sbox = 8'hec;
                8'h84: sbox = 8'h5f; 8'h85: sbox = 8'h97; 8'h86: sbox = 8'h44; 8'h87: sbox = 8'h17;
                8'h88: sbox = 8'hc4; 8'h89: sbox = 8'ha7; 8'h8a: sbox = 8'h7e; 8'h8b: sbox = 8'h3d;
                8'h8c: sbox = 8'h64; 8'h8d: sbox = 8'h5d; 8'h8e: sbox = 8'h19; 8'h8f: sbox = 8'h73;
                8'h90: sbox = 8'h60; 8'h91: sbox = 8'h81; 8'h92: sbox = 8'h4f; 8'h93: sbox = 8'hdc;
                8'h94: sbox = 8'h22; 8'h95: sbox = 8'h2a; 8'h96: sbox = 8'h90; 8'h97: sbox = 8'h88;
                8'h98: sbox = 8'h46; 8'h99: sbox = 8'hee; 8'h9a: sbox = 8'hb8; 8'h9b: sbox = 8'h14;
                8'h9c: sbox = 8'hde; 8'h9d: sbox = 8'h5e; 8'h9e: sbox = 8'h0b; 8'h9f: sbox = 8'hdb;
                8'ha0: sbox = 8'he0; 8'ha1: sbox = 8'h32; 8'ha2: sbox = 8'h3a; 8'ha3: sbox = 8'h0a;
                8'ha4: sbox = 8'h49; 8'ha5: sbox = 8'h06; 8'ha6: sbox = 8'h24; 8'ha7: sbox = 8'h5c;
                8'ha8: sbox = 8'hc2; 8'ha9: sbox = 8'hd3; 8'haa: sbox = 8'hac; 8'hab: sbox = 8'h62;
                8'hac: sbox = 8'h91; 8'had: sbox = 8'h95; 8'hae: sbox = 8'he4; 8'haf: sbox = 8'h79;
                8'hb0: sbox = 8'he7; 8'hb1: sbox = 8'hc8; 8'hb2: sbox = 8'h37; 8'hb3: sbox = 8'h6d;
                8'hb4: sbox = 8'h8d; 8'hb5: sbox = 8'hd5; 8'hb6: sbox = 8'h4e; 8'hb7: sbox = 8'ha9;
                8'hb8: sbox = 8'h6c; 8'hb9: sbox = 8'h56; 8'hba: sbox = 8'hf4; 8'hbb: sbox = 8'hea;
                8'hbc: sbox = 8'h65; 8'hbd: sbox = 8'h7a; 8'hbe: sbox = 8'hae; 8'hbf: sbox = 8'h08;
                8'hc0: sbox = 8'hba; 8'hc1: sbox = 8'h78; 8'hc2: sbox = 8'h25; 8'hc3: sbox = 8'h2e;
                8'hc4: sbox = 8'h1c; 8'hc5: sbox = 8'ha6; 8'hc6: sbox = 8'hb4; 8'hc7: sbox = 8'hc6;
                8'hc8: sbox = 8'he8; 8'hc9: sbox = 8'hdd; 8'hca: sbox = 8'h74; 8'hcb: sbox = 8'h1f;
                8'hcc: sbox = 8'h4b; 8'hcd: sbox = 8'hbd; 8'hce: sbox = 8'h8b; 8'hcf: sbox = 8'h8a;
                8'hd0: sbox = 8'h70; 8'hd1: sbox = 8'h3e; 8'hd2: sbox = 8'hb5; 8'hd3: sbox = 8'h66;
                8'hd4: sbox = 8'h48; 8'hd5: sbox = 8'h03; 8'hd6: sbox = 8'hf6; 8'hd7: sbox = 8'h0e;
                8'hd8: sbox = 8'h61; 8'hd9: sbox = 8'h35; 8'hda: sbox = 8'h57; 8'hdb: sbox = 8'hb9;
                8'hdc: sbox = 8'h86; 8'hdd: sbox = 8'hc1; 8'hde: sbox = 8'h1d; 8'hdf: sbox = 8'h9e;
                8'he0: sbox = 8'he1; 8'he1: sbox = 8'hf8; 8'he2: sbox = 8'h98; 8'he3: sbox = 8'h11;
                8'he4: sbox = 8'h69; 8'he5: sbox = 8'hd9; 8'he6: sbox = 8'h8e; 8'he7: sbox = 8'h94;
                8'he8: sbox = 8'h9b; 8'he9: sbox = 8'h1e; 8'hea: sbox = 8'h87; 8'heb: sbox = 8'he9;
                8'hec: sbox = 8'hce; 8'hed: sbox = 8'h55; 8'hee: sbox = 8'h28; 8'hef: sbox = 8'hdf;
                8'hf0: sbox = 8'h8c; 8'hf1: sbox = 8'ha1; 8'hf2: sbox = 8'h89; 8'hf3: sbox = 8'h0d;
                8'hf4: sbox = 8'hbf; 8'hf5: sbox = 8'he6; 8'hf6: sbox = 8'h42; 8'hf7: sbox = 8'h68;
                8'hf8: sbox = 8'h41; 8'hf9: sbox = 8'h99; 8'hfa: sbox = 8'h2d; 8'hfb: sbox = 8'h0f;
                8'hfc: sbox = 8'hb0; 8'hfd: sbox = 8'h54; 8'hfe: sbox = 8'hbb; 8'hff: sbox = 8'h16;
                default: sbox = 8'h00;
            endcase
        end
    endfunction

    // ------------------------------------------------------------------------
    // GF(2^8) multiplication by 2
    // ------------------------------------------------------------------------
    function [7:0] xtime;
        input [7:0] b;
        begin
            xtime = {b[6:0], 1'b0} ^ (8'h1b & {8{b[7]}});
        end
    endfunction

    // ------------------------------------------------------------------------
    // SubBytes
    // ------------------------------------------------------------------------
    function [127:0] SubBytes;
        input [127:0] state;
        begin
            SubBytes = {
                sbox(state[127:120]), sbox(state[119:112]), sbox(state[111:104]), sbox(state[103:96]),
                sbox(state[95:88]),   sbox(state[87:80]),   sbox(state[79:72]),   sbox(state[71:64]),
                sbox(state[63:56]),   sbox(state[55:48]),   sbox(state[47:40]),   sbox(state[39:32]),
                sbox(state[31:24]),   sbox(state[23:16]),   sbox(state[15:8]),    sbox(state[7:0])
            };
        end
    endfunction

    // ------------------------------------------------------------------------
    // ShiftRows
    // ------------------------------------------------------------------------
    function [127:0] ShiftRows;
        input [127:0] state;
        reg [7:0] b0,b1,b2,b3,b4,b5,b6,b7,b8,b9,b10,b11,b12,b13,b14,b15;
        begin
            b0 = state[127:120]; b1 = state[119:112]; b2 = state[111:104]; b3 = state[103:96];
            b4 = state[95:88];   b5 = state[87:80];   b6 = state[79:72];   b7 = state[71:64];
            b8 = state[63:56];   b9 = state[55:48];   b10 = state[47:40];  b11 = state[39:32];
            b12 = state[31:24];  b13 = state[23:16];  b14 = state[15:8];   b15 = state[7:0];
            ShiftRows = {b0, b5, b10, b15,
                         b4, b9, b14, b3,
                         b8, b13, b2, b7,
                         b12, b1, b6, b11};
        end
    endfunction

    // ------------------------------------------------------------------------
    // MixColumns
    // ------------------------------------------------------------------------
    function [127:0] MixColumns;
        input [127:0] state;
        reg [7:0] b0,b1,b2,b3,b4,b5,b6,b7,b8,b9,b10,b11,b12,b13,b14,b15;
        reg [7:0] n0,n1,n2,n3,n4,n5,n6,n7,n8,n9,n10,n11,n12,n13,n14,n15;
        begin
            b0 = state[127:120]; b1 = state[119:112]; b2 = state[111:104]; b3 = state[103:96];
            b4 = state[95:88];   b5 = state[87:80];   b6 = state[79:72];   b7 = state[71:64];
            b8 = state[63:56];   b9 = state[55:48];   b10 = state[47:40];  b11 = state[39:32];
            b12 = state[31:24];  b13 = state[23:16];  b14 = state[15:8];   b15 = state[7:0];

            // Column 0
            n0 = xtime(b0) ^ (xtime(b1) ^ b1) ^ b2 ^ b3;
            n1 = b0 ^ xtime(b1) ^ (xtime(b2) ^ b2) ^ b3;
            n2 = b0 ^ b1 ^ xtime(b2) ^ (xtime(b3) ^ b3);
            n3 = (xtime(b0) ^ b0) ^ b1 ^ b2 ^ xtime(b3);

            // Column 1
            n4 = xtime(b4) ^ (xtime(b5) ^ b5) ^ b6 ^ b7;
            n5 = b4 ^ xtime(b5) ^ (xtime(b6) ^ b6) ^ b7;
            n6 = b4 ^ b5 ^ xtime(b6) ^ (xtime(b7) ^ b7);
            n7 = (xtime(b4) ^ b4) ^ b5 ^ b6 ^ xtime(b7);

            // Column 2
            n8 = xtime(b8) ^ (xtime(b9) ^ b9) ^ b10 ^ b11;
            n9 = b8 ^ xtime(b9) ^ (xtime(b10) ^ b10) ^ b11;
            n10 = b8 ^ b9 ^ xtime(b10) ^ (xtime(b11) ^ b11);
            n11 = (xtime(b8) ^ b8) ^ b9 ^ b10 ^ xtime(b11);

            // Column 3
            n12 = xtime(b12) ^ (xtime(b13) ^ b13) ^ b14 ^ b15;
            n13 = b12 ^ xtime(b13) ^ (xtime(b14) ^ b14) ^ b15;
            n14 = b12 ^ b13 ^ xtime(b14) ^ (xtime(b15) ^ b15);
            n15 = (xtime(b12) ^ b12) ^ b13 ^ b14 ^ xtime(b15);

            MixColumns = {n0,n1,n2,n3,n4,n5,n6,n7,n8,n9,n10,n11,n12,n13,n14,n15};
        end
    endfunction

    // ------------------------------------------------------------------------
    // Rcon
    // ------------------------------------------------------------------------
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
                4'd9:  rcon = 8'h1b;
                4'd10: rcon = 8'h36;
                default: rcon = 8'h00;
            endcase
        end
    endfunction

    // ------------------------------------------------------------------------
    // Next round key generation
    // ------------------------------------------------------------------------
    function [127:0] next_key;
        input [127:0] key;
        input [3:0] r;
        reg [31:0] w0,w1,w2,w3, rot, sub, temp, nw0,nw1,nw2,nw3;
        begin
            w0 = key[127:96];
            w1 = key[95:64];
            w2 = key[63:32];
            w3 = key[31:0];
            rot = {w3[23:16], w3[15:8], w3[7:0], w3[31:24]};
            sub = {sbox(rot[31:24]), sbox(rot[23:16]), sbox(rot[15:8]), sbox(rot[7:0])};
            temp = sub ^ {rcon(r), 24'h000000};
            nw0 = w0 ^ temp;
            nw1 = w1 ^ nw0;
            nw2 = w2 ^ nw1;
            nw3 = w3 ^ nw2;
            next_key = {nw0, nw1, nw2, nw3};
        end
    endfunction

    // ------------------------------------------------------------------------
    // Pipeline registers
    // ------------------------------------------------------------------------
    reg [127:0] state_0, key_0;
    reg [127:0] state_1, key_1;
    reg [127:0] state_2, key_2;
    reg [127:0] state_3, key_3;
    reg [127:0] state_4, key_4;
    reg [127:0] state_5, key_5;
    reg [127:0] state_6, key_6;
    reg [127:0] state_7, key_7;
    reg [127:0] state_8, key_8;
    reg [127:0] state_9, key_9;

    reg valid_0, valid_1, valid_2, valid_3, valid_4;
    reg valid_5, valid_6, valid_7, valid_8, valid_9;

    // ------------------------------------------------------------------------
    // Main pipeline
    // ------------------------------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state_0 <= 128'b0; key_0 <= 128'b0;
            state_1 <= 128'b0; key_1 <= 128'b0;
            state_2 <= 128'b0; key_2 <= 128'b0;
            state_3 <= 128'b0; key_3 <= 128'b0;
            state_4 <= 128'b0; key_4 <= 128'b0;
            state_5 <= 128'b0; key_5 <= 128'b0;
            state_6 <= 128'b0; key_6 <= 128'b0;
            state_7 <= 128'b0; key_7 <= 128'b0;
            state_8 <= 128'b0; key_8 <= 128'b0;
            state_9 <= 128'b0; key_9 <= 128'b0;
            valid_0 <= 1'b0; valid_1 <= 1'b0; valid_2 <= 1'b0; valid_3 <= 1'b0;
            valid_4 <= 1'b0; valid_5 <= 1'b0; valid_6 <= 1'b0; valid_7 <= 1'b0;
            valid_8 <= 1'b0; valid_9 <= 1'b0;
            Cypher_text <= 128'b0;
        end else begin
            // Stage 0: initial AddRoundKey
            if (EN) begin
                state_0 <= Plain_text ^ Key_in;
                key_0 <= Key_in;
                valid_0 <= 1'b1;
            end else begin
                valid_0 <= 1'b0;
            end

            // Stage 1: round 1
            key_1 <= next_key(key_0, 4'd1);
            state_1 <= MixColumns(ShiftRows(SubBytes(state_0))) ^ next_key(key_0, 4'd1);
            valid_1 <= valid_0;

            // Stage 2: round 2
            key_2 <= next_key(key_1, 4'd2);
            state_2 <= MixColumns(ShiftRows(SubBytes(state_1))) ^ next_key(key_1, 4'd2);
            valid_2 <= valid_1;

            // Stage 3: round 3
            key_3 <= next_key(key_2, 4'd3);
            state_3 <= MixColumns(ShiftRows(SubBytes(state_2))) ^ next_key(key_2, 4'd3);
            valid_3 <= valid_2;

            // Stage 4: round 4
            key_4 <= next_key(key_3, 4'd4);
            state_4 <= MixColumns(ShiftRows(SubBytes(state_3))) ^ next_key(key_3, 4'd4);
            valid_4 <= valid_3;

            // Stage 5: round 5
            key_5 <= next_key(key_4, 4'd5);
            state_5 <= MixColumns(ShiftRows(SubBytes(state_4))) ^ next_key(key_4, 4'd5);
            valid_5 <= valid_4;

            // Stage 6: round 6
            key_6 <= next_key(key_5, 4'd6);
            state_6 <= MixColumns(ShiftRows(SubBytes(state_5))) ^ next_key(key_5, 4'd6);
            valid_6 <= valid_5;

            // Stage 7: round 7
            key_7 <= next_key(key_6, 4'd7);
            state_7 <= MixColumns(ShiftRows(SubBytes(state_6))) ^ next_key(key_6, 4'd7);
            valid_7 <= valid_6;

            // Stage 8: round 8
            key_8 <= next_key(key_7, 4'd8);
            state_8 <= MixColumns(ShiftRows(SubBytes(state_7))) ^ next_key(key_7, 4'd8);
            valid_8 <= valid_7;

            // Stage 9: round 9
            key_9 <= next_key(key_8, 4'd9);
            state_9 <= MixColumns(ShiftRows(SubBytes(state_8))) ^ next_key(key_8, 4'd9);
            valid_9 <= valid_8;

            // Stage 10: final round (no MixColumns)
            if (valid_9) begin
                Cypher_text <= ShiftRows(SubBytes(state_9)) ^ next_key(key_9, 4'd10);
            end
        end
    end

endmodule
