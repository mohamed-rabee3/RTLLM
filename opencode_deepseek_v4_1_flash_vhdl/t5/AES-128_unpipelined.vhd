library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity AES_Encrypt is
    port (
        clk : in std_logic;
        rst : in std_logic;
        Plain_text : in std_logic_vector(127 downto 0);
        EN : in std_logic;
        Key_in : in std_logic_vector(127 downto 0);
        Cypher_text : out std_logic_vector(127 downto 0)
    );
end AES_Encrypt;

architecture behavioral of AES_Encrypt is

    type state_t is array (0 to 3, 0 to 3) of std_logic_vector(7 downto 0);
    type key_schedule_t is array (0 to 10) of std_logic_vector(127 downto 0);
    type sbox_array_t is array (0 to 255) of std_logic_vector(7 downto 0);
    type rcon_array_t is array (1 to 10) of std_logic_vector(7 downto 0);
    type word_array_t is array (0 to 43) of std_logic_vector(31 downto 0);

    constant SBOX : sbox_array_t := (
        X"63", X"7c", X"77", X"7b", X"f2", X"6b", X"6f", X"c5", X"30", X"01", X"67", X"2b", X"fe", X"d7", X"ab", X"76",
        X"ca", X"82", X"c9", X"7d", X"fa", X"59", X"47", X"f0", X"ad", X"d4", X"a2", X"af", X"9c", X"a4", X"72", X"c0",
        X"b7", X"fd", X"93", X"26", X"36", X"3f", X"f7", X"cc", X"34", X"a5", X"e5", X"f1", X"71", X"d8", X"31", X"15",
        X"04", X"c7", X"23", X"c3", X"18", X"96", X"05", X"9a", X"07", X"12", X"80", X"e2", X"eb", X"27", X"b2", X"75",
        X"09", X"83", X"2c", X"1a", X"1b", X"6e", X"5a", X"a0", X"52", X"3b", X"d6", X"b3", X"29", X"e3", X"2f", X"84",
        X"53", X"d1", X"00", X"ed", X"20", X"fc", X"b1", X"5b", X"6a", X"cb", X"be", X"39", X"4a", X"4c", X"58", X"cf",
        X"d0", X"ef", X"aa", X"fb", X"43", X"4d", X"33", X"85", X"45", X"f9", X"02", X"7f", X"50", X"3c", X"9f", X"a8",
        X"51", X"a3", X"40", X"8f", X"92", X"9d", X"38", X"f5", X"bc", X"b6", X"da", X"21", X"10", X"ff", X"f3", X"d2",
        X"cd", X"0c", X"13", X"ec", X"5f", X"97", X"44", X"17", X"c4", X"a7", X"7e", X"3d", X"64", X"5d", X"19", X"73",
        X"60", X"81", X"4f", X"dc", X"22", X"2a", X"90", X"88", X"46", X"ee", X"b8", X"14", X"de", X"5e", X"0b", X"db",
        X"e0", X"32", X"3a", X"0a", X"49", X"06", X"24", X"5c", X"c2", X"d3", X"ac", X"62", X"91", X"95", X"e4", X"79",
        X"e7", X"c8", X"37", X"6d", X"8d", X"d5", X"4e", X"a9", X"6c", X"56", X"f4", X"ea", X"65", X"7a", X"ae", X"08",
        X"ba", X"78", X"25", X"2e", X"1c", X"a6", X"b4", X"c6", X"e8", X"dd", X"74", X"1f", X"4b", X"bd", X"8b", X"8a",
        X"70", X"3e", X"b5", X"66", X"48", X"03", X"f6", X"0e", X"61", X"35", X"57", X"b9", X"86", X"c1", X"1d", X"9e",
        X"e1", X"f8", X"98", X"11", X"69", X"d9", X"8e", X"94", X"9b", X"1e", X"87", X"e9", X"ce", X"55", X"28", X"df",
        X"8c", X"a1", X"89", X"0d", X"bf", X"e6", X"42", X"68", X"41", X"99", X"2d", X"0f", X"b0", X"54", X"bb", X"16"
    );

    constant RCON : rcon_array_t := (
        X"01", X"02", X"04", X"08", X"10", X"20", X"40", X"80", X"1B", X"36"
    );

    function bytes_to_state(v: std_logic_vector(127 downto 0)) return state_t is
        variable s: state_t;
    begin
        s(0,0) := v(127 downto 120);
        s(1,0) := v(119 downto 112);
        s(2,0) := v(111 downto 104);
        s(3,0) := v(103 downto 96);
        s(0,1) := v(95 downto 88);
        s(1,1) := v(87 downto 80);
        s(2,1) := v(79 downto 72);
        s(3,1) := v(71 downto 64);
        s(0,2) := v(63 downto 56);
        s(1,2) := v(55 downto 48);
        s(2,2) := v(47 downto 40);
        s(3,2) := v(39 downto 32);
        s(0,3) := v(31 downto 24);
        s(1,3) := v(23 downto 16);
        s(2,3) := v(15 downto 8);
        s(3,3) := v(7 downto 0);
        return s;
    end;

    function state_to_bytes(s: state_t) return std_logic_vector is
        variable v: std_logic_vector(127 downto 0);
    begin
        v(127 downto 120) := s(0,0);
        v(119 downto 112) := s(1,0);
        v(111 downto 104) := s(2,0);
        v(103 downto 96) := s(3,0);
        v(95 downto 88) := s(0,1);
        v(87 downto 80) := s(1,1);
        v(79 downto 72) := s(2,1);
        v(71 downto 64) := s(3,1);
        v(63 downto 56) := s(0,2);
        v(55 downto 48) := s(1,2);
        v(47 downto 40) := s(2,2);
        v(39 downto 32) := s(3,2);
        v(31 downto 24) := s(0,3);
        v(23 downto 16) := s(1,3);
        v(15 downto 8) := s(2,3);
        v(7 downto 0) := s(3,3);
        return v;
    end;

    function xtime(b: std_logic_vector(7 downto 0)) return std_logic_vector is
        variable r: std_logic_vector(7 downto 0);
    begin
        if b(7) = '1' then
            r := (b(6 downto 0) & '0') xor X"1B";
        else
            r := b(6 downto 0) & '0';
        end if;
        return r;
    end;

    function mul2(b: std_logic_vector(7 downto 0)) return std_logic_vector is
    begin
        return xtime(b);
    end;

    function mul3(b: std_logic_vector(7 downto 0)) return std_logic_vector is
    begin
        return xtime(b) xor b;
    end;

    function SubWord(w: std_logic_vector(31 downto 0)) return std_logic_vector is
        variable res: std_logic_vector(31 downto 0);
    begin
        res(31 downto 24) := SBOX(to_integer(unsigned(w(31 downto 24))));
        res(23 downto 16) := SBOX(to_integer(unsigned(w(23 downto 16))));
        res(15 downto 8)  := SBOX(to_integer(unsigned(w(15 downto 8))));
        res(7 downto 0)   := SBOX(to_integer(unsigned(w(7 downto 0))));
        return res;
    end;

    function RotWord(w: std_logic_vector(31 downto 0)) return std_logic_vector is
    begin
        return w(23 downto 0) & w(31 downto 24);
    end;

    function KeyExpansion(key: std_logic_vector(127 downto 0)) return key_schedule_t is
        variable w: word_array_t;
        variable temp: std_logic_vector(31 downto 0);
        variable rk: key_schedule_t;
    begin
        w(0) := key(127 downto 96);
        w(1) := key(95 downto 64);
        w(2) := key(63 downto 32);
        w(3) := key(31 downto 0);
        for i in 4 to 43 loop
            temp := w(i-1);
            if (i mod 4) = 0 then
                temp := SubWord(RotWord(temp)) xor (RCON(i/4) & X"000000");
            end if;
            w(i) := w(i-4) xor temp;
        end loop;
        for r in 0 to 10 loop
            rk(r) := w(4*r) & w(4*r+1) & w(4*r+2) & w(4*r+3);
        end loop;
        return rk;
    end;

    function AddRoundKey(s: state_t; rk: std_logic_vector(127 downto 0)) return state_t is
        variable t: state_t;
        variable k: state_t;
    begin
        k := bytes_to_state(rk);
        for r in 0 to 3 loop
            for c in 0 to 3 loop
                t(r,c) := s(r,c) xor k(r,c);
            end loop;
        end loop;
        return t;
    end;

    function SubBytes(s: state_t) return state_t is
        variable t: state_t;
    begin
        for r in 0 to 3 loop
            for c in 0 to 3 loop
                t(r,c) := SBOX(to_integer(unsigned(s(r,c))));
            end loop;
        end loop;
        return t;
    end;

    function ShiftRows(s: state_t) return state_t is
        variable t: state_t;
    begin
        for r in 0 to 3 loop
            for c in 0 to 3 loop
                t(r,c) := s(r, (c+r) mod 4);
            end loop;
        end loop;
        return t;
    end;

    function MixColumns(s: state_t) return state_t is
        variable t: state_t;
        variable a0, a1, a2, a3 : std_logic_vector(7 downto 0);
    begin
        t := s;
        for c in 0 to 3 loop
            a0 := s(0,c);
            a1 := s(1,c);
            a2 := s(2,c);
            a3 := s(3,c);
            t(0,c) := mul2(a0) xor mul3(a1) xor a2 xor a3;
            t(1,c) := a0 xor mul2(a1) xor mul3(a2) xor a3;
            t(2,c) := a0 xor a1 xor mul2(a2) xor mul3(a3);
            t(3,c) := mul3(a0) xor a1 xor a2 xor mul2(a3);
        end loop;
        return t;
    end;

    function AES_Encrypt_Block(plain: std_logic_vector(127 downto 0); key: std_logic_vector(127 downto 0)) return std_logic_vector is
        variable state: state_t;
        variable rk: key_schedule_t;
    begin
        rk := KeyExpansion(key);
        state := bytes_to_state(plain);
        state := AddRoundKey(state, rk(0));
        for round in 1 to 9 loop
            state := SubBytes(state);
            state := ShiftRows(state);
            state := MixColumns(state);
            state := AddRoundKey(state, rk(round));
        end loop;
        state := SubBytes(state);
        state := ShiftRows(state);
        state := AddRoundKey(state, rk(10));
        return state_to_bytes(state);
    end;

    signal cipher_reg : std_logic_vector(127 downto 0);

begin

    process(clk, rst)
    begin
        if rst = '1' then
            cipher_reg <= (others => '0');
        elsif rising_edge(clk) then
            if EN = '1' then
                cipher_reg <= AES_Encrypt_Block(Plain_text, Key_in);
            end if;
        end if;
    end process;

    Cypher_text <= cipher_reg;

end behavioral;
