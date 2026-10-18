library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity sha256_core is
  port (
    clk : in std_logic;
    reset_n : in std_logic;
    init : in std_logic;
    next : in std_logic;
    mode : in std_logic;
    block : in std_logic_vector(511 downto 0);
    ready : out std_logic;
    digest_valid : out std_logic;
    digest : out std_logic_vector(255 downto 0)
  );
end sha256_core;

architecture rtl of sha256_core is
  type word_array is array (0 to 63) of std_logic_vector(31 downto 0);
  type state_type is (IDLE, PROCESS);
  constant K : word_array := (
    x"428a2f98", x"71374491", x"b5c0fbcf", x"e9b5dba5",
    x"3956c25b", x"59f111f1", x"923f82a4", x"ab1c5ed5",
    x"d807aa98", x"12835b01", x"243185be", x"550c7dc3",
    x"72be5d74", x"80deb1fe", x"9bdc06a7", x"c19bf174",
    x"e49b69c1", x"efbe4786", x"0fc19dc6", x"240ca1cc",
    x"2de92c6f", x"4a7484aa", x"5cb0a9dc", x"76f988da",
    x"983e5152", x"a831c66d", x"b00327c8", x"bf597fc7",
    x"c6e00bf3", x"d5a79147", x"06ca6351", x"14292967",
    x"27b70a85", x"2e1b2138", x"4d2c6dfc", x"53380d13",
    x"650a7354", x"766a0abb", x"81c2c92e", x"92722c85",
    x"a2bfe8a1", x"a81a664b", x"c24b8b70", x"c76c51a3",
    x"d192e819", x"d6990624", x"f40e3585", x"106aa070",
    x"19a4c116", x"1e376c08", x"2748774c", x"34b0bcb5",
    x"391c0cb3", x"4ed8aa4a", x"5b9cca4f", x"682e6ff3",
    x"748f82ee", x"78a5636f", x"84c87814", x"8cc70208",
    x"90befffa", x"a4506ceb", x"bef9a3f7", x"c67178f2"
  );
  constant H0 : std_logic_vector(31 downto 0) := x"6a09e667";
  constant H1 : std_logic_vector(31 downto 0) := x"bb67ae85";
  constant H2 : std_logic_vector(31 downto 0) := x"3c6ef372";
  constant H3 : std_logic_vector(31 downto 0) := x"a54ff53a";
  constant H4 : std_logic_vector(31 downto 0) := x"510e527f";
  constant H5 : std_logic_vector(31 downto 0) := x"9b05688c";
  constant H6 : std_logic_vector(31 downto 0) := x"1f83d9ab";
  constant H7 : std_logic_vector(31 downto 0) := x"5be0cd19";

  signal W : word_array;
  signal a, b, c, d, e, f, g, h : std_logic_vector(31 downto 0);
  signal h0, h1, h2, h3, h4, h5, h6, h7 : std_logic_vector(31 downto 0);
  signal round_idx : integer range 0 to 63;
  signal state : state_type;
  signal ready_reg : std_logic;
  signal valid_reg : std_logic;

  function rotr(x : std_logic_vector(31 downto 0); n : integer) return std_logic_vector is
  begin
    return x(n-1 downto 0) & x(31 downto n);
  end function;

  function shr(x : std_logic_vector(31 downto 0); n : integer) return std_logic_vector is
  begin
    return (31 downto 32-n => '0') & x(31 downto n);
  end function;

  function Ch(x, y, z : std_logic_vector(31 downto 0)) return std_logic_vector is
  begin
    return (x and y) xor ((not x) and z);
  end function;

  function Maj(x, y, z : std_logic_vector(31 downto 0)) return std_logic_vector is
  begin
    return (x and y) xor (x and z) xor (y and z);
  end function;

  function Sigma0(x : std_logic_vector(31 downto 0)) return std_logic_vector is
  begin
    return rotr(x, 2) xor rotr(x, 13) xor rotr(x, 22);
  end function;

  function Sigma1(x : std_logic_vector(31 downto 0)) return std_logic_vector is
  begin
    return rotr(x, 6) xor rotr(x, 11) xor rotr(x, 25);
  end function;

  function sigma0(x : std_logic_vector(31 downto 0)) return std_logic_vector is
  begin
    return rotr(x, 7) xor rotr(x, 18) xor shr(x, 3);
  end function;

  function sigma1(x : std_logic_vector(31 downto 0)) return std_logic_vector is
  begin
    return rotr(x, 17) xor rotr(x, 19) xor shr(x, 10);
  end function;

begin
  ready <= ready_reg;
  digest_valid <= valid_reg;
  digest <= h0 & h1 & h2 & h3 & h4 & h5 & h6 & h7;

  process(clk, reset_n)
    variable w_t : std_logic_vector(31 downto 0);
    variable t1, t2 : std_logic_vector(31 downto 0);
    variable new_a, new_b, new_c, new_d, new_e, new_f, new_g, new_h : std_logic_vector(31 downto 0);
  begin
    if reset_n = '0' then
      state <= IDLE;
      ready_reg <= '1';
      valid_reg <= '0';
      round_idx <= 0;
      h0 <= H0; h1 <= H1; h2 <= H2; h3 <= H3;
      h4 <= H4; h5 <= H5; h6 <= H6; h7 <= H7;
      a <= (others => '0'); b <= (others => '0'); c <= (others => '0'); d <= (others => '0');
      e <= (others => '0'); f <= (others => '0'); g <= (others => '0'); h <= (others => '0');
      W <= (others => (others => '0'));
    elsif rising_edge(clk) then
      if init = '1' then
        h0 <= H0; h1 <= H1; h2 <= H2; h3 <= H3;
        h4 <= H4; h5 <= H5; h6 <= H6; h7 <= H7;
        a <= H0; b <= H1; c <= H2; d <= H3;
        e <= H4; f <= H5; g <= H6; h <= H7;
        W(0) <= block(511 downto 480);
        W(1) <= block(479 downto 448);
        W(2) <= block(447 downto 416);
        W(3) <= block(415 downto 384);
        W(4) <= block(383 downto 352);
        W(5) <= block(351 downto 320);
        W(6) <= block(319 downto 288);
        W(7) <= block(287 downto 256);
        W(8) <= block(255 downto 224);
        W(9) <= block(223 downto 192);
        W(10) <= block(191 downto 160);
        W(11) <= block(159 downto 128);
        W(12) <= block(127 downto 96);
        W(13) <= block(95 downto 64);
        W(14) <= block(63 downto 32);
        W(15) <= block(31 downto 0);
        round_idx <= 0;
        ready_reg <= '0';
        valid_reg <= '0';
        state <= PROCESS;
      elsif next = '1' and state = IDLE then
        a <= h0; b <= h1; c <= h2; d <= h3;
        e <= h4; f <= h5; g <= h6; h <= h7;
        W(0) <= block(511 downto 480);
        W(1) <= block(479 downto 448);
        W(2) <= block(447 downto 416);
        W(3) <= block(415 downto 384);
        W(4) <= block(383 downto 352);
        W(5) <= block(351 downto 320);
        W(6) <= block(319 downto 288);
        W(7) <= block(287 downto 256);
        W(8) <= block(255 downto 224);
        W(9) <= block(223 downto 192);
        W(10) <= block(191 downto 160);
        W(11) <= block(159 downto 128);
        W(12) <= block(127 downto 96);
        W(13) <= block(95 downto 64);
        W(14) <= block(63 downto 32);
        W(15) <= block(31 downto 0);
        round_idx <= 0;
        ready_reg <= '0';
        valid_reg <= '0';
        state <= PROCESS;
      elsif state = PROCESS then
        if round_idx >= 16 then
          w_t := std_logic_vector(unsigned(sigma1(W(round_idx-2))) + unsigned(W(round_idx-7)) + unsigned(sigma0(W(round_idx-15))) + unsigned(W(round_idx-16)));
          W(round_idx) <= w_t;
        else
          w_t := W(round_idx);
        end if;

        t1 := std_logic_vector(unsigned(h) + unsigned(Sigma1(e)) + unsigned(Ch(e, f, g)) + unsigned(K(round_idx)) + unsigned(w_t));
        t2 := std_logic_vector(unsigned(Sigma0(a)) + unsigned(Maj(a, b, c)));

        new_h := g;
        new_g := f;
        new_f := e;
        new_e := std_logic_vector(unsigned(d) + unsigned(t1));
        new_d := c;
        new_c := b;
        new_b := a;
        new_a := std_logic_vector(unsigned(t1) + unsigned(t2));

        if round_idx = 63 then
          h0 <= std_logic_vector(unsigned(h0) + unsigned(new_a));
          h1 <= std_logic_vector(unsigned(h1) + unsigned(new_b));
          h2 <= std_logic_vector(unsigned(h2) + unsigned(new_c));
          h3 <= std_logic_vector(unsigned(h3) + unsigned(new_d));
          h4 <= std_logic_vector(unsigned(h4) + unsigned(new_e));
          h5 <= std_logic_vector(unsigned(h5) + unsigned(new_f));
          h6 <= std_logic_vector(unsigned(h6) + unsigned(new_g));
          h7 <= std_logic_vector(unsigned(h7) + unsigned(new_h));
          ready_reg <= '1';
          valid_reg <= '1';
          state <= IDLE;
          round_idx <= 0;
        else
          a <= new_a;
          b <= new_b;
          c <= new_c;
          d <= new_d;
          e <= new_e;
          f <= new_f;
          g <= new_g;
          h <= new_h;
          round_idx <= round_idx + 1;
        end if;
      end if;
    end if;
  end process;
end rtl;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity sha256 is
  port (
    clk : in std_logic;
    reset_n : in std_logic;
    cs : in std_logic;
    we : in std_logic;
    address : in std_logic_vector(7 downto 0);
    write_data : in std_logic_vector(31 downto 0);
    read_data : out std_logic_vector(31 downto 0);
    error : out std_logic
  );
end sha256;

architecture rtl of sha256 is
  type block_array is array (0 to 15) of std_logic_vector(31 downto 0);

  constant NAME0 : std_logic_vector(31 downto 0) := x"5348412D";
  constant NAME1 : std_logic_vector(31 downto 0) := x"32353620";
  constant VERSION : std_logic_vector(31 downto 0) := x"00010000";

  signal block_reg : block_array := (others => (others => '0'));
  signal mode_reg : std_logic := '0';
  signal core_init : std_logic := '0';
  signal core_next : std_logic := '0';
  signal core_block : std_logic_vector(511 downto 0);
  signal core_ready : std_logic;
  signal core_valid : std_logic;
  signal core_digest : std_logic_vector(255 downto 0);

begin
  core_block <= block_reg(0) & block_reg(1) & block_reg(2) & block_reg(3) &
                block_reg(4) & block_reg(5) & block_reg(6) & block_reg(7) &
                block_reg(8) & block_reg(9) & block_reg(10) & block_reg(11) &
                block_reg(12) & block_reg(13) & block_reg(14) & block_reg(15);

  u_core : entity work.sha256_core
    port map (
      clk => clk,
      reset_n => reset_n,
      init => core_init,
      next => core_next,
      mode => mode_reg,
      block => core_block,
      ready => core_ready,
      digest_valid => core_valid,
      digest => core_digest
    );

  process(cs, we, address, core_ready, core_valid, core_digest, mode_reg, block_reg)
  begin
    read_data <= (others => '0');
    if cs = '1' and we = '0' then
      case address is
        when x"00" => read_data <= NAME0;
        when x"01" => read_data <= NAME1;
        when x"02" => read_data <= VERSION;
        when x"08" => read_data <= (2 => mode_reg, others => '0');
        when x"09" => read_data <= (0 => core_ready, 1 => core_valid, others => '0');
        when x"10" => read_data <= block_reg(0);
        when x"11" => read_data <= block_reg(1);
        when x"12" => read_data <= block_reg(2);
        when x"13" => read_data <= block_reg(3);
        when x"14" => read_data <= block_reg(4);
        when x"15" => read_data <= block_reg(5);
        when x"16" => read_data <= block_reg(6);
        when x"17" => read_data <= block_reg(7);
        when x"18" => read_data <= block_reg(8);
        when x"19" => read_data <= block_reg(9);
        when x"1A" => read_data <= block_reg(10);
        when x"1B" => read_data <= block_reg(11);
        when x"1C" => read_data <= block_reg(12);
        when x"1D" => read_data <= block_reg(13);
        when x"1E" => read_data <= block_reg(14);
        when x"1F" => read_data <= block_reg(15);
        when x"20" => read_data <= core_digest(255 downto 224);
        when x"21" => read_data <= core_digest(223 downto 192);
        when x"22" => read_data <= core_digest(191 downto 160);
        when x"23" => read_data <= core_digest(159 downto 128);
        when x"24" => read_data <= core_digest(127 downto 96);
        when x"25" => read_data <= core_digest(95 downto 64);
        when x"26" => read_data <= core_digest(63 downto 32);
        when x"27" => read_data <= core_digest(31 downto 0);
        when others => read_data <= (others => '0');
      end case;
    end if;
  end process;

  process(cs, address)
  begin
    error <= '0';
    if cs = '1' then
      case address is
        when x"00" | x"01" | x"02" | x"08" | x"09" |
             x"10" | x"11" | x"12" | x"13" | x"14" | x"15" | x"16" | x"17" |
             x"18" | x"19" | x"1A" | x"1B" | x"1C" | x"1D" | x"1E" | x"1F" |
             x"20" | x"21" | x"22" | x"23" | x"24" | x"25" | x"26" | x"27" =>
          error <= '0';
        when others =>
          error <= '1';
      end case;
    end if;
  end process;

  process(clk, reset_n)
  begin
    if reset_n = '0' then
      block_reg <= (others => (others => '0'));
      mode_reg <= '0';
      core_init <= '0';
      core_next <= '0';
    elsif rising_edge(clk) then
      core_init <= '0';
      core_next <= '0';
      if cs = '1' and we = '1' then
        case address is
          when x"08" =>
            mode_reg <= write_data(2);
            if write_data(0) = '1' then
              core_init <= '1';
            end if;
            if write_data(1) = '1' then
              core_next <= '1';
            end if;
          when x"10" => block_reg(0) <= write_data;
          when x"11" => block_reg(1) <= write_data;
          when x"12" => block_reg(2) <= write_data;
          when x"13" => block_reg(3) <= write_data;
          when x"14" => block_reg(4) <= write_data;
          when x"15" => block_reg(5) <= write_data;
          when x"16" => block_reg(6) <= write_data;
          when x"17" => block_reg(7) <= write_data;
          when x"18" => block_reg(8) <= write_data;
          when x"19" => block_reg(9) <= write_data;
          when x"1A" => block_reg(10) <= write_data;
          when x"1B" => block_reg(11) <= write_data;
          when x"1C" => block_reg(12) <= write_data;
          when x"1D" => block_reg(13) <= write_data;
          when x"1E" => block_reg(14) <= write_data;
          when x"1F" => block_reg(15) <= write_data;
          when others => null;
        end case;
      end if;
    end if;
  end process;
end rtl;
