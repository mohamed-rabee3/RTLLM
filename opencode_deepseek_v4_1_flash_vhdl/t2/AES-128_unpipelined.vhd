library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity AES_Encrypt is
    Port (
        clk         : in  STD_LOGIC;
        rst         : in  STD_LOGIC;
        Plain_text  : in  STD_LOGIC_VECTOR (127 downto 0);
        EN          : in  STD_LOGIC;
        Key_in      : in  STD_LOGIC_VECTOR (127 downto 0);
        Cypher_text : out STD_LOGIC_VECTOR (127 downto 0)
    );
end AES_Encrypt;

architecture Behavioral of AES_Encrypt is

    subtype byte is std_logic_vector(7 downto 0);
    subtype word is std_logic_vector(31 downto 0);

    type byte_array is array (0 to 15) of byte;
    type word_array is array (0 to 43) of word;
    type sbox_array is array (0 to 255) of byte;
    type rcon_array is array (0 to 10) of byte;

    constant SBOX_TABLE : sbox_array := (
        x"63", x"7c", x"77", x"7b", x"f2", x"6b", x"6f", x"c5", x"30", x"01", x"67", x"2b", x"fe", x"d7", x"ab", x"76",
        x"ca", x"82", x"c9", x"7d", x"fa", x"59", x"47", x"f0", x"ad", x"d4", x"a2", x"af", x"9c", x"a4", x"72", x"c0",
        x"b7", x"fd", x"93", x"26", x"36", x"3f", x"f7", x"cc", x"34", x"a5", x"e5", x"f1", x"71", x"d8", x"31", x"15",
        x"04", x"c7", x"23", x"c3", x"18", x"96", x"05", x"9a", x"07", x"12", x"80", x"e2", x"eb", x"27", x"b2", x"75",
        x"09", x"83", x"2c", x"1a", x"1b", x"6e", x"5a", x"a0", x"52", x"3b", x"d6", x"b3", x"29", x"e3", x"2f", x"84",
        x"53", x"d1", x"00", x"ed", x"20", x"fc", x"b1", x"5b", x"6a", x"cb", x"be", x"39", x"4a", x"4c", x"58", x"cf",
        x"d0", x"ef", x"aa", x"fb", x"43", x"4d", x"33", x"85", x"45", x"f9", x"02", x"7f", x"50", x"3c", x"9f", x"a8",
        x"51", x"a3", x"40", x"8f", x"92", x"9d", x"38", x"f5", x"bc", x"b6", x"da", x"21", x"10", x"ff", x"f3", x"d2",
        x"cd", x"0c", x"13", x"ec", x"5f", x"97", x"44", x"17", x"c4", x"a7", x"7e", x"3d", x"64", x"5d", x"19", x"73",
        x"60", x"81", x"4f", x"dc", x"22", x"2a", x"90", x"88", x"46", x"ee", x"b8", x"14", x"de", x"5e", x"0b", x"db",
        x"e0", x"32", x"3a", x"0a", x"49", x"06", x"24", x"5c", x"c2", x"d3", x"ac", x"62", x"91", x"95", x"e4", x"79",
        x"e7", x"c8", x"37", x"6d", x"8d", x"d5", x"4e", x"a9", x"6c", x"56", x"f4", x"ea", x"65", x"7a", x"ae", x"08",
        x"ba", x"78", x"25", x"2e", x"1c", x"a6", x"b4", x"c6", x"e8", x"dd", x"74", x"1f", x"4b", x"bd", x"8b", x"8a",
        x"70", x"3e", x"b5", x"66", x"48", x"03", x"f6", x"0e", x"61", x"35", x"57", x"b9", x"86", x"c1", x"1d", x"9e",
        x"e1", x"f8", x"98", x"11", x"69", x"d9", x"8e", x"94", x"9b", x"1e", x"87", x"e9", x"ce", x"55", x"28", x"df",
        x"8c", x"a1", x"89", x"0d", x"bf", x"e6", x"42", x"68", x"41", x"99", x"2d", x"0f", x"b0", x"54", x"bb", x"16"
    );

    constant RCON : rcon_array := (
        x"00", x"01", x"02", x"04", x"08", x"10", x"20", x"40", x"80", x"1b", x"36"
    );

    signal reg_out    : std_logic_vector(127 downto 0);
    signal aes_result : std_logic_vector(127 downto 0);

    function get_byte(v : std_logic_vector(127 downto 0); idx : integer) return byte is
        variable b : byte;
    begin
        for j in 0 to 7 loop
            b(7 - j) := v(127 - (idx * 8 + j));
        end loop;
        return b;
    end function;

    function sbox_byte(b : byte) return byte is
    begin
        return SBOX_TABLE(to_integer(unsigned(b)));
    end function;

    function xtime(b : byte) return byte is
        variable shifted : byte;
    begin
        shifted := b(6 downto 0) & '0';
        if b(7) = '1' then
            return shifted xor x"1B";
        else
            return shifted;
        end if;
    end function;

    function mul2(b : byte) return byte is
    begin
        return xtime(b);
    end function;

    function mul3(b : byte) return byte is
    begin
        return xtime(b) xor b;
    end function;

    function rot_word(w : word) return word is
    begin
        return w(23 downto 16) & w(15 downto 8) & w(7 downto 0) & w(31 downto 24);
    end function;

    function sub_word(w : word) return word is
    begin
        return sbox_byte(w(31 downto 24)) &
               sbox_byte(w(23 downto 16)) &
               sbox_byte(w(15 downto 8))  &
               sbox_byte(w(7 downto 0));
    end function;

    function add_round_key(s : byte_array; w : word_array; round : integer) return byte_array is
        variable res      : byte_array;
        variable word_val : word;
    begin
        for c in 0 to 3 loop
            word_val := w(round * 4 + c);
            res(0 + 4*c) := s(0 + 4*c) xor word_val(31 downto 24);
            res(1 + 4*c) := s(1 + 4*c) xor word_val(23 downto 16);
            res(2 + 4*c) := s(2 + 4*c) xor word_val(15 downto 8);
            res(3 + 4*c) := s(3 + 4*c) xor word_val(7 downto 0);
        end loop;
        return res;
    end function;

    function sub_bytes(s : byte_array) return byte_array is
        variable res : byte_array;
    begin
        for i in 0 to 15 loop
            res(i) := sbox_byte(s(i));
        end loop;
        return res;
    end function;

    function shift_rows(s : byte_array) return byte_array is
        variable res     : byte_array;
        variable col_src : integer;
    begin
        for r in 0 to 3 loop
            for c in 0 to 3 loop
                col_src := (c + r) mod 4;
                res(r + 4*c) := s(r + 4*col_src);
            end loop;
        end loop;
        return res;
    end function;

    function mix_columns(s : byte_array) return byte_array is
        variable res : byte_array;
        variable a0, a1, a2, a3 : byte;
    begin
        for c in 0 to 3 loop
            a0 := s(0 + 4*c);
            a1 := s(1 + 4*c);
            a2 := s(2 + 4*c);
            a3 := s(3 + 4*c);

            res(0 + 4*c) := mul2(a0) xor mul3(a1) xor a2 xor a3;
            res(1 + 4*c) := a0 xor mul2(a1) xor mul3(a2) xor a3;
            res(2 + 4*c) := a0 xor a1 xor mul2(a2) xor mul3(a3);
            res(3 + 4*c) := mul3(a0) xor a1 xor a2 xor mul2(a3);
        end loop;
        return res;
    end function;

    function aes_encrypt(plain, key : std_logic_vector(127 downto 0)) return std_logic_vector is
        variable state     : byte_array;
        variable w         : word_array;
        variable temp      : word;
        variable key_bytes : byte_array;
        variable out_vec   : std_logic_vector(127 downto 0);
    begin
        for i in 0 to 15 loop
            key_bytes(i) := get_byte(key, i);
            state(i)     := get_byte(plain, i);
        end loop;

        for i in 0 to 3 loop
            w(i) := key_bytes(4*i) & key_bytes(4*i + 1) & key_bytes(4*i + 2) & key_bytes(4*i + 3);
        end loop;

        for i in 4 to 43 loop
            temp := w(i - 1);
            if (i mod 4) = 0 then
                temp := sub_word(rot_word(temp)) xor (RCON(i / 4) & x"000000");
            end if;
            w(i) := w(i - 4) xor temp;
        end loop;

        state := add_round_key(state, w, 0);

        for r in 1 to 9 loop
            state := sub_bytes(state);
            state := shift_rows(state);
            state := mix_columns(state);
            state := add_round_key(state, w, r);
        end loop;

        state := sub_bytes(state);
        state := shift_rows(state);
        state := add_round_key(state, w, 10);

        for i in 0 to 15 loop
            for j in 0 to 7 loop
                out_vec(127 - (i * 8 + j)) := state(i)(7 - j);
            end loop;
        end loop;

        return out_vec;
    end function;

begin

    aes_result <= aes_encrypt(Plain_text, Key_in);

    process(clk, rst)
    begin
        if rst = '1' then
            reg_out <= (others => '0');
        elsif rising_edge(clk) then
            if EN = '1' then
                reg_out <= aes_result;
            end if;
        end if;
    end process;

    Cypher_text <= (others => '0') when rst = '1' else
                   aes_result       when EN  = '1' else
                   reg_out;

end Behavioral;
