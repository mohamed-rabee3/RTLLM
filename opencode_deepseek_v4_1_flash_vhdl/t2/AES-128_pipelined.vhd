library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity AES_Encrypt is
    Port (
        clk        : in  STD_LOGIC;
        rst        : in  STD_LOGIC;
        Plain_text : in  STD_LOGIC_VECTOR (127 downto 0);
        EN         : in  STD_LOGIC;
        Key_in     : in  STD_LOGIC_VECTOR (127 downto 0);
        Cypher_text: out STD_LOGIC_VECTOR (127 downto 0)
    );
end AES_Encrypt;

architecture Behavioral of AES_Encrypt is

    type sbox_array is array (0 to 255) of std_logic_vector(7 downto 0);
    constant SBOX : sbox_array := (
        x"63", x"7c", x"77", x"7b", x"f2", x"6b", x"6f", x"c5",
        x"30", x"01", x"67", x"2b", x"fe", x"d7", x"ab", x"76",
        x"ca", x"82", x"c9", x"7d", x"fa", x"59", x"47", x"f0",
        x"ad", x"d4", x"a2", x"af", x"9c", x"a4", x"72", x"c0",
        x"b7", x"fd", x"93", x"26", x"36", x"3f", x"f7", x"cc",
        x"34", x"a5", x"e5", x"f1", x"71", x"d8", x"31", x"15",
        x"04", x"c7", x"23", x"c3", x"18", x"96", x"05", x"9a",
        x"07", x"12", x"80", x"e2", x"eb", x"27", x"b2", x"75",
        x"09", x"83", x"2c", x"1a", x"1b", x"6e", x"5a", x"a0",
        x"52", x"3b", x"d6", x"b3", x"29", x"e3", x"2f", x"84",
        x"53", x"d1", x"00", x"ed", x"20", x"fc", x"b1", x"5b",
        x"6a", x"cb", x"be", x"39", x"4a", x"4c", x"58", x"cf",
        x"d0", x"ef", x"aa", x"fb", x"43", x"4d", x"33", x"85",
        x"45", x"f9", x"02", x"7f", x"50", x"3c", x"9f", x"a8",
        x"51", x"a3", x"40", x"8f", x"92", x"9d", x"38", x"f5",
        x"bc", x"b6", x"da", x"21", x"10", x"ff", x"f3", x"d2",
        x"cd", x"0c", x"13", x"ec", x"5f", x"97", x"44", x"17",
        x"c4", x"a7", x"7e", x"3d", x"64", x"5d", x"19", x"73",
        x"60", x"81", x"4f", x"dc", x"22", x"2a", x"90", x"88",
        x"46", x"ee", x"b8", x"14", x"de", x"5e", x"0b", x"db",
        x"e0", x"32", x"3a", x"0a", x"49", x"06", x"24", x"5c",
        x"c2", x"d3", x"ac", x"62", x"91", x"95", x"e4", x"79",
        x"e7", x"c8", x"37", x"6d", x"8d", x"d5", x"4e", x"a9",
        x"6c", x"56", x"f4", x"ea", x"65", x"7a", x"ae", x"08",
        x"ba", x"78", x"25", x"2e", x"1c", x"a6", x"b4", x"c6",
        x"e8", x"dd", x"74", x"1f", x"4b", x"bd", x"8b", x"8a",
        x"70", x"3e", x"b5", x"66", x"48", x"03", x"f6", x"0e",
        x"61", x"35", x"57", x"b9", x"86", x"c1", x"1d", x"9e",
        x"e1", x"f8", x"98", x"11", x"69", x"d9", x"8e", x"94",
        x"9b", x"1e", x"87", x"e9", x"ce", x"55", x"28", x"df",
        x"8c", x"a1", x"89", x"0d", x"bf", x"e6", x"42", x"68",
        x"41", x"99", x"2d", x"0f", x"b0", x"54", x"bb", x"16"
    );

    type key_array is array (0 to 43) of std_logic_vector(31 downto 0);

    function sbox(a : std_logic_vector(7 downto 0)) return std_logic_vector is
        variable idx : integer range 0 to 255;
    begin
        idx := to_integer(unsigned(a));
        return SBOX(idx);
    end function;

    function xtime(a : std_logic_vector(7 downto 0)) return std_logic_vector is
        variable r : std_logic_vector(7 downto 0);
    begin
        r := a(6 downto 0) & '0';
        if a(7) = '1' then
            r := r xor x"1B";
        end if;
        return r;
    end function;

    function mul2(a : std_logic_vector(7 downto 0)) return std_logic_vector is
    begin
        return xtime(a);
    end function;

    function mul3(a : std_logic_vector(7 downto 0)) return std_logic_vector is
    begin
        return xtime(a) xor a;
    end function;

    function rot_word(w : std_logic_vector(31 downto 0)) return std_logic_vector is
    begin
        return w(23 downto 16) & w(15 downto 8) & w(7 downto 0) & w(31 downto 24);
    end function;

    function sub_word(w : std_logic_vector(31 downto 0)) return std_logic_vector is
    begin
        return sbox(w(31 downto 24)) & sbox(w(23 downto 16)) & sbox(w(15 downto 8)) & sbox(w(7 downto 0));
    end function;

    function rcon(r : integer) return std_logic_vector is
        variable rc : std_logic_vector(7 downto 0);
    begin
        case r is
            when 1 => rc := x"01";
            when 2 => rc := x"02";
            when 3 => rc := x"04";
            when 4 => rc := x"08";
            when 5 => rc := x"10";
            when 6 => rc := x"20";
            when 7 => rc := x"40";
            when 8 => rc := x"80";
            when 9 => rc := x"1B";
            when 10 => rc := x"36";
            when others => rc := x"00";
        end case;
        return rc & x"000000";
    end function;

    function key_expansion(key : std_logic_vector(127 downto 0)) return key_array is
        variable w : key_array;
        variable temp : std_logic_vector(31 downto 0);
    begin
        w(0) := key(127 downto 96);
        w(1) := key(95 downto 64);
        w(2) := key(63 downto 32);
        w(3) := key(31 downto 0);
        for i in 4 to 43 loop
            temp := w(i-1);
            if (i mod 4) = 0 then
                temp := sub_word(rot_word(temp)) xor rcon(i/4);
            end if;
            w(i) := w(i-4) xor temp;
        end loop;
        return w;
    end function;

    function get_round_key(key : std_logic_vector(127 downto 0); round_index : integer) return std_logic_vector is
        variable w : key_array;
    begin
        w := key_expansion(key);
        return w(4*round_index) & w(4*round_index+1) & w(4*round_index+2) & w(4*round_index+3);
    end function;

    function sub_bytes(v : std_logic_vector(127 downto 0)) return std_logic_vector is
    begin
        return sub_word(v(127 downto 96)) & sub_word(v(95 downto 64)) & sub_word(v(63 downto 32)) & sub_word(v(31 downto 0));
    end function;

    function shift_rows(v : std_logic_vector(127 downto 0)) return std_logic_vector is
        variable c0, c1, c2, c3 : std_logic_vector(31 downto 0);
        variable n0, n1, n2, n3 : std_logic_vector(31 downto 0);
    begin
        c0 := v(127 downto 96);
        c1 := v(95 downto 64);
        c2 := v(63 downto 32);
        c3 := v(31 downto 0);

        n0(31 downto 24) := c0(31 downto 24);
        n0(23 downto 16) := c1(23 downto 16);
        n0(15 downto 8)  := c2(15 downto 8);
        n0(7 downto 0)   := c3(7 downto 0);

        n1(31 downto 24) := c1(31 downto 24);
        n1(23 downto 16) := c2(23 downto 16);
        n1(15 downto 8)  := c3(15 downto 8);
        n1(7 downto 0)   := c0(7 downto 0);

        n2(31 downto 24) := c2(31 downto 24);
        n2(23 downto 16) := c3(23 downto 16);
        n2(15 downto 8)  := c0(15 downto 8);
        n2(7 downto 0)   := c1(7 downto 0);

        n3(31 downto 24) := c3(31 downto 24);
        n3(23 downto 16) := c0(23 downto 16);
        n3(15 downto 8)  := c1(15 downto 8);
        n3(7 downto 0)   := c2(7 downto 0);

        return n0 & n1 & n2 & n3;
    end function;

    function mix_column(w : std_logic_vector(31 downto 0)) return std_logic_vector is
        variable a0, a1, a2, a3 : std_logic_vector(7 downto 0);
        variable b0, b1, b2, b3 : std_logic_vector(7 downto 0);
    begin
        a0 := w(31 downto 24);
        a1 := w(23 downto 16);
        a2 := w(15 downto 8);
        a3 := w(7 downto 0);
        b0 := mul2(a0) xor mul3(a1) xor a2 xor a3;
        b1 := a0 xor mul2(a1) xor mul3(a2) xor a3;
        b2 := a0 xor a1 xor mul2(a2) xor mul3(a3);
        b3 := mul3(a0) xor a1 xor a2 xor mul2(a3);
        return b0 & b1 & b2 & b3;
    end function;

    function mix_columns(v : std_logic_vector(127 downto 0)) return std_logic_vector is
    begin
        return mix_column(v(127 downto 96)) & mix_column(v(95 downto 64)) & mix_column(v(63 downto 32)) & mix_column(v(31 downto 0));
    end function;

    function add_round_key(a, b : std_logic_vector(127 downto 0)) return std_logic_vector is
    begin
        return a xor b;
    end function;

    function full_round(v, rkey : std_logic_vector(127 downto 0)) return std_logic_vector is
    begin
        return add_round_key(mix_columns(shift_rows(sub_bytes(v))), rkey);
    end function;

    function final_round(v, rkey : std_logic_vector(127 downto 0)) return std_logic_vector is
    begin
        return add_round_key(shift_rows(sub_bytes(v)), rkey);
    end function;

    signal s0, s1, s2, s3, s4, s5, s6, s7, s8, s9, s10 : std_logic_vector(127 downto 0);
    signal k0, k1, k2, k3, k4, k5, k6, k7, k8, k9 : std_logic_vector(127 downto 0);
    signal v0, v1, v2, v3, v4, v5, v6, v7, v8, v9, v10 : std_logic;

begin

    process(clk, rst)
    begin
        if rst = '1' then
            s0 <= (others => '0'); s1 <= (others => '0'); s2 <= (others => '0'); s3 <= (others => '0');
            s4 <= (others => '0'); s5 <= (others => '0'); s6 <= (others => '0'); s7 <= (others => '0');
            s8 <= (others => '0'); s9 <= (others => '0'); s10 <= (others => '0');
            k0 <= (others => '0'); k1 <= (others => '0'); k2 <= (others => '0'); k3 <= (others => '0');
            k4 <= (others => '0'); k5 <= (others => '0'); k6 <= (others => '0'); k7 <= (others => '0');
            k8 <= (others => '0'); k9 <= (others => '0');
            v0 <= '0'; v1 <= '0'; v2 <= '0'; v3 <= '0'; v4 <= '0';
            v5 <= '0'; v6 <= '0'; v7 <= '0'; v8 <= '0'; v9 <= '0'; v10 <= '0';
        elsif rising_edge(clk) then

            -- Stage 0: initial AddRoundKey
            if EN = '1' then
                s0 <= add_round_key(Plain_text, Key_in);
                k0 <= Key_in;
                v0 <= '1';
            else
                s0 <= (others => '0');
                k0 <= (others => '0');
                v0 <= '0';
            end if;

            -- Stage 1: round 1
            if v0 = '1' then
                s1 <= full_round(s0, get_round_key(k0, 1));
                k1 <= k0;
                v1 <= '1';
            else
                s1 <= (others => '0');
                k1 <= (others => '0');
                v1 <= '0';
            end if;

            -- Stage 2: round 2
            if v1 = '1' then
                s2 <= full_round(s1, get_round_key(k1, 2));
                k2 <= k1;
                v2 <= '1';
            else
                s2 <= (others => '0');
                k2 <= (others => '0');
                v2 <= '0';
            end if;

            -- Stage 3: round 3
            if v2 = '1' then
                s3 <= full_round(s2, get_round_key(k2, 3));
                k3 <= k2;
                v3 <= '1';
            else
                s3 <= (others => '0');
                k3 <= (others => '0');
                v3 <= '0';
            end if;

            -- Stage 4: round 4
            if v3 = '1' then
                s4 <= full_round(s3, get_round_key(k3, 4));
                k4 <= k3;
                v4 <= '1';
            else
                s4 <= (others => '0');
                k4 <= (others => '0');
                v4 <= '0';
            end if;

            -- Stage 5: round 5
            if v4 = '1' then
                s5 <= full_round(s4, get_round_key(k4, 5));
                k5 <= k4;
                v5 <= '1';
            else
                s5 <= (others => '0');
                k5 <= (others => '0');
                v5 <= '0';
            end if;

            -- Stage 6: round 6
            if v5 = '1' then
                s6 <= full_round(s5, get_round_key(k5, 6));
                k6 <= k5;
                v6 <= '1';
            else
                s6 <= (others => '0');
                k6 <= (others => '0');
                v6 <= '0';
            end if;

            -- Stage 7: round 7
            if v6 = '1' then
                s7 <= full_round(s6, get_round_key(k6, 7));
                k7 <= k6;
                v7 <= '1';
            else
                s7 <= (others => '0');
                k7 <= (others => '0');
                v7 <= '0';
            end if;

            -- Stage 8: round 8
            if v7 = '1' then
                s8 <= full_round(s7, get_round_key(k7, 8));
                k8 <= k7;
                v8 <= '1';
            else
                s8 <= (others => '0');
                k8 <= (others => '0');
                v8 <= '0';
            end if;

            -- Stage 9: round 9
            if v8 = '1' then
                s9 <= full_round(s8, get_round_key(k8, 9));
                k9 <= k8;
                v9 <= '1';
            else
                s9 <= (others => '0');
                k9 <= (others => '0');
                v9 <= '0';
            end if;

            -- Stage 10: final round
            if v9 = '1' then
                s10 <= final_round(s9, get_round_key(k9, 10));
                v10 <= '1';
            else
                v10 <= '0';
            end if;

        end if;
    end process;

    Cypher_text <= s10;

end Behavioral;
