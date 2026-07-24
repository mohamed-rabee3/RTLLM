library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity verified_AES_Encrypt is
    port(clk         : in  std_logic;
         rst         : in  std_logic;
         Plain_text  : in  std_logic_vector(127 downto 0);
         EN          : in  std_logic;
         Key_in      : in  std_logic_vector(127 downto 0);
         Cypher_text : out std_logic_vector(127 downto 0));
end verified_AES_Encrypt;

architecture rtl of verified_AES_Encrypt is
    type word_arr is array(0 to 43) of std_logic_vector(31 downto 0);

    function sbox(x : std_logic_vector(7 downto 0)) return std_logic_vector is
        variable r : std_logic_vector(7 downto 0);
    begin
        case x is
            when x"00" => r := x"63"; when x"01" => r := x"7c"; when x"02" => r := x"77"; when x"03" => r := x"7b"; when x"04" => r := x"f2"; when x"05" => r := x"6b"; when x"06" => r := x"6f"; when x"07" => r := x"c5";
            when x"08" => r := x"30"; when x"09" => r := x"01"; when x"0a" => r := x"67"; when x"0b" => r := x"2b"; when x"0c" => r := x"fe"; when x"0d" => r := x"d7"; when x"0e" => r := x"ab"; when x"0f" => r := x"76";
            when x"10" => r := x"ca"; when x"11" => r := x"82"; when x"12" => r := x"c9"; when x"13" => r := x"7d"; when x"14" => r := x"fa"; when x"15" => r := x"59"; when x"16" => r := x"47"; when x"17" => r := x"f0";
            when x"18" => r := x"ad"; when x"19" => r := x"d4"; when x"1a" => r := x"a2"; when x"1b" => r := x"af"; when x"1c" => r := x"9c"; when x"1d" => r := x"a4"; when x"1e" => r := x"72"; when x"1f" => r := x"c0";
            when x"20" => r := x"b7"; when x"21" => r := x"fd"; when x"22" => r := x"93"; when x"23" => r := x"26"; when x"24" => r := x"36"; when x"25" => r := x"3f"; when x"26" => r := x"f7"; when x"27" => r := x"cc";
            when x"28" => r := x"34"; when x"29" => r := x"a5"; when x"2a" => r := x"e5"; when x"2b" => r := x"f1"; when x"2c" => r := x"71"; when x"2d" => r := x"d8"; when x"2e" => r := x"31"; when x"2f" => r := x"15";
            when x"30" => r := x"04"; when x"31" => r := x"c7"; when x"32" => r := x"23"; when x"33" => r := x"c3"; when x"34" => r := x"18"; when x"35" => r := x"96"; when x"36" => r := x"05"; when x"37" => r := x"9a";
            when x"38" => r := x"07"; when x"39" => r := x"12"; when x"3a" => r := x"80"; when x"3b" => r := x"e2"; when x"3c" => r := x"eb"; when x"3d" => r := x"27"; when x"3e" => r := x"b2"; when x"3f" => r := x"75";
            when x"40" => r := x"09"; when x"41" => r := x"83"; when x"42" => r := x"2c"; when x"43" => r := x"1a"; when x"44" => r := x"1b"; when x"45" => r := x"6e"; when x"46" => r := x"5a"; when x"47" => r := x"a0";
            when x"48" => r := x"52"; when x"49" => r := x"3b"; when x"4a" => r := x"d6"; when x"4b" => r := x"b3"; when x"4c" => r := x"29"; when x"4d" => r := x"e3"; when x"4e" => r := x"2f"; when x"4f" => r := x"84";
            when x"50" => r := x"53"; when x"51" => r := x"d1"; when x"52" => r := x"00"; when x"53" => r := x"ed"; when x"54" => r := x"20"; when x"55" => r := x"fc"; when x"56" => r := x"b1"; when x"57" => r := x"5b";
            when x"58" => r := x"6a"; when x"59" => r := x"cb"; when x"5a" => r := x"be"; when x"5b" => r := x"39"; when x"5c" => r := x"4a"; when x"5d" => r := x"4c"; when x"5e" => r := x"58"; when x"5f" => r := x"cf";
            when x"60" => r := x"d0"; when x"61" => r := x"ef"; when x"62" => r := x"aa"; when x"63" => r := x"fb"; when x"64" => r := x"43"; when x"65" => r := x"4d"; when x"66" => r := x"33"; when x"67" => r := x"85";
            when x"68" => r := x"45"; when x"69" => r := x"f9"; when x"6a" => r := x"02"; when x"6b" => r := x"7f"; when x"6c" => r := x"50"; when x"6d" => r := x"3c"; when x"6e" => r := x"9f"; when x"6f" => r := x"a8";
            when x"70" => r := x"51"; when x"71" => r := x"a3"; when x"72" => r := x"40"; when x"73" => r := x"8f"; when x"74" => r := x"92"; when x"75" => r := x"9d"; when x"76" => r := x"38"; when x"77" => r := x"f5";
            when x"78" => r := x"bc"; when x"79" => r := x"b6"; when x"7a" => r := x"da"; when x"7b" => r := x"21"; when x"7c" => r := x"10"; when x"7d" => r := x"ff"; when x"7e" => r := x"f3"; when x"7f" => r := x"d2";
            when x"80" => r := x"cd"; when x"81" => r := x"0c"; when x"82" => r := x"13"; when x"83" => r := x"ec"; when x"84" => r := x"5f"; when x"85" => r := x"97"; when x"86" => r := x"44"; when x"87" => r := x"17";
            when x"88" => r := x"c4"; when x"89" => r := x"a7"; when x"8a" => r := x"7e"; when x"8b" => r := x"3d"; when x"8c" => r := x"64"; when x"8d" => r := x"5d"; when x"8e" => r := x"19"; when x"8f" => r := x"73";
            when x"90" => r := x"60"; when x"91" => r := x"81"; when x"92" => r := x"4f"; when x"93" => r := x"dc"; when x"94" => r := x"22"; when x"95" => r := x"2a"; when x"96" => r := x"90"; when x"97" => r := x"88";
            when x"98" => r := x"46"; when x"99" => r := x"ee"; when x"9a" => r := x"b8"; when x"9b" => r := x"14"; when x"9c" => r := x"de"; when x"9d" => r := x"5e"; when x"9e" => r := x"0b"; when x"9f" => r := x"db";
            when x"a0" => r := x"e0"; when x"a1" => r := x"32"; when x"a2" => r := x"3a"; when x"a3" => r := x"0a"; when x"a4" => r := x"49"; when x"a5" => r := x"06"; when x"a6" => r := x"24"; when x"a7" => r := x"5c";
            when x"a8" => r := x"c2"; when x"a9" => r := x"d3"; when x"aa" => r := x"ac"; when x"ab" => r := x"62"; when x"ac" => r := x"91"; when x"ad" => r := x"95"; when x"ae" => r := x"e4"; when x"af" => r := x"79";
            when x"b0" => r := x"e7"; when x"b1" => r := x"c8"; when x"b2" => r := x"37"; when x"b3" => r := x"6d"; when x"b4" => r := x"8d"; when x"b5" => r := x"d5"; when x"b6" => r := x"4e"; when x"b7" => r := x"a9";
            when x"b8" => r := x"6c"; when x"b9" => r := x"56"; when x"ba" => r := x"f4"; when x"bb" => r := x"ea"; when x"bc" => r := x"65"; when x"bd" => r := x"7a"; when x"be" => r := x"ae"; when x"bf" => r := x"08";
            when x"c0" => r := x"ba"; when x"c1" => r := x"78"; when x"c2" => r := x"25"; when x"c3" => r := x"2e"; when x"c4" => r := x"1c"; when x"c5" => r := x"a6"; when x"c6" => r := x"b4"; when x"c7" => r := x"c6";
            when x"c8" => r := x"e8"; when x"c9" => r := x"dd"; when x"ca" => r := x"74"; when x"cb" => r := x"1f"; when x"cc" => r := x"4b"; when x"cd" => r := x"bd"; when x"ce" => r := x"8b"; when x"cf" => r := x"8a";
            when x"d0" => r := x"70"; when x"d1" => r := x"3e"; when x"d2" => r := x"b5"; when x"d3" => r := x"66"; when x"d4" => r := x"48"; when x"d5" => r := x"03"; when x"d6" => r := x"f6"; when x"d7" => r := x"0e";
            when x"d8" => r := x"61"; when x"d9" => r := x"35"; when x"da" => r := x"57"; when x"db" => r := x"b9"; when x"dc" => r := x"86"; when x"dd" => r := x"c1"; when x"de" => r := x"1d"; when x"df" => r := x"9e";
            when x"e0" => r := x"e1"; when x"e1" => r := x"f8"; when x"e2" => r := x"98"; when x"e3" => r := x"11"; when x"e4" => r := x"69"; when x"e5" => r := x"d9"; when x"e6" => r := x"8e"; when x"e7" => r := x"94";
            when x"e8" => r := x"9b"; when x"e9" => r := x"1e"; when x"ea" => r := x"87"; when x"eb" => r := x"e9"; when x"ec" => r := x"ce"; when x"ed" => r := x"55"; when x"ee" => r := x"28"; when x"ef" => r := x"df";
            when x"f0" => r := x"8c"; when x"f1" => r := x"a1"; when x"f2" => r := x"89"; when x"f3" => r := x"0d"; when x"f4" => r := x"bf"; when x"f5" => r := x"e6"; when x"f6" => r := x"42"; when x"f7" => r := x"68";
            when x"f8" => r := x"41"; when x"f9" => r := x"99"; when x"fa" => r := x"2d"; when x"fb" => r := x"0f"; when x"fc" => r := x"b0"; when x"fd" => r := x"54"; when x"fe" => r := x"bb"; when x"ff" => r := x"16";
            when others => r := x"00";
        end case;
        return r;
    end function;

    function xtime(x : std_logic_vector(7 downto 0)) return std_logic_vector is
        variable t : std_logic_vector(7 downto 0);
    begin
        t := x(6 downto 0) & '0';
        if x(7) = '1' then
            t := t xor x"1b";
        end if;
        return t;
    end function;

    function rcon(j : integer) return std_logic_vector is
        variable r : std_logic_vector(7 downto 0);
    begin
        case j is
            when 1 => r := x"01"; when 2 => r := x"02"; when 3 => r := x"04";
            when 4 => r := x"08"; when 5 => r := x"10"; when 6 => r := x"20";
            when 7 => r := x"40"; when 8 => r := x"80"; when 9 => r := x"1b";
            when 10 => r := x"36"; when others => r := x"00";
        end case;
        return r;
    end function;

    function SubBytes(v : std_logic_vector(127 downto 0)) return std_logic_vector is
        variable o : std_logic_vector(127 downto 0);
    begin
        for k in 0 to 15 loop
            o(8*(15-k)+7 downto 8*(15-k)) := sbox(v(8*(15-k)+7 downto 8*(15-k)));
        end loop;
        return o;
    end function;

    function ShiftRows(v : std_logic_vector(127 downto 0)) return std_logic_vector is
        variable o : std_logic_vector(127 downto 0);
        variable dst, src : integer;
    begin
        for c in 0 to 3 loop
            for r in 0 to 3 loop
                dst := 4*c + r;
                src := 4*((c+r) mod 4) + r;
                o(8*(15-dst)+7 downto 8*(15-dst)) := v(8*(15-src)+7 downto 8*(15-src));
            end loop;
        end loop;
        return o;
    end function;

    function MixColumns(v : std_logic_vector(127 downto 0)) return std_logic_vector is
        variable o : std_logic_vector(127 downto 0);
        variable a0, a1, a2, a3 : std_logic_vector(7 downto 0);
    begin
        for c in 0 to 3 loop
            a0 := v(8*(15-(4*c+0))+7 downto 8*(15-(4*c+0)));
            a1 := v(8*(15-(4*c+1))+7 downto 8*(15-(4*c+1)));
            a2 := v(8*(15-(4*c+2))+7 downto 8*(15-(4*c+2)));
            a3 := v(8*(15-(4*c+3))+7 downto 8*(15-(4*c+3)));
            o(8*(15-(4*c+0))+7 downto 8*(15-(4*c+0))) := xtime(a0) xor (xtime(a1) xor a1) xor a2 xor a3;
            o(8*(15-(4*c+1))+7 downto 8*(15-(4*c+1))) := a0 xor xtime(a1) xor (xtime(a2) xor a2) xor a3;
            o(8*(15-(4*c+2))+7 downto 8*(15-(4*c+2))) := a0 xor a1 xor xtime(a2) xor (xtime(a3) xor a3);
            o(8*(15-(4*c+3))+7 downto 8*(15-(4*c+3))) := (xtime(a0) xor a0) xor a1 xor a2 xor xtime(a3);
        end loop;
        return o;
    end function;

begin
    process(Plain_text, Key_in)
        variable w    : word_arr;
        variable temp : std_logic_vector(31 downto 0);
        variable st   : std_logic_vector(127 downto 0);
    begin
        w(0) := Key_in(127 downto 96);
        w(1) := Key_in(95 downto 64);
        w(2) := Key_in(63 downto 32);
        w(3) := Key_in(31 downto 0);
        for i in 4 to 43 loop
            temp := w(i-1);
            if (i mod 4) = 0 then
                temp := temp(23 downto 0) & temp(31 downto 24);
                temp := sbox(temp(31 downto 24)) & sbox(temp(23 downto 16)) & sbox(temp(15 downto 8)) & sbox(temp(7 downto 0));
                temp := temp xor (rcon(i/4) & x"000000");
            end if;
            w(i) := w(i-4) xor temp;
        end loop;

        st := Plain_text xor (w(0) & w(1) & w(2) & w(3));
        for r in 1 to 9 loop
            st := SubBytes(st);
            st := ShiftRows(st);
            st := MixColumns(st);
            st := st xor (w(4*r) & w(4*r+1) & w(4*r+2) & w(4*r+3));
        end loop;
        st := SubBytes(st);
        st := ShiftRows(st);
        st := st xor (w(40) & w(41) & w(42) & w(43));

        Cypher_text <= st;
    end process;
end rtl;
