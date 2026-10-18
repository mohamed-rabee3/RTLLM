library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity AES_Encrypt is
    Port (
        clk         : in  std_logic;
        rst         : in  std_logic;
        Plain_text  : in  std_logic_vector(127 downto 0);
        EN          : in  std_logic;
        Key_in      : in  std_logic_vector(127 downto 0);
        Cypher_text : out std_logic_vector(127 downto 0)
    );
end AES_Encrypt;

architecture RTL of AES_Encrypt is

    type byte_array  is array (0 to 15) of std_logic_vector(7 downto 0);
    type state_array is array (0 to 10) of std_logic_vector(127 downto 0);
    type key_array   is array (1 to 10) of std_logic_vector(127 downto 0);
    type rcon_array  is array (1 to 10) of std_logic_vector(7 downto 0);
    type sbox_array  is array (0 to 255) of std_logic_vector(7 downto 0);

    constant SBOX : sbox_array := (
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
        1  => x"01",
        2  => x"02",
        3  => x"04",
        4  => x"08",
        5  => x"10",
        6  => x"20",
        7  => x"40",
        8  => x"80",
        9  => x"1B",
        10 => x"36"
    );

    signal state_reg : state_array;
    signal key_reg   : key_array;

    function slv_to_bytes(s : std_logic_vector(127 downto 0)) return byte_array is
        variable b : byte_array;
    begin
        for i in 0 to 15 loop
            b(i) := s(127 - 8*i downto 120 - 8*i);
        end loop;
        return b;
    end function;

    function bytes_to_slv(b : byte_array) return std_logic_vector is
        variable s : std_logic_vector(127 downto 0);
    begin
        for i in 0 to 15 loop
            s(127 - 8*i downto 120 - 8*i) := b(i);
        end loop;
        return s;
    end function;

    function xtime(b : std_logic_vector(7 downto 0)) return std_logic_vector is
        variable res : std_logic_vector(7 downto 0);
    begin
        res := b(6 downto 0) & '0';
        if b(7) = '1' then
            res := res xor x"1B";
        end if;
        return res;
    end function;

    function sub_bytes(b : byte_array) return byte_array is
        variable r : byte_array;
    begin
        for i in 0 to 15 loop
            r(i) := SBOX(to_integer(unsigned(b(i))));
        end loop;
        return r;
    end function;

    function shift_rows(b : byte_array) return byte_array is
        variable r : byte_array;
    begin
        for c in 0 to 3 loop
            r(4*c+0) := b(4*c+0);
            r(4*c+1) := b(4*((c+1) mod 4)+1);
            r(4*c+2) := b(4*((c+2) mod 4)+2);
            r(4*c+3) := b(4*((c+3) mod 4)+3);
        end loop;
        return r;
    end function;

    function mix_columns(b : byte_array) return byte_array is
        variable r                 : byte_array;
        variable b0, b1, b2, b3    : std_logic_vector(7 downto 0);
        variable t0, t1, t2, t3    : std_logic_vector(7 downto 0);
    begin
        for c in 0 to 3 loop
            b0 := b(4*c+0);
            b1 := b(4*c+1);
            b2 := b(4*c+2);
            b3 := b(4*c+3);
            t0 := xtime(b0) xor xtime(b1) xor b1 xor b2 xor b3;
            t1 := b0 xor xtime(b1) xor xtime(b2) xor b2 xor b3;
            t2 := b0 xor b1 xor xtime(b2) xor xtime(b3) xor b3;
            t3 := xtime(b0) xor b0 xor b1 xor b2 xor xtime(b3);
            r(4*c+0) := t0;
            r(4*c+1) := t1;
            r(4*c+2) := t2;
            r(4*c+3) := t3;
        end loop;
        return r;
    end function;

    function round_transform(state : std_logic_vector(127 downto 0);
                             key   : std_logic_vector(127 downto 0)) return std_logic_vector is
        variable b : byte_array;
    begin
        b := slv_to_bytes(state);
        b := sub_bytes(b);
        b := shift_rows(b);
        b := mix_columns(b);
        return bytes_to_slv(b) xor key;
    end function;

    function final_transform(state : std_logic_vector(127 downto 0);
                             key   : std_logic_vector(127 downto 0)) return std_logic_vector is
        variable b : byte_array;
    begin
        b := slv_to_bytes(state);
        b := sub_bytes(b);
        b := shift_rows(b);
        return bytes_to_slv(b) xor key;
    end function;

    function next_round_key(key  : std_logic_vector(127 downto 0);
                            rcon : std_logic_vector(7 downto 0)) return std_logic_vector is
        variable k              : byte_array;
        variable nk             : byte_array;
        variable t0, t1, t2, t3 : std_logic_vector(7 downto 0);
    begin
        k := slv_to_bytes(key);

        t0 := SBOX(to_integer(unsigned(k(13))));
        t1 := SBOX(to_integer(unsigned(k(14))));
        t2 := SBOX(to_integer(unsigned(k(15))));
        t3 := SBOX(to_integer(unsigned(k(12))));
        t0 := t0 xor rcon;

        nk(0)  := k(0)  xor t0;
        nk(1)  := k(1)  xor t1;
        nk(2)  := k(2)  xor t2;
        nk(3)  := k(3)  xor t3;

        nk(4)  := k(4)  xor nk(0);
        nk(5)  := k(5)  xor nk(1);
        nk(6)  := k(6)  xor nk(2);
        nk(7)  := k(7)  xor nk(3);

        nk(8)  := k(8)  xor nk(4);
        nk(9)  := k(9)  xor nk(5);
        nk(10) := k(10) xor nk(6);
        nk(11) := k(11) xor nk(7);

        nk(12) := k(12) xor nk(8);
        nk(13) := k(13) xor nk(9);
        nk(14) := k(14) xor nk(10);
        nk(15) := k(15) xor nk(11);

        return bytes_to_slv(nk);
    end function;

begin

    Cypher_text <= state_reg(10);

    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                state_reg <= (others => (others => '0'));
                key_reg   <= (others => (others => '0'));
            else
                for i in 1 to 9 loop
                    state_reg(i) <= round_transform(state_reg(i-1), key_reg(i));
                    key_reg(i+1) <= next_round_key(key_reg(i), RCON(i+1));
                end loop;
                state_reg(10) <= final_transform(state_reg(9), key_reg(10));

                if EN = '1' then
                    state_reg(0) <= Plain_text xor Key_in;
                    key_reg(1)   <= next_round_key(Key_in, RCON(1));
                else
                    state_reg(0) <= (others => '0');
                    key_reg(1)   <= (others => '0');
                end if;
            end if;
        end if;
    end process;

end RTL;
