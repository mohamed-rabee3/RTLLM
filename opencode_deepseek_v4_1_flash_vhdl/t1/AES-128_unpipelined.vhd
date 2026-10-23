library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity AES_Encrypt is
    Port (
        clk : in STD_LOGIC;
        rst : in STD_LOGIC;
        Plain_text : in STD_LOGIC_VECTOR (127 downto 0);
        EN : in STD_LOGIC;
        Key_in : in STD_LOGIC_VECTOR (127 downto 0);
        Cypher_text : out STD_LOGIC_VECTOR (127 downto 0)
    );
end AES_Encrypt;

architecture Behavioral of AES_Encrypt is

    subtype byte_t is std_logic_vector(7 downto 0);
    type byte_array_t is array (0 to 15) of byte_t;
    type sbox_array_t is array (0 to 255) of byte_t;
    type word_array_t is array (0 to 43) of std_logic_vector(31 downto 0);
    type roundkey_array_t is array (0 to 10) of std_logic_vector(127 downto 0);
    type rcon_array_t is array (1 to 10) of byte_t;

    constant SBOX : sbox_array_t := (
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

    constant RCON : rcon_array_t := (
        x"01", x"02", x"04", x"08", x"10", x"20", x"40", x"80", x"1b", x"36"
    );

    function xtime(b : byte_t) return byte_t is
        variable r : byte_t;
    begin
        if b(7) = '1' then
            r := (b(6 downto 0) & '0') xor x"1b";
        else
            r := b(6 downto 0) & '0';
        end if;
        return r;
    end function;

    function sub_word(w : std_logic_vector(31 downto 0)) return std_logic_vector is
        variable b0, b1, b2, b3 : byte_t;
    begin
        b0 := SBOX(to_integer(unsigned(w(31 downto 24))));
        b1 := SBOX(to_integer(unsigned(w(23 downto 16))));
        b2 := SBOX(to_integer(unsigned(w(15 downto 8))));
        b3 := SBOX(to_integer(unsigned(w(7 downto 0))));
        return b0 & b1 & b2 & b3;
    end function;

    function rot_word(w : std_logic_vector(31 downto 0)) return std_logic_vector is
    begin
        return w(23 downto 0) & w(31 downto 24);
    end function;

    function key_expansion(key : std_logic_vector(127 downto 0)) return roundkey_array_t is
        variable w : word_array_t;
        variable temp : std_logic_vector(31 downto 0);
        variable rk : roundkey_array_t;
    begin
        for i in 0 to 3 loop
            w(i) := key(127 - i*32 downto 96 - i*32);
        end loop;

        for i in 4 to 43 loop
            temp := w(i-1);
            if (i mod 4) = 0 then
                temp := sub_word(rot_word(temp));
                temp(31 downto 24) := temp(31 downto 24) xor RCON(i/4);
            end if;
            w(i) := w(i-4) xor temp;
        end loop;

        for r in 0 to 10 loop
            rk(r) := w(4*r) & w(4*r+1) & w(4*r+2) & w(4*r+3);
        end loop;

        return rk;
    end function;

    function add_round_key(state : byte_array_t; rk : std_logic_vector(127 downto 0)) return byte_array_t is
        variable s : byte_array_t;
    begin
        for i in 0 to 15 loop
            s(i) := state(i) xor rk(127 - i*8 downto 120 - i*8);
        end loop;
        return s;
    end function;

    function sub_bytes(state : byte_array_t) return byte_array_t is
        variable s : byte_array_t;
    begin
        for i in 0 to 15 loop
            s(i) := SBOX(to_integer(unsigned(state(i))));
        end loop;
        return s;
    end function;

    function shift_rows(state : byte_array_t) return byte_array_t is
        variable s : byte_array_t;
    begin
        s(0)  := state(0);
        s(1)  := state(5);
        s(2)  := state(10);
        s(3)  := state(15);
        s(4)  := state(4);
        s(5)  := state(9);
        s(6)  := state(14);
        s(7)  := state(3);
        s(8)  := state(8);
        s(9)  := state(13);
        s(10) := state(2);
        s(11) := state(7);
        s(12) := state(12);
        s(13) := state(1);
        s(14) := state(6);
        s(15) := state(11);
        return s;
    end function;

    function mix_columns(state : byte_array_t) return byte_array_t is
        variable s : byte_array_t;
        variable a0, a1, a2, a3 : byte_t;
    begin
        for c in 0 to 3 loop
            a0 := state(4*c);
            a1 := state(4*c + 1);
            a2 := state(4*c + 2);
            a3 := state(4*c + 3);

            s(4*c)     := xtime(a0) xor xtime(a1) xor a1 xor a2 xor a3;
            s(4*c + 1) := a0 xor xtime(a1) xor xtime(a2) xor a2 xor a3;
            s(4*c + 2) := a0 xor a1 xor xtime(a2) xor xtime(a3) xor a3;
            s(4*c + 3) := xtime(a0) xor a0 xor a1 xor a2 xor xtime(a3);
        end loop;
        return s;
    end function;

    function bytes_to_vec(b : byte_array_t) return std_logic_vector is
        variable v : std_logic_vector(127 downto 0);
    begin
        for i in 0 to 15 loop
            v(127 - i*8 downto 120 - i*8) := b(i);
        end loop;
        return v;
    end function;

    function aes_encrypt(pt : std_logic_vector(127 downto 0);
                         key : std_logic_vector(127 downto 0)) return std_logic_vector is
        variable state : byte_array_t;
        variable rk : roundkey_array_t;
    begin
        for i in 0 to 15 loop
            state(i) := pt(127 - i*8 downto 120 - i*8);
        end loop;

        rk := key_expansion(key);
        state := add_round_key(state, rk(0));

        for rnd in 1 to 9 loop
            state := sub_bytes(state);
            state := shift_rows(state);
            state := mix_columns(state);
            state := add_round_key(state, rk(rnd));
        end loop;

        state := sub_bytes(state);
        state := shift_rows(state);
        state := add_round_key(state, rk(10));

        return bytes_to_vec(state);
    end function;

    signal cipher_reg : std_logic_vector(127 downto 0);

begin

    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                cipher_reg <= (others => '0');
            elsif EN = '1' then
                cipher_reg <= aes_encrypt(Plain_text, Key_in);
            end if;
        end if;
    end process;

    Cypher_text <= cipher_reg;

end Behavioral;
