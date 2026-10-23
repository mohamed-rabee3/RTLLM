library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity sha256_core is
  port (
    clk          : in  std_logic;
    reset_n      : in  std_logic;
    init         : in  std_logic;
    next         : in  std_logic;
    mode         : in  std_logic;
    block        : in  std_logic_vector(511 downto 0);
    ready        : out std_logic;
    digest_valid : out std_logic;
    digest       : out std_logic_vector(255 downto 0)
  );
end sha256_core;

architecture rtl of sha256_core is
  type state_t is (IDLE, EXPAND, ROUND, DONE);
  type word_array is array (0 to 63) of std_logic_vector(31 downto 0);
  type k_array is array (0 to 63) of std_logic_vector(31 downto 0);

  constant K : k_array := (
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

  constant H0_INIT : std_logic_vector(31 downto 0) := x"6a09e667";
  constant H1_INIT : std_logic_vector(31 downto 0) := x"bb67ae85";
  constant H2_INIT : std_logic_vector(31 downto 0) := x"3c6ef372";
  constant H3_INIT : std_logic_vector(31 downto 0) := x"a54ff53a";
  constant H4_INIT : std_logic_vector(31 downto 0) := x"510e527f";
  constant H5_INIT : std_logic_vector(31 downto 0) := x"9b05688c";
  constant H6_INIT : std_logic_vector(31 downto 0) := x"1f83d9ab";
  constant H7_INIT : std_logic_vector(31 downto 0) := x"5be0cd19";

  function rotr(x : std_logic_vector(31 downto 0); n : integer) return std_logic_vector is
    variable r : std_logic_vector(31 downto 0);
  begin
    if n = 0 then
      r := x;
    else
      r := x(n-1 downto 0) & x(31 downto n);
    end if;
    return r;
  end function;

  function shr(x : std_logic_vector(31 downto 0); n : integer) return std_logic_vector is
    variable r : std_logic_vector(31 downto 0) := (others => '0');
  begin
    if n = 0 then
      r := x;
    else
      r(31-n downto 0) := x(31 downto n);
    end if;
    return r;
  end function;

  function ch(x, y, z : std_logic_vector(31 downto 0)) return std_logic_vector is
  begin
    return (x and y) xor ((not x) and z);
  end function;

  function maj(x, y, z : std_logic_vector(31 downto 0)) return std_logic_vector is
  begin
    return (x and y) xor (x and z) xor (y and z);
  end function;

  function big_sigma0(x : std_logic_vector(31 downto 0)) return std_logic_vector is
  begin
    return rotr(x, 2) xor rotr(x, 13) xor rotr(x, 22);
  end function;

  function big_sigma1(x : std_logic_vector(31 downto 0)) return std_logic_vector is
  begin
    return rotr(x, 6) xor rotr(x, 11) xor rotr(x, 25);
  end function;

  function small_sigma0(x : std_logic_vector(31 downto 0)) return std_logic_vector is
  begin
    return rotr(x, 7) xor rotr(x, 18) xor shr(x, 3);
  end function;

  function small_sigma1(x : std_logic_vector(31 downto 0)) return std_logic_vector is
  begin
    return rotr(x, 17) xor rotr(x, 19) xor shr(x, 10);
  end function;

  signal state        : state_t;
  signal w            : word_array;
  signal a, b, c, d, e, f, g, h : std_logic_vector(31 downto 0);
  signal h0, h1, h2, h3, h4, h5, h6, h7 : std_logic_vector(31 downto 0);
  signal round_idx    : integer range 0 to 63;
  signal w_idx        : integer range 0 to 63;
  signal digest_reg   : std_logic_vector(255 downto 0);
  signal ready_reg    : std_logic;
  signal digest_valid_reg : std_logic;

begin
  digest       <= digest_reg;
  ready        <= ready_reg;
  digest_valid <= digest_valid_reg;

  process(clk, reset_n)
    variable v_a, v_b, v_c, v_d, v_e, v_f, v_g, v_h : std_logic_vector(31 downto 0);
    variable v_t1, v_t2 : std_logic_vector(31 downto 0);
  begin
    if reset_n = '0' then
      state             <= IDLE;
      ready_reg         <= '1';
      digest_valid_reg  <= '0';
      digest_reg        <= H0_INIT & H1_INIT & H2_INIT & H3_INIT &
                           H4_INIT & H5_INIT & H6_INIT & H7_INIT;
      a <= H0_INIT; b <= H1_INIT; c <= H2_INIT; d <= H3_INIT;
      e <= H4_INIT; f <= H5_INIT; g <= H6_INIT; h <= H7_INIT;
      h0 <= H0_INIT; h1 <= H1_INIT; h2 <= H2_INIT; h3 <= H3_INIT;
      h4 <= H4_INIT; h5 <= H5_INIT; h6 <= H6_INIT; h7 <= H7_INIT;
      round_idx <= 0;
      w_idx     <= 0;
      for i in 0 to 63 loop
        w(i) <= (others => '0');
      end loop;
    elsif rising_edge(clk) then
      digest_valid_reg <= '0';
      case state is
        when IDLE =>
          ready_reg <= '1';
          if init = '1' or next = '1' then
            w(0)  <= block(511 downto 480);
            w(1)  <= block(479 downto 448);
            w(2)  <= block(447 downto 416);
            w(3)  <= block(415 downto 384);
            w(4)  <= block(383 downto 352);
            w(5)  <= block(351 downto 320);
            w(6)  <= block(319 downto 288);
            w(7)  <= block(287 downto 256);
            w(8)  <= block(255 downto 224);
            w(9)  <= block(223 downto 192);
            w(10) <= block(191 downto 160);
            w(11) <= block(159 downto 128);
            w(12) <= block(127 downto 96);
            w(13) <= block(95 downto 64);
            w(14) <= block(63 downto 32);
            w(15) <= block(31 downto 0);

            if init = '1' then
              a <= H0_INIT; b <= H1_INIT; c <= H2_INIT; d <= H3_INIT;
              e <= H4_INIT; f <= H5_INIT; g <= H6_INIT; h <= H7_INIT;
              h0 <= H0_INIT; h1 <= H1_INIT; h2 <= H2_INIT; h3 <= H3_INIT;
              h4 <= H4_INIT; h5 <= H5_INIT; h6 <= H6_INIT; h7 <= H7_INIT;
            else
              a <= digest_reg(255 downto 224);
              b <= digest_reg(223 downto 192);
              c <= digest_reg(191 downto 160);
              d <= digest_reg(159 downto 128);
              e <= digest_reg(127 downto 96);
              f <= digest_reg(95 downto 64);
              g <= digest_reg(63 downto 32);
              h <= digest_reg(31 downto 0);
              h0 <= digest_reg(255 downto 224);
              h1 <= digest_reg(223 downto 192);
              h2 <= digest_reg(191 downto 160);
              h3 <= digest_reg(159 downto 128);
              h4 <= digest_reg(127 downto 96);
              h5 <= digest_reg(95 downto 64);
              h6 <= digest_reg(63 downto 32);
              h7 <= digest_reg(31 downto 0);
            end if;

            w_idx    <= 16;
            round_idx <= 0;
            ready_reg <= '0';
            state    <= EXPAND;
          end if;

        when EXPAND =>
          if w_idx <= 63 then
            w(w_idx) <= std_logic_vector(
              unsigned(small_sigma1(w(w_idx-2))) +
              unsigned(w(w_idx-7)) +
              unsigned(small_sigma0(w(w_idx-15))) +
              unsigned(w(w_idx-16))
            );
            if w_idx = 63 then
              state <= ROUND;
            else
              w_idx <= w_idx + 1;
            end if;
          end if;

        when ROUND =>
          v_t1 := std_logic_vector(
            unsigned(h) +
            unsigned(big_sigma1(e)) +
            unsigned(ch(e, f, g)) +
            unsigned(K(round_idx)) +
            unsigned(w(round_idx))
          );
          v_t2 := std_logic_vector(
            unsigned(big_sigma0(a)) +
            unsigned(maj(a, b, c))
          );

          v_h := g;
          v_g := f;
          v_f := e;
          v_e := std_logic_vector(unsigned(d) + unsigned(v_t1));
          v_d := c;
          v_c := b;
          v_b := a;
          v_a := std_logic_vector(unsigned(v_t1) + unsigned(v_t2));

          a <= v_a;
          b <= v_b;
          c <= v_c;
          d <= v_d;
          e <= v_e;
          f <= v_f;
          g <= v_g;
          h <= v_h;

          if round_idx = 63 then
            state <= DONE;
          else
            round_idx <= round_idx + 1;
          end if;

        when DONE =>
          digest_reg(255 downto 224) <= std_logic_vector(unsigned(h0) + unsigned(a));
          digest_reg(223 downto 192) <= std_logic_vector(unsigned(h1) + unsigned(b));
          digest_reg(191 downto 160) <= std_logic_vector(unsigned(h2) + unsigned(c));
          digest_reg(159 downto 128) <= std_logic_vector(unsigned(h3) + unsigned(d));
          digest_reg(127 downto 96)  <= std_logic_vector(unsigned(h4) + unsigned(e));
          digest_reg(95 downto 64)   <= std_logic_vector(unsigned(h5) + unsigned(f));
          digest_reg(63 downto 32)   <= std_logic_vector(unsigned(h6) + unsigned(g));
          digest_reg(31 downto 0)    <= std_logic_vector(unsigned(h7) + unsigned(h));
          digest_valid_reg <= '1';
          ready_reg <= '1';
          state <= IDLE;
      end case;
    end if;
  end process;
end rtl;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity sha256 is
  port (
    clk        : in  std_logic;
    reset_n    : in  std_logic;
    cs         : in  std_logic;
    we         : in  std_logic;
    address    : in  std_logic_vector(7 downto 0);
    write_data : in  std_logic_vector(31 downto 0);
    read_data  : out std_logic_vector(31 downto 0);
    error      : out std_logic
  );
end sha256;

architecture rtl of sha256 is
  type word_array16 is array (0 to 15) of std_logic_vector(31 downto 0);

  signal block_words : word_array16;
  signal control_reg : std_logic_vector(2 downto 0);
  signal valid_reg   : std_logic;

  signal core_init         : std_logic;
  signal core_next         : std_logic;
  signal core_mode         : std_logic;
  signal core_block        : std_logic_vector(511 downto 0);
  signal core_ready        : std_logic;
  signal core_digest_valid : std_logic;
  signal core_digest       : std_logic_vector(255 downto 0);

  constant NAME0   : std_logic_vector(31 downto 0) := x"53484132";
  constant NAME1   : std_logic_vector(31 downto 0) := x"35362020";
  constant VERSION : std_logic_vector(31 downto 0) := x"00000100";

begin
  core_mode <= control_reg(2);

  core_block(511 downto 480) <= block_words(0);
  core_block(479 downto 448) <= block_words(1);
  core_block(447 downto 416) <= block_words(2);
  core_block(415 downto 384) <= block_words(3);
  core_block(383 downto 352) <= block_words(4);
  core_block(351 downto 320) <= block_words(5);
  core_block(319 downto 288) <= block_words(6);
  core_block(287 downto 256) <= block_words(7);
  core_block(255 downto 224) <= block_words(8);
  core_block(223 downto 192) <= block_words(9);
  core_block(191 downto 160) <= block_words(10);
  core_block(159 downto 128) <= block_words(11);
  core_block(127 downto 96)  <= block_words(12);
  core_block(95 downto 64)   <= block_words(13);
  core_block(63 downto 32)   <= block_words(14);
  core_block(31 downto 0)    <= block_words(15);

  core_inst : entity work.sha256_core
    port map (
      clk          => clk,
      reset_n      => reset_n,
      init         => core_init,
      next         => core_next,
      mode         => core_mode,
      block        => core_block,
      ready        => core_ready,
      digest_valid => core_digest_valid,
      digest       => core_digest
    );

  process(address, cs)
    variable addr : integer range 0 to 255;
  begin
    addr := to_integer(unsigned(address));
    if cs = '1' then
      if (addr = 0) or (addr = 1) or (addr = 2) or (addr = 8) or (addr = 9) or
         (addr >= 16 and addr <= 31) or (addr >= 32 and addr <= 39) then
        error <= '0';
      else
        error <= '1';
      end if;
    else
      error <= '0';
    end if;
  end process;

  process(address, control_reg, core_ready, valid_reg, core_digest_valid, block_words, core_digest)
    variable addr : integer range 0 to 255;
  begin
    addr := to_integer(unsigned(address));
    read_data <= (others => '0');
    case addr is
      when 0 =>
        read_data <= NAME0;
      when 1 =>
        read_data <= NAME1;
      when 2 =>
        read_data <= VERSION;
      when 8 =>
        read_data <= (others => '0');
        read_data(2 downto 0) <= control_reg;
      when 9 =>
        read_data <= (others => '0');
        read_data(0) <= core_ready;
        read_data(1) <= valid_reg or core_digest_valid;
      when 16 to 31 =>
        read_data <= block_words(addr - 16);
      when 32 =>
        read_data <= core_digest(255 downto 224);
      when 33 =>
        read_data <= core_digest(223 downto 192);
      when 34 =>
        read_data <= core_digest(191 downto 160);
      when 35 =>
        read_data <= core_digest(159 downto 128);
      when 36 =>
        read_data <= core_digest(127 downto 96);
      when 37 =>
        read_data <= core_digest(95 downto 64);
      when 38 =>
        read_data <= core_digest(63 downto 32);
      when 39 =>
        read_data <= core_digest(31 downto 0);
      when others =>
        read_data <= (others => '0');
    end case;
  end process;

  process(clk, reset_n)
    variable addr : integer range 0 to 255;
  begin
    if reset_n = '0' then
      for i in 0 to 15 loop
        block_words(i) <= (others => '0');
      end loop;
      control_reg <= (others => '0');
      valid_reg   <= '0';
      core_init   <= '0';
      core_next   <= '0';
    elsif rising_edge(clk) then
      addr := to_integer(unsigned(address));
      core_init <= '0';
      core_next <= '0';

      if cs = '1' and we = '1' then
        if addr = 8 then
          control_reg <= write_data(2 downto 0);
          if write_data(0) = '1' then
            core_init <= '1';
            valid_reg <= '0';
          end if;
          if write_data(1) = '1' then
            core_next <= '1';
            valid_reg <= '0';
          end if;
        elsif addr >= 16 and addr <= 31 then
          block_words(addr - 16) <= write_data;
        end if;
      end if;

      if core_digest_valid = '1' then
        valid_reg <= '1';
      end if;
      if core_init = '1' or core_next = '1' then
        valid_reg <= '0';
      end if;
    end if;
  end process;
end rtl;
