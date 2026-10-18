library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity AES_Encrypt is
  Port (
    clk : in std_logic;
    rst : in std_logic;
    Plain_text : in std_logic_vector(127 downto 0);
    EN : in std_logic;
    Key_in : in std_logic_vector(127 downto 0);
    Cypher_text : out std_logic_vector(127 downto 0)
  );
end AES_Encrypt;

architecture rtl of AES_Encrypt is
  subtype byte is std_logic_vector(7 downto 0);
  type byte_array_16 is array (0 to 15) of byte;
  type sbox_array is array (0 to 255) of byte;

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

  constant ZERO_BYTES : byte_array_16 := (others => (others => '0'));

  function vec_to_bytes(v : std_logic_vector(127 downto 0)) return byte_array_16 is
    variable b : byte_array_16;
  begin
    for i in 0 to 15 loop
      for j in 0 to 7 loop
        b(i)(j) := v(120 - 8*i + j);
      end loop;
    end loop;
    return b;
  end function;

  function bytes_to_vec(b : byte_array_16) return std_logic_vector(127 downto 0) is
    variable v : std_logic_vector(127 downto 0);
  begin
    for i in 0 to 15 loop
      for j in 0 to 7 loop
        v(120 - 8*i + j) := b(i)(j);
      end loop;
    end loop;
    return v;
  end function;

  function sbox(x : byte) return byte is
  begin
    return SBOX(to_integer(unsigned(x)));
  end function;

  function sub_bytes(s : byte_array_16) return byte_array_16 is
    variable res : byte_array_16;
  begin
    for i in 0 to 15 loop
      res(i) := sbox(s(i));
    end loop;
    return res;
  end function;

  function shift_rows(s : byte_array_16) return byte_array_16 is
    variable res : byte_array_16;
  begin
    for c_idx in 0 to 3 loop
      for r_idx in 0 to 3 loop
        res(r_idx + 4*c_idx) := s(r_idx + 4*((c_idx + r_idx) mod 4));
      end loop;
    end loop;
    return res;
  end function;

  function xtime(x : byte) return byte is
    variable y : byte;
  begin
    if x(7) = '1' then
      y := (x(6 downto 0) & '0') xor x"1B";
    else
      y := x(6 downto 0) & '0';
    end if;
    return y;
  end function;

  function mul2(x : byte) return byte is
  begin
    return xtime(x);
  end function;

  function mul3(x : byte) return byte is
  begin
    return xtime(x) xor x;
  end function;

  function mix_columns(s : byte_array_16) return byte_array_16 is
    variable res : byte_array_16;
    variable a0, a1, a2, a3 : byte;
    variable b0, b1, b2, b3 : byte;
  begin
    for c_idx in 0 to 3 loop
      a0 := s(4*c_idx + 0);
      a1 := s(4*c_idx + 1);
      a2 := s(4*c_idx + 2);
      a3 := s(4*c_idx + 3);
      b0 := mul2(a0) xor mul3(a1) xor a2 xor a3;
      b1 := a0 xor mul2(a1) xor mul3(a2) xor a3;
      b2 := a0 xor a1 xor mul2(a2) xor mul3(a3);
      b3 := mul3(a0) xor a1 xor a2 xor mul2(a3);
      res(4*c_idx + 0) := b0;
      res(4*c_idx + 1) := b1;
      res(4*c_idx + 2) := b2;
      res(4*c_idx + 3) := b3;
    end loop;
    return res;
  end function;

  function add_round_key(s : byte_array_16; key : byte_array_16) return byte_array_16 is
    variable res : byte_array_16;
  begin
    for i in 0 to 15 loop
      res(i) := s(i) xor key(i);
    end loop;
    return res;
  end function;

  function key_expansion_round(key : byte_array_16; rcon : byte) return byte_array_16 is
    variable t0, t1, t2, t3 : byte;
    variable nk : byte_array_16;
  begin
    t0 := sbox(key(13));
    t1 := sbox(key(14));
    t2 := sbox(key(15));
    t3 := sbox(key(12));
    t0 := t0 xor rcon;
    nk(0) := key(0) xor t0;
    nk(1) := key(1) xor t1;
    nk(2) := key(2) xor t2;
    nk(3) := key(3) xor t3;
    nk(4) := key(4) xor nk(0);
    nk(5) := key(5) xor nk(1);
    nk(6) := key(6) xor nk(2);
    nk(7) := key(7) xor nk(3);
    nk(8) := key(8) xor nk(4);
    nk(9) := key(9) xor nk(5);
    nk(10) := key(10) xor nk(6);
    nk(11) := key(11) xor nk(7);
    nk(12) := key(12) xor nk(8);
    nk(13) := key(13) xor nk(9);
    nk(14) := key(14) xor nk(10);
    nk(15) := key(15) xor nk(11);
    return nk;
  end function;

  function next_rcon(r : byte) return byte is
  begin
    if r = x"01" then
      return x"02";
    elsif r = x"02" then
      return x"04";
    elsif r = x"04" then
      return x"08";
    elsif r = x"08" then
      return x"10";
    elsif r = x"10" then
      return x"20";
    elsif r = x"20" then
      return x"40";
    elsif r = x"40" then
      return x"80";
    elsif r = x"80" then
      return x"1B";
    elsif r = x"1B" then
      return x"36";
    else
      return x"00";
    end if;
  end function;

  type pipeline_state_array is array (0 to 10) of byte_array_16;
  type pipeline_rcon_array is array (0 to 10) of byte;
  signal stage_state : pipeline_state_array;
  signal stage_key : pipeline_state_array;
  signal stage_rcon : pipeline_rcon_array;
  signal stage_valid : std_logic_vector(0 to 10);

begin
  process(clk, rst)
  begin
    if rst = '1' then
      for i in 0 to 10 loop
        stage_state(i) <= ZERO_BYTES;
        stage_key(i) <= ZERO_BYTES;
        stage_rcon(i) <= (others => '0');
      end loop;
      stage_valid <= (others => '0');
    elsif rising_edge(clk) then
      if EN = '1' then
        stage_state(0) <= add_round_key(vec_to_bytes(Plain_text), vec_to_bytes(Key_in));
        stage_key(0) <= key_expansion_round(vec_to_bytes(Key_in), x"01");
        stage_rcon(0) <= x"02";
        stage_valid(0) <= '1';
      else
        stage_state(0) <= ZERO_BYTES;
        stage_key(0) <= ZERO_BYTES;
        stage_rcon(0) <= (others => '0');
        stage_valid(0) <= '0';
      end if;

      for i in 1 to 9 loop
        stage_state(i) <= add_round_key(mix_columns(shift_rows(sub_bytes(stage_state(i-1)))), stage_key(i-1));
        stage_key(i) <= key_expansion_round(stage_key(i-1), stage_rcon(i-1));
        stage_rcon(i) <= next_rcon(stage_rcon(i-1));
        stage_valid(i) <= stage_valid(i-1);
      end loop;

      stage_state(10) <= add_round_key(shift_rows(sub_bytes(stage_state(9))), stage_key(9));
      stage_valid(10) <= stage_valid(9);
      stage_key(10) <= ZERO_BYTES;
      stage_rcon(10) <= (others => '0');
    end if;
  end process;

  Cypher_text <= bytes_to_vec(stage_state(10));
end rtl;
