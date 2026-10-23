library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity AES_Encrypt is
    port (
        clk         : in  std_logic;
        rst         : in  std_logic;
        Plain_text  : in  std_logic_vector(127 downto 0);
        EN          : in  std_logic;
        Key_in      : in  std_logic_vector(127 downto 0);
        Cypher_text : out std_logic_vector(127 downto 0)
    );
end AES_Encrypt;

architecture Behavioral of AES_Encrypt is

    type sbox_array is array (0 to 255) of std_logic_vector(7 downto 0);
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

    type rcon_array is array (1 to 10) of std_logic_vector(7 downto 0);
    constant RCON : rcon_array := (
        x"01", x"02", x"04", x"08", x"10", x"20", x"40", x"80", x"1B", x"36"
    );

    type perm_array is array (0 to 15) of integer;
    constant SHIFT_PERM : perm_array := (0,5,10,15,4,9,14,3,8,13,2,7,12,1,6,11);

    function sbox(b : std_logic_vector(7 downto 0)) return std_logic_vector is
    begin
        return SBOX(to_integer(unsigned(b)));
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

    function mix_column(col : std_logic_vector(31 downto 0)) return std_logic_vector is
        variable a0, a1, a2, a3 : std_logic_vector(7 downto 0);
        variable r0, r1, r2, r3 : std_logic_vector(7 downto 0);
    begin
        a0 := col(31 downto 24);
        a1 := col(23 downto 16);
        a2 := col(15 downto 8);
        a3 := col(7 downto 0);
        r0 := xtime(a0) xor (xtime(a1) xor a1) xor a2 xor a3;
        r1 := a0 xor xtime(a1) xor (xtime(a2) xor a2) xor a3;
        r2 := a0 xor a1 xor xtime(a2) xor (xtime(a3) xor a3);
        r3 := (xtime(a0) xor a0) xor a1 xor a2 xor xtime(a3);
        return r0 & r1 & r2 & r3;
    end function;

    function sub_bytes(state : std_logic_vector(127 downto 0)) return std_logic_vector is
        variable result : std_logic_vector(127 downto 0);
    begin
        for i in 0 to 15 loop
            result(127 - i*8 downto 120 - i*8) := sbox(state(127 - i*8 downto 120 - i*8));
        end loop;
        return result;
    end function;

    function shift_rows(state : std_logic_vector(127 downto 0)) return std_logic_vector is
        variable result : std_logic_vector(127 downto 0);
    begin
        for i in 0 to 15 loop
            result(127 - i*8 downto 120 - i*8) := state(127 - SHIFT_PERM(i)*8 downto 120 - SHIFT_PERM(i)*8);
        end loop;
        return result;
    end function;

    function mix_columns(state : std_logic_vector(127 downto 0)) return std_logic_vector is
        variable result : std_logic_vector(127 downto 0);
    begin
        for c in 0 to 3 loop
            result(127 - c*32 downto 96 - c*32) := mix_column(state(127 - c*32 downto 96 - c*32));
        end loop;
        return result;
    end function;

    function add_round_key(state : std_logic_vector(127 downto 0); key : std_logic_vector(127 downto 0)) return std_logic_vector is
    begin
        return state xor key;
    end function;

    function Round_Top(state : std_logic_vector(127 downto 0); key : std_logic_vector(127 downto 0)) return std_logic_vector is
        variable s : std_logic_vector(127 downto 0);
    begin
        s := sub_bytes(state);
        s := shift_rows(s);
        s := mix_columns(s);
        s := add_round_key(s, key);
        return s;
    end function;

    function Final_Round(state : std_logic_vector(127 downto 0); key : std_logic_vector(127 downto 0)) return std_logic_vector is
        variable s : std_logic_vector(127 downto 0);
    begin
        s := sub_bytes(state);
        s := shift_rows(s);
        s := add_round_key(s, key);
        return s;
    end function;

    function rot_word(w : std_logic_vector(31 downto 0)) return std_logic_vector is
    begin
        return w(23 downto 0) & w(31 downto 24);
    end function;

    function sub_word(w : std_logic_vector(31 downto 0)) return std_logic_vector is
        variable b0, b1, b2, b3 : std_logic_vector(7 downto 0);
    begin
        b0 := w(31 downto 24);
        b1 := w(23 downto 16);
        b2 := w(15 downto 8);
        b3 := w(7 downto 0);
        return sbox(b0) & sbox(b1) & sbox(b2) & sbox(b3);
    end function;

    function next_key(key : std_logic_vector(127 downto 0); round : integer) return std_logic_vector is
        variable w0, w1, w2, w3 : std_logic_vector(31 downto 0);
        variable temp : std_logic_vector(31 downto 0);
        variable new0, new1, new2, new3 : std_logic_vector(31 downto 0);
    begin
        w0 := key(127 downto 96);
        w1 := key(95 downto 64);
        w2 := key(63 downto 32);
        w3 := key(31 downto 0);
        temp := sub_word(rot_word(w3)) xor (RCON(round) & x"000000");
        new0 := w0 xor temp;
        new1 := w1 xor new0;
        new2 := w2 xor new1;
        new3 := w3 xor new2;
        return new0 & new1 & new2 & new3;
    end function;

    type state_array is array (0 to 10) of std_logic_vector(127 downto 0);
    type key_array is array (1 to 10) of std_logic_vector(127 downto 0);
    signal r_st : state_array;
    signal k : key_array;

begin

    process(clk, rst)
    begin
        if rst = '1' then
            for i in 0 to 10 loop
                r_st(i) <= (others => '0');
            end loop;
            for i in 1 to 10 loop
                k(i) <= (others => '0');
            end loop;
        elsif rising_edge(clk) then
            if EN = '1' then
                r_st(0) <= Plain_text xor Key_in;
                k(1) <= next_key(Key_in, 1);
                r_st(1) <= Round_Top(r_st(0), k(1));
                k(2) <= next_key(k(1), 2);
                r_st(2) <= Round_Top(r_st(1), k(2));
                k(3) <= next_key(k(2), 3);
                r_st(3) <= Round_Top(r_st(2), k(3));
                k(4) <= next_key(k(3), 4);
                r_st(4) <= Round_Top(r_st(3), k(4));
                k(5) <= next_key(k(4), 5);
                r_st(5) <= Round_Top(r_st(4), k(5));
                k(6) <= next_key(k(5), 6);
                r_st(6) <= Round_Top(r_st(5), k(6));
                k(7) <= next_key(k(6), 7);
                r_st(7) <= Round_Top(r_st(6), k(7));
                k(8) <= next_key(k(7), 8);
                r_st(8) <= Round_Top(r_st(7), k(8));
                k(9) <= next_key(k(8), 9);
                r_st(9) <= Round_Top(r_st(8), k(9));
                k(10) <= next_key(k(9), 10);
                r_st(10) <= Final_Round(r_st(9), k(10));
            end if;
        end if;
    end process;

    Cypher_text <= r_st(10);

end Behavioral;
