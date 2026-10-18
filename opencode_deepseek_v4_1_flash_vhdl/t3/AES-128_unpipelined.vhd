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

architecture rtl of AES_Encrypt is

    subtype byte_t is std_logic_vector(7 downto 0);
    type state_t is array (0 to 3, 0 to 3) of byte_t;
    type word_t is array (0 to 3) of byte_t;
    type word_array_t is array (0 to 43) of word_t;
    type round_keys_t is array (0 to 10, 0 to 3, 0 to 3) of byte_t;
    type sbox_t is array (0 to 255) of byte_t;

    constant S_BOX : sbox_t := (
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

    constant RCON : array (1 to 10) of byte_t := (
        x"01", x"02", x"04", x"08", x"10", x"20", x"40", x"80", x"1B", x"36"
    );

    function gf_mul2(x : byte_t) return byte_t is
        variable tmp : byte_t;
    begin
        if x(7) = '1' then
            tmp := (x(6 downto 0) & '0') xor x"1B";
        else
            tmp := x(6 downto 0) & '0';
        end if;
        return tmp;
    end function;

    function gf_mul3(x : byte_t) return byte_t is
    begin
        return gf_mul2(x) xor x;
    end function;

    function sbox(b : byte_t) return byte_t is
    begin
        return S_BOX(to_integer(unsigned(b)));
    end function;

    function sub_bytes(s : state_t) return state_t is
        variable res : state_t;
    begin
        for r in 0 to 3 loop
            for c in 0 to 3 loop
                res(r,c) := sbox(s(r,c));
            end loop;
        end loop;
        return res;
    end function;

    function shift_rows(s : state_t) return state_t is
        variable res : state_t;
    begin
        for c in 0 to 3 loop
            res(0,c) := s(0,c);
            res(1,c) := s(1,(c+1) mod 4);
            res(2,c) := s(2,(c+2) mod 4);
            res(3,c) := s(3,(c+3) mod 4);
        end loop;
        return res;
    end function;

    function mix_columns(s : state_t) return state_t is
        variable res : state_t;
        variable a0, a1, a2, a3 : byte_t;
    begin
        for c in 0 to 3 loop
            a0 := s(0,c);
            a1 := s(1,c);
            a2 := s(2,c);
            a3 := s(3,c);
            res(0,c) := gf_mul2(a0) xor gf_mul3(a1) xor a2 xor a3;
            res(1,c) := a0 xor gf_mul2(a1) xor gf_mul3(a2) xor a3;
            res(2,c) := a0 xor a1 xor gf_mul2(a2) xor gf_mul3(a3);
            res(3,c) := gf_mul3(a0) xor a1 xor a2 xor gf_mul2(a3);
        end loop;
        return res;
    end function;

    function add_round_key(s : state_t; rk : round_keys_t; rnd : integer) return state_t is
        variable res : state_t;
    begin
        for r in 0 to 3 loop
            for c in 0 to 3 loop
                res(r,c) := s(r,c) xor rk(rnd,r,c);
            end loop;
        end loop;
        return res;
    end function;

    function key_expansion(key : std_logic_vector(127 downto 0)) return round_keys_t is
        variable w : word_array_t;
        variable temp : word_t;
        variable tmp : word_t;
        variable rcon_val : byte_t;
        variable round_keys : round_keys_t;
    begin
        w(0)(0) := key(127 downto 120);
        w(0)(1) := key(119 downto 112);
        w(0)(2) := key(111 downto 104);
        w(0)(3) := key(103 downto 96);
        w(1)(0) := key(95 downto 88);
        w(1)(1) := key(87 downto 80);
        w(1)(2) := key(79 downto 72);
        w(1)(3) := key(71 downto 64);
        w(2)(0) := key(63 downto 56);
        w(2)(1) := key(55 downto 48);
        w(2)(2) := key(47 downto 40);
        w(2)(3) := key(39 downto 32);
        w(3)(0) := key(31 downto 24);
        w(3)(1) := key(23 downto 16);
        w(3)(2) := key(15 downto 8);
        w(3)(3) := key(7 downto 0);

        for i in 4 to 43 loop
            temp := w(i-1);
            if (i mod 4) = 0 then
                tmp(0) := temp(1);
                tmp(1) := temp(2);
                tmp(2) := temp(3);
                tmp(3) := temp(0);
                for j in 0 to 3 loop
                    tmp(j) := sbox(tmp(j));
                end loop;
                rcon_val := RCON(i/4);
                tmp(0) := tmp(0) xor rcon_val;
                temp := tmp;
            end if;
            for j in 0 to 3 loop
                w(i)(j) := w(i-4)(j) xor temp(j);
            end loop;
        end loop;

        for r in 0 to 10 loop
            for c in 0 to 3 loop
                for row in 0 to 3 loop
                    round_keys(r,row,c) := w(4*r + c)(row);
                end loop;
            end loop;
        end loop;

        return round_keys;
    end function;

    function aes_encrypt(plain : std_logic_vector(127 downto 0); key : std_logic_vector(127 downto 0)) return std_logic_vector is
        variable state : state_t;
        variable rk : round_keys_t;
        variable out_vec : std_logic_vector(127 downto 0);
        variable k : integer;
    begin
        for r in 0 to 3 loop
            for c in 0 to 3 loop
                k := r + 4*c;
                for i in 0 to 7 loop
                    state(r,c)(i) := plain(120 - 8*k + i);
                end loop;
            end loop;
        end loop;

        rk := key_expansion(key);

        state := add_round_key(state, rk, 0);
        for rnd in 1 to 9 loop
            state := sub_bytes(state);
            state := shift_rows(state);
            state := mix_columns(state);
            state := add_round_key(state, rk, rnd);
        end loop;
        state := sub_bytes(state);
        state := shift_rows(state);
        state := add_round_key(state, rk, 10);

        for r in 0 to 3 loop
            for c in 0 to 3 loop
                k := r + 4*c;
                for i in 0 to 7 loop
                    out_vec(120 - 8*k + i) := state(r,c)(i);
                end loop;
            end loop;
        end loop;

        return out_vec;
    end function;

begin

    process(clk, rst)
    begin
        if rst = '1' then
            Cypher_text <= (others => '0');
        elsif rising_edge(clk) then
            if EN = '1' then
                Cypher_text <= aes_encrypt(Plain_text, Key_in);
            end if;
        end if;
    end process;

end rtl;
