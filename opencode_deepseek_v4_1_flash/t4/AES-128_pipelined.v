module AES_Encrypt(
    input clk,
    input rst,
    input [127:0] Plain_text,
    input EN,
    input [127:0] Key_in,
    output [127:0] Cypher_text
);

    function [7:0] Sbox;
        input [7:0] x;
        begin
            case (x)
                8'h00: Sbox = 8'h63; 8'h01: Sbox = 8'h7c; 8'h02: Sbox = 8'h77; 8'h03: Sbox = 8'h7b;
                8'h04: Sbox = 8'hf2; 8'h05: Sbox = 8'h6b; 8'h06: Sbox = 8'h6f; 8'h07: Sbox = 8'hc5;
                8'h08: Sbox = 8'h30; 8'h09: Sbox = 8'h01; 8'h0a: Sbox = 8'h67; 8'h0b: Sbox = 8'h2b;
                8'h0c: Sbox = 8'hfe; 8'h0d: Sbox = 8'hd7; 8'h0e: Sbox = 8'hab; 8'h0f: Sbox = 8'h76;
                8'h10: Sbox = 8'hca; 8'h11: Sbox = 8'h82; 8'h12: Sbox = 8'hc9; 8'h13: Sbox = 8'h7d;
                8'h14: Sbox = 8'hfa; 8'h15: Sbox = 8'h59; 8'h16: Sbox = 8'h47; 8'h17: Sbox = 8'hf0;
                8'h18: Sbox = 8'had; 8'h19: Sbox = 8'hd4; 8'h1a: Sbox = 8'ha2; 8'h1b: Sbox = 8'haf;
                8'h1c: Sbox = 8'h9c; 8'h1d: Sbox = 8'ha4; 8'h1e: Sbox = 8'h72; 8'h1f: Sbox = 8'hc0;
                8'h20: Sbox = 8'hb7; 8'h21: Sbox = 8'hfd; 8'h22: Sbox = 8'h93; 8'h23: Sbox = 8'h26;
                8'h24: Sbox = 8'h36; 8'h25: Sbox = 8'h3f; 8'h26: Sbox = 8'hf7; 8'h27: Sbox = 8'hcc;
                8'h28: Sbox = 8'h34; 8'h29: Sbox = 8'ha5; 8'h2a: Sbox = 8'he5; 8'h2b: Sbox = 8'hf1;
                8'h2c: Sbox = 8'h71; 8'h2d: Sbox = 8'hd8; 8'h2e: Sbox = 8'h31; 8'h2f: Sbox = 8'h15;
                8'h30: Sbox = 8'h04; 8'h31: Sbox = 8'hc7; 8'h32: Sbox = 8'h23; 8'h33: Sbox = 8'hc3;
                8'h34: Sbox = 8'h18; 8'h35: Sbox = 8'h96; 8'h36: Sbox = 8'h05; 8'h37: Sbox = 8'h9a;
                8'h38: Sbox = 8'h07; 8'h39: Sbox = 8'h12; 8'h3a: Sbox = 8'h80; 8'h3b: Sbox = 8'he2;
                8'h3c: Sbox = 8'heb; 8'h3d: Sbox = 8'h27; 8'h3e: Sbox = 8'hb2; 8'h3f: Sbox = 8'h75;
                8'h40: Sbox = 8'h09; 8'h41: Sbox = 8'h83; 8'h42: Sbox = 8'h2c; 8'h43: Sbox = 8'h1a;
                8'h44: Sbox = 8'h1b; 8'h45: Sbox = 8'h6e; 8'h46: Sbox = 8'h5a; 8'h47: Sbox = 8'ha0;
                8'h48: Sbox = 8'h52; 8'h49: Sbox = 8'h3b; 8'h4a: Sbox = 8'hd6; 8'h4b: Sbox = 8'hb3;
                8'h4c: Sbox = 8'h29; 8'h4d: Sbox = 8'he3; 8'h4e: Sbox = 8'h2f; 8'h4f: Sbox = 8'h84;
                8'h50: Sbox = 8'h53; 8'h51: Sbox = 8'hd1; 8'h52: Sbox = 8'h00; 8'h53: Sbox = 8'hed;
                8'h54: Sbox = 8'h20; 8'h55: Sbox = 8'hfc; 8'h56: Sbox = 8'hb1; 8'h57: Sbox = 8'h5b;
                8'h58: Sbox = 8'h6a; 8'h59: Sbox = 8'hcb; 8'h5a: Sbox = 8'hbe; 8'h5b: Sbox = 8'h39;
                8'h5c: Sbox = 8'h4a; 8'h5d: Sbox = 8'h4c; 8'h5e: Sbox = 8'h58; 8'h5f: Sbox = 8'hcf;
                8'h60: Sbox = 8'hd0; 8'h61: Sbox = 8'hef; 8'h62: Sbox = 8'haa; 8'h63: Sbox = 8'hfb;
                8'h64: Sbox = 8'h43; 8'h65: Sbox = 8'h4d; 8'h66: Sbox = 8'h33; 8'h67: Sbox = 8'h85;
                8'h68: Sbox = 8'h45; 8'h69: Sbox = 8'hf9; 8'h6a: Sbox = 8'h02; 8'h6b: Sbox = 8'h7f;
                8'h6c: Sbox = 8'h50; 8'h6d: Sbox = 8'h3c; 8'h6e: Sbox = 8'h9f; 8'h6f: Sbox = 8'ha8;
                8'h70: Sbox = 8'h51; 8'h71: Sbox = 8'ha3; 8'h72: Sbox = 8'h40; 8'h73: Sbox = 8'h8f;
                8'h74: Sbox = 8'h92; 8'h75: Sbox = 8'h9d; 8'h76: Sbox = 8'h38; 8'h77: Sbox = 8'hf5;
                8'h78: Sbox = 8'hbc; 8'h79: Sbox = 8'hb6; 8'h7a: Sbox = 8'hda; 8'h7b: Sbox = 8'h21;
                8'h7c: Sbox = 8'h10; 8'h7d: Sbox = 8'hff; 8'h7e: Sbox = 8'hf3; 8'h7f: Sbox = 8'hd2;
                8'h80: Sbox = 8'hcd; 8'h81: Sbox = 8'h0c; 8'h82: Sbox = 8'h13; 8'h83: Sbox = 8'hec;
                8'h84: Sbox = 8'h5f; 8'h85: Sbox = 8'h97; 8'h86: Sbox = 8'h44; 8'h87: Sbox = 8'h17;
                8'h88: Sbox = 8'hc4; 8'h89: Sbox = 8'ha7; 8'h8a: Sbox = 8'h7e; 8'h8b: Sbox = 8'h3d;
                8'h8c: Sbox = 8'h64; 8'h8d: Sbox = 8'h5d; 8'h8e: Sbox = 8'h19; 8'h8f: Sbox = 8'h73;
                8'h90: Sbox = 8'h60; 8'h91: Sbox = 8'h81; 8'h92: Sbox = 8'h4f; 8'h93: Sbox = 8'hdc;
                8'h94: Sbox = 8'h22; 8'h95: Sbox = 8'h2a; 8'h96: Sbox = 8'h90; 8'h97: Sbox = 8'h88;
                8'h98: Sbox = 8'h46; 8'h99: Sbox = 8'hee; 8'h9a: Sbox = 8'hb8; 8'h9b: Sbox = 8'h14;
                8'h9c: Sbox = 8'hde; 8'h9d: Sbox = 8'h5e; 8'h9e: Sbox = 8'h0b; 8'h9f: Sbox = 8'hdb;
                8'ha0: Sbox = 8'he0; 8'ha1: Sbox = 8'h32; 8'ha2: Sbox = 8'h3a; 8'ha3: Sbox = 8'h0a;
                8'ha4: Sbox = 8'h49; 8'ha5: Sbox = 8'h06; 8'ha6: Sbox = 8'h24; 8'ha7: Sbox = 8'h5c;
                8'ha8: Sbox = 8'hc2; 8'ha9: Sbox = 8'hd3; 8'haa: Sbox = 8'hac; 8'hab: Sbox = 8'h62;
                8'hac: Sbox = 8'h91; 8'had: Sbox = 8'h95; 8'hae: Sbox = 8'he4; 8'haf: Sbox = 8'h79;
                8'hb0: Sbox = 8'he7; 8'hb1: Sbox = 8'hc8; 8'hb2: Sbox = 8'h37; 8'hb3: Sbox = 8'h6d;
                8'hb4: Sbox = 8'h8d; 8'hb5: Sbox = 8'hd5; 8'hb6: Sbox = 8'h4e; 8'hb7: Sbox = 8'ha9;
                8'hb8: Sbox = 8'h6c; 8'hb9: Sbox = 8'h56; 8'hba: Sbox = 8'hf4; 8'hbb: Sbox = 8'hea;
                8'hbc: Sbox = 8'h65; 8'hbd: Sbox = 8'h7a; 8'hbe: Sbox = 8'hae; 8'hbf: Sbox = 8'h08;
                8'hc0: Sbox = 8'hba; 8'hc1: Sbox = 8'h78; 8'hc2: Sbox = 8'h25; 8'hc3: Sbox = 8'h2e;
                8'hc4: Sbox = 8'h1c; 8'hc5: Sbox = 8'ha6; 8'hc6: Sbox = 8'hb4; 8'hc7: Sbox = 8'hc6;
                8'hc8: Sbox = 8'he8; 8'hc9: Sbox = 8'hdd; 8'hca: Sbox = 8'h74; 8'hcb: Sbox = 8'h1f;
                8'hcc: Sbox = 8'h4b; 8'hcd: Sbox = 8'hbd; 8'hce: Sbox = 8'h8b; 8'hcf: Sbox = 8'h8a;
                8'hd0: Sbox = 8'h70; 8'hd1: Sbox = 8'h3e; 8'hd2: Sbox = 8'hb5; 8'hd3: Sbox = 8'h66;
                8'hd4: Sbox = 8'h48; 8'hd5: Sbox = 8'h03; 8'hd6: Sbox = 8'hf6; 8'hd7: Sbox = 8'h0e;
                8'hd8: Sbox = 8'h61; 8'hd9: Sbox = 8'h35; 8'hda: Sbox = 8'h57; 8'hdb: Sbox = 8'hb9;
                8'hdc: Sbox = 8'h86; 8'hdd: Sbox = 8'hc1; 8'hde: Sbox = 8'h1d; 8'hdf: Sbox = 8'h9e;
                8'he0: Sbox = 8'he1; 8'he1: Sbox = 8'hf8; 8'he2: Sbox = 8'h98; 8'he3: Sbox = 8'h11;
                8'he4: Sbox = 8'h69; 8'he5: Sbox = 8'hd9; 8'he6: Sbox = 8'h8e; 8'he7: Sbox = 8'h94;
                8'he8: Sbox = 8'h9b; 8'he9: Sbox = 8'h1e; 8'hea: Sbox = 8'h87; 8'heb: Sbox = 8'he9;
                8'hec: Sbox = 8'hce; 8'hed: Sbox = 8'h55; 8'hee: Sbox = 8'h28; 8'hef: Sbox = 8'hdf;
                8'hf0: Sbox = 8'h8c; 8'hf1: Sbox = 8'ha1; 8'hf2: Sbox = 8'h89; 8'hf3: Sbox = 8'h0d;
                8'hf4: Sbox = 8'hbf; 8'hf5: Sbox = 8'he6; 8'hf6: Sbox = 8'h42; 8'hf7: Sbox = 8'h68;
                8'hf8: Sbox = 8'h41; 8'hf9: Sbox = 8'h99; 8'hfa: Sbox = 8'h2d; 8'hfb: Sbox = 8'h0f;
                8'hfc: Sbox = 8'hb0; 8'hfd: Sbox = 8'h54; 8'hfe: Sbox = 8'hbb; 8'hff: Sbox = 8'h16;
                default: Sbox = 8'h00;
            endcase
        end
    endfunction

    function [31:0] SubWord;
        input [31:0] x;
        begin
            SubWord = {Sbox(x[31:24]), Sbox(x[23:16]), Sbox(x[15:8]), Sbox(x[7:0])};
        end
    endfunction

    function [31:0] RotWord;
        input [31:0] x;
        begin
            RotWord = {x[23:0], x[31:24]};
        end
    endfunction

    function [31:0] Rcon;
        input [3:0] idx;
        begin
            case (idx)
                4'd1:  Rcon = 32'h01000000;
                4'd2:  Rcon = 32'h02000000;
                4'd3:  Rcon = 32'h04000000;
                4'd4:  Rcon = 32'h08000000;
                4'd5:  Rcon = 32'h10000000;
                4'd6:  Rcon = 32'h20000000;
                4'd7:  Rcon = 32'h40000000;
                4'd8:  Rcon = 32'h80000000;
                4'd9:  Rcon = 32'h1b000000;
                4'd10: Rcon = 32'h36000000;
                default: Rcon = 32'h00000000;
            endcase
        end
    endfunction

    function [127:0] SubBytes;
        input [127:0] s;
        begin
            SubBytes = {
                Sbox(s[127:120]), Sbox(s[119:112]), Sbox(s[111:104]), Sbox(s[103:96]),
                Sbox(s[95:88]),   Sbox(s[87:80]),   Sbox(s[79:72]),   Sbox(s[71:64]),
                Sbox(s[63:56]),   Sbox(s[55:48]),   Sbox(s[47:40]),   Sbox(s[39:32]),
                Sbox(s[31:24]),   Sbox(s[23:16]),   Sbox(s[15:8]),    Sbox(s[7:0])
            };
        end
    endfunction

    function [127:0] ShiftRows;
        input [127:0] s;
        begin
            ShiftRows = {
                s[127:120], s[87:80],  s[47:40], s[7:0],
                s[95:88],   s[55:48],  s[15:8],  s[103:96],
                s[63:56],   s[23:16],  s[111:104], s[71:64],
                s[31:24],   s[119:112], s[79:72], s[39:32]
            };
        end
    endfunction

    function [7:0] xtime;
        input [7:0] x;
        begin
            xtime = {x[6:0], 1'b0} ^ (x[7] ? 8'h1b : 8'h00);
        end
    endfunction

    function [31:0] MixColumn;
        input [31:0] col;
        reg [7:0] a0, a1, a2, a3;
        reg [7:0] b0, b1, b2, b3;
        begin
            a0 = col[31:24];
            a1 = col[23:16];
            a2 = col[15:8];
            a3 = col[7:0];

            b0 = xtime(a0) ^ (xtime(a1) ^ a1) ^ a2 ^ a3;
            b1 = a0 ^ xtime(a1) ^ (xtime(a2) ^ a2) ^ a3;
            b2 = a0 ^ a1 ^ xtime(a2) ^ (xtime(a3) ^ a3);
            b3 = (xtime(a0) ^ a0) ^ a1 ^ a2 ^ xtime(a3);

            MixColumn = {b0, b1, b2, b3};
        end
    endfunction

    function [127:0] MixColumns;
        input [127:0] s;
        begin
            MixColumns = {
                MixColumn(s[127:96]),
                MixColumn(s[95:64]),
                MixColumn(s[63:32]),
                MixColumn(s[31:0])
            };
        end
    endfunction

    function [127:0] full_round;
        input [127:0] state;
        input [127:0] rkey;
        begin
            full_round = MixColumns(ShiftRows(SubBytes(state))) ^ rkey;
        end
    endfunction

    function [127:0] final_round;
        input [127:0] state;
        input [127:0] rkey;
        begin
            final_round = ShiftRows(SubBytes(state)) ^ rkey;
        end
    endfunction

    reg [31:0] w [0:43];
    reg [127:0] round_keys [0:10];
    integer i;
    reg [31:0] temp;

    always @* begin
        w[0] = Key_in[127:96];
        w[1] = Key_in[95:64];
        w[2] = Key_in[63:32];
        w[3] = Key_in[31:0];

        for (i = 4; i < 44; i = i + 1) begin
            temp = w[i-1];
            if ((i % 4) == 0) begin
                temp = SubWord(RotWord(temp)) ^ Rcon(i/4);
            end
            w[i] = w[i-4] ^ temp;
        end

        round_keys[0]  = {w[0],  w[1],  w[2],  w[3]};
        round_keys[1]  = {w[4],  w[5],  w[6],  w[7]};
        round_keys[2]  = {w[8],  w[9],  w[10], w[11]};
        round_keys[3]  = {w[12], w[13], w[14], w[15]};
        round_keys[4]  = {w[16], w[17], w[18], w[19]};
        round_keys[5]  = {w[20], w[21], w[22], w[23]};
        round_keys[6]  = {w[24], w[25], w[26], w[27]};
        round_keys[7]  = {w[28], w[29], w[30], w[31]};
        round_keys[8]  = {w[32], w[33], w[34], w[35]};
        round_keys[9]  = {w[36], w[37], w[38], w[39]};
        round_keys[10] = {w[40], w[41], w[42], w[43]};
    end

    reg [127:0] stage0, stage1, stage2, stage3, stage4, stage5;
    reg [127:0] stage6, stage7, stage8, stage9, stage10;
    reg [127:0] key1, key2, key3, key4, key5;
    reg [127:0] key6, key7, key8, key9, key10;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            stage0  <= 128'b0;
            stage1  <= 128'b0;
            stage2  <= 128'b0;
            stage3  <= 128'b0;
            stage4  <= 128'b0;
            stage5  <= 128'b0;
            stage6  <= 128'b0;
            stage7  <= 128'b0;
            stage8  <= 128'b0;
            stage9  <= 128'b0;
            stage10 <= 128'b0;

            key1  <= 128'b0;
            key2  <= 128'b0;
            key3  <= 128'b0;
            key4  <= 128'b0;
            key5  <= 128'b0;
            key6  <= 128'b0;
            key7  <= 128'b0;
            key8  <= 128'b0;
            key9  <= 128'b0;
            key10 <= 128'b0;
        end
        else if (EN) begin
            stage0 <= Plain_text ^ round_keys[0];

            key1  <= round_keys[1];
            key2  <= round_keys[2];
            key3  <= round_keys[3];
            key4  <= round_keys[4];
            key5  <= round_keys[5];
            key6  <= round_keys[6];
            key7  <= round_keys[7];
            key8  <= round_keys[8];
            key9  <= round_keys[9];
            key10 <= round_keys[10];

            stage1  <= full_round(stage0,  key1);
            stage2  <= full_round(stage1,  key2);
            stage3  <= full_round(stage2,  key3);
            stage4  <= full_round(stage3,  key4);
            stage5  <= full_round(stage4,  key5);
            stage6  <= full_round(stage5,  key6);
            stage7  <= full_round(stage6,  key7);
            stage8  <= full_round(stage7,  key8);
            stage9  <= full_round(stage8,  key9);
            stage10 <= final_round(stage9, key10);
        end
    end

    assign Cypher_text = stage10;

endmodule
