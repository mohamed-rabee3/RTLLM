library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity AES_Encrypt is
    Port (
        clk        : in  std_logic;
        rst        : in  std_logic;
        Plain_text : in  std_logic_vector(127 downto 0);
        EN         : in  std_logic;
        Key_in     : in  std_logic_vector(127 downto 0);
        Cypher_text: out std_logic_vector(127 downto 0)
    );
end AES_Encrypt;

architecture rtl of AES_Encrypt is

    subtype byte_t is std_logic_vector(7 downto 0);
    type state_array_t is array (0 to 15) of byte_t;
    type sbox_array_t is array (0 to 255) of byte_t;
    type pipe_state_t is array (0 to 10) of std_logic_vector(127 downto 0);
    type pipe_key_t is array (0 to 9) of std_logic_vector(127 downto 0);

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

    signal state_reg : pipe_state_t;
    signal key_reg   : pipe_key_t;

    function xtime(a : byte_t) return byte_t is
        variable r : byte_t;
    begin
        if a(7) = '1' then
            r := (a(6 downto 0) & '0') xor x"1B";
        else
            r := (a(6 downto 0) & '0');
        end if;
        return r;
    end function;

    function sbox8(x : byte_t) return byte_t is
    begin
        return SBOX(to_integer(unsigned(x)));
    end function;

    function to_state(v : std_logic_vector(127 downto 0)) return state_array_t is
        variable s : state_array_t;
    begin
        for i in 0 to 15 loop
            s(i) := v(127 - 8*i downto 120 - 8*i);
        end loop;
        return s;
    end function;

    function from_state(s : state_array_t) return std_logic_vector is
        variable v : std_logic_vector(127 downto 0);
    begin
        for i in 0 to 15 loop
            v(127 - 8*i downto 120 - 8*i) := s(i);
        end loop;
        return v;
    end function;

    function sub_bytes(v : std_logic_vector(127 downto 0)) return std_logic_vector is
        variable s : state_array_t;
    begin
        s := to_state(v);
        for i in 0 to 15 loop
            s(i) := sbox8(s(i));
        end loop;
        return from_state(s);
    end function;

    function shift_rows(v : std_logic_vector(127 downto 0)) return std_logic_vector is
        variable s, t : state_array_t;
    begin
        s := to_state(v);
        for r in 0 to 3 loop
            for c in 0 to 3 loop
                t(r + 4*c) := s(r + 4*((c + r) mod 4));
            end loop;
        end loop;
        return from_state(t);
    end function;

    function mix_columns(v : std_logic_vector(127 downto 0)) return std_logic_vector is
        variable s, t : state_array_t;
        variable a0, a1, a2, a3, b0, b1, b2, b3 : byte_t;
    begin
        s := to_state(v);
        for c in 0 to 3 loop
            a0 := s(0 + 4*c);
            a1 := s(1 + 4*c);
            a2 := s(2 + 4*c);
            a3 := s(3 + 4*c);
            b0 := xtime(a0) xor xtime(a1) xor a1 xor a2 xor a3;
            b1 := a0 xor xtime(a1) xor xtime(a2) xor a2 xor a3;
            b2 := a0 xor a1 xor xtime(a2) xor xtime(a3) xor a3;
            b3 := xtime(a0) xor a0 xor a1 xor a2 xor xtime(a3);
            t(0 + 4*c) := b0;
            t(1 + 4*c) := b1;
            t(2 + 4*c) := b2;
            t(3 + 4*c) := b3;
        end loop;
        return from_state(t);
    end function;

    function add_round_key(v, k : std_logic_vector(127 downto 0)) return std_logic_vector is
    begin
        return v xor k;
    end function;

    function next_round_key(prev_key : std_logic_vector(127 downto 0); rcon : byte_t) return std_logic_vector is
        variable s, t : state_array_t;
        variable temp0, temp1, temp2, temp3 : byte_t;
    begin
        s := to_state(prev_key);
        temp0 := sbox8(s(13)) xor rcon;
        temp1 := sbox8(s(14));
        temp2 := sbox8(s(15));
        temp3 := sbox8(s(12));
        t(0) := s(0) xor temp0;
        t(1) := s(1) xor temp1;
        t(2) := s(2) xor temp2;
        t(3) := s(3) xor temp3;
        t(4) := s(4) xor t(0);
        t(5) := s(5) xor t(1);
        t(6) := s(6) xor t(2);
        t(7) := s(7) xor t(3);
        t(8) := s(8) xor t(4);
        t(9) := s(9) xor t(5);
        t(10) := s(10) xor t(6);
        t(11) := s(11) xor t(7);
        t(12) := s(12) xor t(8);
        t(13) := s(13) xor t(9);
        t(14) := s(14) xor t(10);
        t(15) := s(15) xor t(11);
        return from_state(t);
    end function;

    function rcon_byte(round : integer) return byte_t is
    begin
        case round is
            when 1 => return x"01";
            when 2 => return x"02";
            when 3 => return x"04";
            when 4 => return x"08";
            when 5 => return x"10";
            when 6 => return x"20";
            when 7 => return x"40";
            when 8 => return x"80";
            when 9 => return x"1B";
            when 10 => return x"36";
            when others => return x"00";
        end case;
    end function;

begin

    process(clk, rst)
    begin
        if rst = '1' then
            for i in 0 to 10 loop
                state_reg(i) <= (others => '0');
            end loop;
            for i in 0 to 9 loop
                key_reg(i) <= (others => '0');
            end loop;
        elsif rising_edge(clk) then
            if EN = '1' then
                state_reg(0) <= add_round_key(Plain_text, Key_in);
                key_reg(0) <= next_round_key(Key_in, rcon_byte(1));
            else
                state_reg(0) <= (others => '0');
                key_reg(0) <= (others => '0');
            end if;

            for i in 1 to 9 loop
                state_reg(i) <= add_round_key(
                    mix_columns(shift_rows(sub_bytes(state_reg(i-1)))),
                    key_reg(i-1)
                );
                key_reg(i) <= next_round_key(key_reg(i-1), rcon_byte(i+1));
            end loop;

            state_reg(10) <= add_round_key(
                shift_rows(sub_bytes(state_reg(9))),
                key_reg(9)
            );
        end if;
    end process;

    Cypher_text <= state_reg(10);

end rtl;
