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

    type byte_array is array (0 to 15) of std_logic_vector(7 downto 0);
    type word_array is array (0 to 43) of std_logic_vector(31 downto 0);
    type round_key_array is array (0 to 10) of byte_array;

    function sbox(input : std_logic_vector(7 downto 0)) return std_logic_vector is
        variable res : std_logic_vector(7 downto 0);
    begin
        case input is
            when x"00" => res := x"63";
            when x"01" => res := x"7C";
            when x"02" => res := x"77";
            when x"03" => res := x"7B";
            when x"04" => res := x"F2";
            when x"05" => res := x"6B";
            when x"06" => res := x"6F";
            when x"07" => res := x"C5";
            when x"08" => res := x"30";
            when x"09" => res := x"01";
            when x"0A" => res := x"67";
            when x"0B" => res := x"2B";
            when x"0C" => res := x"FE";
            when x"0D" => res := x"D7";
            when x"0E" => res := x"AB";
            when x"0F" => res := x"76";

            when x"10" => res := x"CA";
            when x"11" => res := x"82";
            when x"12" => res := x"C9";
            when x"13" => res := x"7D";
            when x"14" => res := x"FA";
            when x"15" => res := x"59";
            when x"16" => res := x"47";
            when x"17" => res := x"F0";
            when x"18" => res := x"AD";
            when x"19" => res := x"D4";
            when x"1A" => res := x"A2";
            when x"1B" => res := x"AF";
            when x"1C" => res := x"9C";
            when x"1D" => res := x"A4";
            when x"1E" => res := x"72";
            when x"1F" => res := x"C0";

            when x"20" => res := x"B7";
            when x"21" => res := x"FD";
            when x"22" => res := x"93";
            when x"23" => res := x"26";
            when x"24" => res := x"36";
            when x"25" => res := x"3F";
            when x"26" => res := x"F7";
            when x"27" => res := x"CC";
            when x"28" => res := x"34";
            when x"29" => res := x"A5";
            when x"2A" => res := x"E5";
            when x"2B" => res := x"F1";
            when x"2C" => res := x"71";
            when x"2D" => res := x"D8";
            when x"2E" => res := x"31";
            when x"2F" => res := x"15";

            when x"30" => res := x"04";
            when x"31" => res := x"C7";
            when x"32" => res := x"23";
            when x"33" => res := x"C3";
            when x"34" => res := x"18";
            when x"35" => res := x"96";
            when x"36" => res := x"05";
            when x"37" => res := x"9A";
            when x"38" => res := x"07";
            when x"39" => res := x"12";
            when x"3A" => res := x"80";
            when x"3B" => res := x"E2";
            when x"3C" => res := x"EB";
            when x"3D" => res := x"27";
            when x"3E" => res := x"B2";
            when x"3F" => res := x"75";

            when x"40" => res := x"09";
            when x"41" => res := x"83";
            when x"42" => res := x"2C";
            when x"43" => res := x"1A";
            when x"44" => res := x"1B";
            when x"45" => res := x"6E";
            when x"46" => res := x"5A";
            when x"47" => res := x"A0";
            when x"48" => res := x"52";
            when x"49" => res := x"3B";
            when x"4A" => res := x"D6";
            when x"4B" => res := x"B3";
            when x"4C" => res := x"29";
            when x"4D" => res := x"E3";
            when x"4E" => res := x"2F";
            when x"4F" => res := x"84";

            when x"50" => res := x"53";
            when x"51" => res := x"D1";
            when x"52" => res := x"00";
            when x"53" => res := x"ED";
            when x"54" => res := x"20";
            when x"55" => res := x"FC";
            when x"56" => res := x"B1";
            when x"57" => res := x"5B";
            when x"58" => res := x"6A";
            when x"59" => res := x"CB";
            when x"5A" => res := x"BE";
            when x"5B" => res := x"39";
            when x"5C" => res := x"4A";
            when x"5D" => res := x"4C";
            when x"5E" => res := x"58";
            when x"5F" => res := x"CF";

            when x"60" => res := x"D0";
            when x"61" => res := x"EF";
            when x"62" => res := x"AA";
            when x"63" => res := x"FB";
            when x"64" => res := x"43";
            when x"65" => res := x"4D";
            when x"66" => res := x"33";
            when x"67" => res := x"85";
            when x"68" => res := x"45";
            when x"69" => res := x"F9";
            when x"6A" => res := x"02";
            when x"6B" => res := x"7F";
            when x"6C" => res := x"50";
            when x"6D" => res := x"3C";
            when x"6E" => res := x"9F";
            when x"6F" => res := x"A8";

            when x"70" => res := x"51";
            when x"71" => res := x"A3";
            when x"72" => res := x"40";
            when x"73" => res := x"8F";
            when x"74" => res := x"92";
            when x"75" => res := x"9D";
            when x"76" => res := x"38";
            when x"77" => res := x"F5";
            when x"78" => res := x"BC";
            when x"79" => res := x"B6";
            when x"7A" => res := x"DA";
            when x"7B" => res := x"21";
            when x"7C" => res := x"10";
            when x"7D" => res := x"FF";
            when x"7E" => res := x"F3";
            when x"7F" => res := x"D2";

            when x"80" => res := x"CD";
            when x"81" => res := x"0C";
            when x"82" => res := x"13";
            when x"83" => res := x"EC";
            when x"84" => res := x"5F";
            when x"85" => res := x"97";
            when x"86" => res := x"44";
            when x"87" => res := x"17";
            when x"88" => res := x"C4";
            when x"89" => res := x"A7";
            when x"8A" => res := x"7E";
            when x"8B" => res := x"3D";
            when x"8C" => res := x"64";
            when x"8D" => res := x"5D";
            when x"8E" => res := x"19";
            when x"8F" => res := x"73";

            when x"90" => res := x"60";
            when x"91" => res := x"81";
            when x"92" => res := x"4F";
            when x"93" => res := x"DC";
            when x"94" => res := x"22";
            when x"95" => res := x"2A";
            when x"96" => res := x"90";
            when x"97" => res := x"88";
            when x"98" => res := x"46";
            when x"99" => res := x"EE";
            when x"9A" => res := x"B8";
            when x"9B" => res := x"14";
            when x"9C" => res := x"DE";
            when x"9D" => res := x"5E";
            when x"9E" => res := x"0B";
            when x"9F" => res := x"DB";

            when x"A0" => res := x"E0";
            when x"A1" => res := x"32";
            when x"A2" => res := x"3A";
            when x"A3" => res := x"0A";
            when x"A4" => res := x"49";
            when x"A5" => res := x"06";
            when x"A6" => res := x"24";
            when x"A7" => res := x"5C";
            when x"A8" => res := x"C2";
            when x"A9" => res := x"D3";
            when x"AA" => res := x"AC";
            when x"AB" => res := x"62";
            when x"AC" => res := x"91";
            when x"AD" => res := x"95";
            when x"AE" => res := x"E4";
            when x"AF" => res := x"79";

            when x"B0" => res := x"E7";
            when x"B1" => res := x"C8";
            when x"B2" => res := x"37";
            when x"B3" => res := x"6D";
            when x"B4" => res := x"8D";
            when x"B5" => res := x"D5";
            when x"B6" => res := x"4E";
            when x"B7" => res := x"A9";
            when x"B8" => res := x"6C";
            when x"B9" => res := x"56";
            when x"BA" => res := x"F4";
            when x"BB" => res := x"EA";
            when x"BC" => res := x"65";
            when x"BD" => res := x"7A";
            when x"BE" => res := x"AE";
            when x"BF" => res := x"08";

            when x"C0" => res := x"BA";
            when x"C1" => res := x"78";
            when x"C2" => res := x"25";
            when x"C3" => res := x"2E";
            when x"C4" => res := x"1C";
            when x"C5" => res := x"A6";
            when x"C6" => res := x"B4";
            when x"C7" => res := x"C6";
            when x"C8" => res := x"E8";
            when x"C9" => res := x"DD";
            when x"CA" => res := x"74";
            when x"CB" => res := x"1F";
            when x"CC" => res := x"4B";
            when x"CD" => res := x"BD";
            when x"CE" => res := x"8B";
            when x"CF" => res := x"8A";

            when x"D0" => res := x"70";
            when x"D1" => res := x"3E";
            when x"D2" => res := x"B5";
            when x"D3" => res := x"66";
            when x"D4" => res := x"48";
            when x"D5" => res := x"03";
            when x"D6" => res := x"F6";
            when x"D7" => res := x"0E";
            when x"D8" => res := x"61";
            when x"D9" => res := x"35";
            when x"DA" => res := x"57";
            when x"DB" => res := x"B9";
            when x"DC" => res := x"86";
            when x"DD" => res := x"C1";
            when x"DE" => res := x"1D";
            when x"DF" => res := x"9E";

            when x"E0" => res := x"E1";
            when x"E1" => res := x"F8";
            when x"E2" => res := x"98";
            when x"E3" => res := x"11";
            when x"E4" => res := x"69";
            when x"E5" => res := x"D9";
            when x"E6" => res := x"8E";
            when x"E7" => res := x"94";
            when x"E8" => res := x"9B";
            when x"E9" => res := x"1E";
            when x"EA" => res := x"87";
            when x"EB" => res := x"E9";
            when x"EC" => res := x"CE";
            when x"ED" => res := x"55";
            when x"EE" => res := x"28";
            when x"EF" => res := x"DF";

            when x"F0" => res := x"8C";
            when x"F1" => res := x"A1";
            when x"F2" => res := x"89";
            when x"F3" => res := x"0D";
            when x"F4" => res := x"BF";
            when x"F5" => res := x"E6";
            when x"F6" => res := x"42";
            when x"F7" => res := x"68";
            when x"F8" => res := x"41";
            when x"F9" => res := x"99";
            when x"FA" => res := x"2D";
            when x"FB" => res := x"0F";
            when x"FC" => res := x"B0";
            when x"FD" => res := x"54";
            when x"FE" => res := x"BB";
            when x"FF" => res := x"16";
            when others => res := x"00";
        end case;
        return res;
    end function;

    function sub_word(w : std_logic_vector(31 downto 0)) return std_logic_vector is
        variable res : std_logic_vector(31 downto 0);
    begin
        res(31 downto 24) := sbox(w(31 downto 24));
        res(23 downto 16) := sbox(w(23 downto 16));
        res(15 downto 8)  := sbox(w(15 downto 8));
        res(7 downto 0)   := sbox(w(7 downto 0));
        return res;
    end function;

    function rot_word(w : std_logic_vector(31 downto 0)) return std_logic_vector is
    begin
        return w(23 downto 0) & w(31 downto 24);
    end function;

    function rcon(i : integer) return std_logic_vector is
        variable res : std_logic_vector(31 downto 0);
    begin
        case i is
            when 1  => res := x"01000000";
            when 2  => res := x"02000000";
            when 3  => res := x"04000000";
            when 4  => res := x"08000000";
            when 5  => res := x"10000000";
            when 6  => res := x"20000000";
            when 7  => res := x"40000000";
            when 8  => res := x"80000000";
            when 9  => res := x"1B000000";
            when 10 => res := x"36000000";
            when others => res := x"00000000";
        end case;
        return res;
    end function;

    function key_expansion(key : std_logic_vector(127 downto 0)) return round_key_array is
        variable w    : word_array;
        variable rk   : round_key_array;
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

        for r in 0 to 10 loop
            rk(r)(0)  := w(4*r)(31 downto 24);
            rk(r)(1)  := w(4*r)(23 downto 16);
            rk(r)(2)  := w(4*r)(15 downto 8);
            rk(r)(3)  := w(4*r)(7 downto 0);
            rk(r)(4)  := w(4*r+1)(31 downto 24);
            rk(r)(5)  := w(4*r+1)(23 downto 16);
            rk(r)(6)  := w(4*r+1)(15 downto 8);
            rk(r)(7)  := w(4*r+1)(7 downto 0);
            rk(r)(8)  := w(4*r+2)(31 downto 24);
            rk(r)(9)  := w(4*r+2)(23 downto 16);
            rk(r)(10) := w(4*r+2)(15 downto 8);
            rk(r)(11) := w(4*r+2)(7 downto 0);
            rk(r)(12) := w(4*r+3)(31 downto 24);
            rk(r)(13) := w(4*r+3)(23 downto 16);
            rk(r)(14) := w(4*r+3)(15 downto 8);
            rk(r)(15) := w(4*r+3)(7 downto 0);
        end loop;
        return rk;
    end function;

    function gf_mul2(a : std_logic_vector(7 downto 0)) return std_logic_vector is
        variable res : std_logic_vector(7 downto 0);
    begin
        if a(7) = '1' then
            res := (a(6 downto 0) & '0') xor x"1B";
        else
            res := a(6 downto 0) & '0';
        end if;
        return res;
    end function;

    function gf_mul3(a : std_logic_vector(7 downto 0)) return std_logic_vector is
    begin
        return gf_mul2(a) xor a;
    end function;

    function sub_bytes(state : byte_array) return byte_array is
        variable res : byte_array;
    begin
        for i in 0 to 15 loop
            res(i) := sbox(state(i));
        end loop;
        return res;
    end function;

    function shift_rows(state : byte_array) return byte_array is
        variable res     : byte_array;
        variable new_idx : integer;
        variable old_idx : integer;
    begin
        for c in 0 to 3 loop
            for r in 0 to 3 loop
                new_idx := 4*c + r;
                old_idx := 4*((c + r) mod 4) + r;
                res(new_idx) := state(old_idx);
            end loop;
        end loop;
        return res;
    end function;

    function mix_columns(state : byte_array) return byte_array is
        variable res : byte_array;
        variable a0, a1, a2, a3 : std_logic_vector(7 downto 0);
        variable b0, b1, b2, b3 : std_logic_vector(7 downto 0);
    begin
        for c in 0 to 3 loop
            a0 := state(4*c+0);
            a1 := state(4*c+1);
            a2 := state(4*c+2);
            a3 := state(4*c+3);
            b0 := gf_mul2(a0) xor gf_mul3(a1) xor a2 xor a3;
            b1 := a0 xor gf_mul2(a1) xor gf_mul3(a2) xor a3;
            b2 := a0 xor a1 xor gf_mul2(a2) xor gf_mul3(a3);
            b3 := gf_mul3(a0) xor a1 xor a2 xor gf_mul2(a3);
            res(4*c+0) := b0;
            res(4*c+1) := b1;
            res(4*c+2) := b2;
            res(4*c+3) := b3;
        end loop;
        return res;
    end function;

    function add_round_key(state : byte_array; rk : byte_array) return byte_array is
        variable res : byte_array;
    begin
        for i in 0 to 15 loop
            res(i) := state(i) xor rk(i);
        end loop;
        return res;
    end function;

    function aes_encrypt(plain : std_logic_vector(127 downto 0); key : std_logic_vector(127 downto 0)) return std_logic_vector is
        variable state   : byte_array;
        variable rk      : round_key_array;
        variable res_vec : std_logic_vector(127 downto 0);
    begin
        state(0)  := plain(127 downto 120);
        state(1)  := plain(119 downto 112);
        state(2)  := plain(111 downto 104);
        state(3)  := plain(103 downto 96);
        state(4)  := plain(95 downto 88);
        state(5)  := plain(87 downto 80);
        state(6)  := plain(79 downto 72);
        state(7)  := plain(71 downto 64);
        state(8)  := plain(63 downto 56);
        state(9)  := plain(55 downto 48);
        state(10) := plain(47 downto 40);
        state(11) := plain(39 downto 32);
        state(12) := plain(31 downto 24);
        state(13) := plain(23 downto 16);
        state(14) := plain(15 downto 8);
        state(15) := plain(7 downto 0);

        rk := key_expansion(key);
        state := add_round_key(state, rk(0));

        for round in 1 to 9 loop
            state := sub_bytes(state);
            state := shift_rows(state);
            state := mix_columns(state);
            state := add_round_key(state, rk(round));
        end loop;

        state := sub_bytes(state);
        state := shift_rows(state);
        state := add_round_key(state, rk(10));

        res_vec(127 downto 120) := state(0);
        res_vec(119 downto 112) := state(1);
        res_vec(111 downto 104) := state(2);
        res_vec(103 downto 96)  := state(3);
        res_vec(95 downto 88)   := state(4);
        res_vec(87 downto 80)   := state(5);
        res_vec(79 downto 72)   := state(6);
        res_vec(71 downto 64)   := state(7);
        res_vec(63 downto 56)   := state(8);
        res_vec(55 downto 48)   := state(9);
        res_vec(47 downto 40)   := state(10);
        res_vec(39 downto 32)   := state(11);
        res_vec(31 downto 24)   := state(12);
        res_vec(23 downto 16)   := state(13);
        res_vec(15 downto 8)    := state(14);
        res_vec(7 downto 0)     := state(15);

        return res_vec;
    end function;

    signal cipher_reg : std_logic_vector(127 downto 0);

begin

    process(clk, rst)
    begin
        if rst = '1' then
            cipher_reg <= (others => '0');
        elsif rising_edge(clk) then
            if EN = '1' then
                cipher_reg <= aes_encrypt(Plain_text, Key_in);
            end if;
        end if;
    end process;

    Cypher_text <= cipher_reg;

end RTL;
