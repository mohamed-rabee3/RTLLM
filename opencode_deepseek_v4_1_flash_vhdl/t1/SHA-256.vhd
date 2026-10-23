library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

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
  type word_array is array (0 to 63) of std_logic_vector(31 downto 0);
  type state_t is (IDLE, PROCESS, FINISH);

  signal state           : state_t;
  signal w               : word_array;
  signal a, b, c, d      : std_logic_vector(31 downto 0);
  signal e, f, g, h      : std_logic_vector(31 downto 0);
  signal h0, h1, h2, h3  : std_logic_vector(31 downto 0);
  signal h4, h5, h6, h7  : std_logic_vector(31 downto 0);
  signal digest_reg      : std_logic_vector(255 downto 0);
  signal ready_reg       : std_logic;
  signal digest_valid_reg: std_logic;
  signal round_cnt       : integer range 0 to 63;

  constant IV0 : std_logic_vector(31 downto 0) := x"6a09e667";
  constant IV1 : std_logic_vector(31 downto 0) := x"bb67ae85";
  constant IV2 : std_logic_vector(31 downto 0) := x"3c6ef372";
  constant IV3 : std_logic_vector(31 downto 0) := x"a54ff53a";
  constant IV4 : std_logic_vector(31 downto 0) := x"510e527f";
  constant IV5 : std_logic_vector(31 downto 0) := x"9b05688c";
  constant IV6 : std_logic_vector(31 downto 0) := x"1f83d9ab";
  constant IV7 : std_logic_vector(31 downto 0) := x"5be0cd19";

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

  function rotr(x : std_logic_vector(31 downto 0); n : integer) return std_logic_vector is
    variable res : std_logic_vector(31 downto 0);
  begin
    res := x(n-1 downto 0) & x(31 downto n);
    return res;
  end function;

  function shr(x : std_logic_vector(31 downto 0); n : integer) return std_logic_vector is
    variable res : std_logic_vector(31 downto 0) := (others => '0');
  begin
    res(31-n downto 0) := x(31 downto n);
    return res;
  end function;

  function ch(x, y, z : std_logic_vector(31 downto 0)) return std_logic_vector is
  begin
    return (x and y) xor ((not x) and z);
  end function;

  function maj(x, y, z : std_logic_vector(31 downto 0)) return std_logic_vector is
  begin
    return (x and y) xor (x and z) xor (y and z);
  end function;

  function bsig0(x : std_logic_vector(31 downto 0)) return std_logic_vector is
  begin
    return rotr(x, 2) xor rotr(x, 13) xor rotr(x, 22);
  end function;

  function bsig1(x : std_logic_vector(31 downto 0)) return std_logic_vector is
  begin
    return rotr(x, 6) xor rotr(x, 11) xor rotr(x, 25);
  end function;

  function ssig0(x : std_logic_vector(31 downto 0)) return std_logic_vector is
  begin
    return rotr(x, 7) xor rotr(x, 18) xor shr(x, 3);
  end function;

  function ssig1(x : std_logic_vector(31 downto 0)) return std_logic_vector is
  begin
    return rotr(x, 17) xor rotr(x, 19) xor shr(x, 10);
  end function;

begin
  process(clk, reset_n)
    variable vw : word_array;
    variable old_h0, old_h1, old_h2, old_h3 : std_logic_vector(31 downto 0);
    variable old_h4, old_h5, old_h6, old_h7 : std_logic_vector(31 downto 0);
    variable t1, t2 : std_logic_vector(31 downto 0);
    variable vh0, vh1, vh2, vh3 : std_logic_vector(31 downto 0);
    variable vh4, vh5, vh6, vh7 : std_logic_vector(31 downto 0);
  begin
    if reset_n = '0' then
      state <= IDLE;
      ready_reg <= '1';
      digest_valid_reg <= '0';
      round_cnt <= 0;
      h0 <= IV0;
      h1 <= IV1;
      h2 <= IV2;
      h3 <= IV3;
      h4 <= IV4;
      h5 <= IV5;
      h6 <= IV6;
      h7 <= IV7;
      digest_reg <= IV0 & IV1 & IV2 & IV3 & IV4 & IV5 & IV6 & IV7;
      a <= (others => '0');
      b <= (others => '0');
      c <= (others => '0');
      d <= (others => '0');
      e <= (others => '0');
      f <= (others => '0');
      g <= (others => '0');
      h <= (others => '0');
      w <= (others => (others => '0'));
    elsif rising_edge(clk) then
      case state is
        when IDLE =>
          ready_reg <= '1';
          if init = '1' or next = '1' then
            ready_reg <= '0';
            digest_valid_reg <= '0';

            for i in 0 to 15 loop
              vw(i) := block(511 - i*32 downto 480 - i*32);
            end loop;
            for i in 16 to 63 loop
              vw(i) := std_logic_vector(unsigned(ssig1(vw(i-2))) + unsigned(vw(i-7)) + unsigned(ssig0(vw(i-15))) + unsigned(vw(i-16)));
            end loop;
            w <= vw;

            if init = '1' then
              old_h0 := IV0; old_h1 := IV1; old_h2 := IV2; old_h3 := IV3;
              old_h4 := IV4; old_h5 := IV5; old_h6 := IV6; old_h7 := IV7;
            else
              old_h0 := h0; old_h1 := h1; old_h2 := h2; old_h3 := h3;
              old_h4 := h4; old_h5 := h5; old_h6 := h6; old_h7 := h7;
            end if;

            h0 <= old_h0; h1 <= old_h1; h2 <= old_h2; h3 <= old_h3;
            h4 <= old_h4; h5 <= old_h5; h6 <= old_h6; h7 <= old_h7;

            a <= old_h0; b <= old_h1; c <= old_h2; d <= old_h3;
            e <= old_h4; f <= old_h5; g <= old_h6; h <= old_h7;

            round_cnt <= 0;
            state <= PROCESS;
          end if;

        when PROCESS =>
          t1 := std_logic_vector(unsigned(h) + unsigned(bsig1(e)) + unsigned(ch(e,f,g)) + unsigned(K(round_cnt)) + unsigned(w(round_cnt)));
          t2 := std_logic_vector(unsigned(bsig0(a)) + unsigned(maj(a,b,c)));

          h <= g;
          g <= f;
          f <= e;
          e <= std_logic_vector(unsigned(d) + unsigned(t1));
          d <= c;
          c <= b;
          b <= a;
          a <= std_logic_vector(unsigned(t1) + unsigned(t2));

          if round_cnt = 63 then
            state <= FINISH;
          else
            round_cnt <= round_cnt + 1;
          end if;

        when FINISH =>
          vh0 := std_logic_vector(unsigned(h0) + unsigned(a));
          vh1 := std_logic_vector(unsigned(h1) + unsigned(b));
          vh2 := std_logic_vector(unsigned(h2) + unsigned(c));
          vh3 := std_logic_vector(unsigned(h3) + unsigned(d));
          vh4 := std_logic_vector(unsigned(h4) + unsigned(e));
          vh5 := std_logic_vector(unsigned(h5) + unsigned(f));
          vh6 := std_logic_vector(unsigned(h6) + unsigned(g));
          vh7 := std_logic_vector(unsigned(h7) + unsigned(h));

          h0 <= vh0; h1 <= vh1; h2 <= vh2; h3 <= vh3;
          h4 <= vh4; h5 <= vh5; h6 <= vh6; h7 <= vh7;

          digest_reg <= vh0 & vh1 & vh2 & vh3 & vh4 & vh5 & vh6 & vh7;
          ready_reg <= '1';
          digest_valid_reg <= '1';
          state <= IDLE;
          round_cnt <= 0;
      end case;
    end if;
  end process;

  ready <= ready_reg;
  digest_valid <= digest_valid_reg;
  digest <= digest_reg;
end rtl;


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

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
  component sha256_core
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
  end component;

  constant NAME0   : std_logic_vector(31 downto 0) := x"53484132"; -- "SHA2"
  constant NAME1   : std_logic_vector(31 downto 0) := x"35360000"; -- "56"
  constant VERSION : std_logic_vector(31 downto 0) := x"00010000";

  signal block_reg    : std_logic_vector(511 downto 0);
  signal control_reg  : std_logic_vector(31 downto 0);
  signal pending_init : std_logic;
  signal pending_next : std_logic;
  signal core_init    : std_logic;
  signal core_next    : std_logic;
  signal core_mode    : std_logic;
  signal core_ready   : std_logic;
  signal core_valid   : std_logic;
  signal core_digest  : std_logic_vector(255 downto 0);
  signal read_data_reg: std_logic_vector(31 downto 0);
  signal error_reg    : std_logic;
begin
  core_inst : sha256_core
    port map (
      clk          => clk,
      reset_n      => reset_n,
      init         => core_init,
      next         => core_next,
      mode         => core_mode,
      block        => block_reg,
      ready        => core_ready,
      digest_valid => core_valid,
      digest       => core_digest
    );

  core_init <= pending_init and core_ready;
  core_next <= pending_next and core_ready and not pending_init;
  core_mode <= control_reg(2);

  process(clk, reset_n)
  begin
    if reset_n = '0' then
      block_reg <= (others => '0');
      control_reg <= (others => '0');
      pending_init <= '0';
      pending_next <= '0';
    elsif rising_edge(clk) then
      if core_ready = '1' then
        if pending_init = '1' then
          pending_init <= '0';
          pending_next <= '0';
        elsif pending_next = '1' then
          pending_next <= '0';
        end if;
      end if;

      if cs = '1' and we = '1' then
        case address is
          when x"08" =>
            control_reg <= write_data;
            if write_data(0) = '1' then
              pending_init <= '1';
              pending_next <= '0';
            elsif write_data(1) = '1' then
              pending_next <= '1';
              pending_init <= '0';
            end if;

          when x"10" => block_reg(511 downto 480) <= write_data;
          when x"11" => block_reg(479 downto 448) <= write_data;
          when x"12" => block_reg(447 downto 416) <= write_data;
          when x"13" => block_reg(415 downto 384) <= write_data;
          when x"14" => block_reg(383 downto 352) <= write_data;
          when x"15" => block_reg(351 downto 320) <= write_data;
          when x"16" => block_reg(319 downto 288) <= write_data;
          when x"17" => block_reg(287 downto 256) <= write_data;
          when x"18" => block_reg(255 downto 224) <= write_data;
          when x"19" => block_reg(223 downto 192) <= write_data;
          when x"1a" => block_reg(191 downto 160) <= write_data;
          when x"1b" => block_reg(159 downto 128) <= write_data;
          when x"1c" => block_reg(127 downto 96) <= write_data;
          when x"1d" => block_reg(95 downto 64) <= write_data;
          when x"1e" => block_reg(63 downto 32) <= write_data;
          when x"1f" => block_reg(31 downto 0) <= write_data;
          when others => null;
        end case;
      end if;
    end if;
  end process;

  process(cs, we, address, control_reg, core_ready, core_valid, core_digest, block_reg)
  begin
    read_data_reg <= (others => '0');
    if cs = '1' and we = '0' then
      case address is
        when x"00" => read_data_reg <= NAME0;
        when x"01" => read_data_reg <= NAME1;
        when x"02" => read_data_reg <= VERSION;
        when x"08" => read_data_reg <= control_reg;
        when x"09" => read_data_reg <= std_logic_vector(to_unsigned(0, 30)) & core_valid & core_ready;
        when x"10" => read_data_reg <= block_reg(511 downto 480);
        when x"11" => read_data_reg <= block_reg(479 downto 448);
        when x"12" => read_data_reg <= block_reg(447 downto 416);
        when x"13" => read_data_reg <= block_reg(415 downto 384);
        when x"14" => read_data_reg <= block_reg(383 downto 352);
        when x"15" => read_data_reg <= block_reg(351 downto 320);
        when x"16" => read_data_reg <= block_reg(319 downto 288);
        when x"17" => read_data_reg <= block_reg(287 downto 256);
        when x"18" => read_data_reg <= block_reg(255 downto 224);
        when x"19" => read_data_reg <= block_reg(223 downto 192);
        when x"1a" => read_data_reg <= block_reg(191 downto 160);
        when x"1b" => read_data_reg <= block_reg(159 downto 128);
        when x"1c" => read_data_reg <= block_reg(127 downto 96);
        when x"1d" => read_data_reg <= block_reg(95 downto 64);
        when x"1e" => read_data_reg <= block_reg(63 downto 32);
        when x"1f" => read_data_reg <= block_reg(31 downto 0);
        when x"20" => read_data_reg <= core_digest(255 downto 224);
        when x"21" => read_data_reg <= core_digest(223 downto 192);
        when x"22" => read_data_reg <= core_digest(191 downto 160);
        when x"23" => read_data_reg <= core_digest(159 downto 128);
        when x"24" => read_data_reg <= core_digest(127 downto 96);
        when x"25" => read_data_reg <= core_digest(95 downto 64);
        when x"26" => read_data_reg <= core_digest(63 downto 32);
        when x"27" => read_data_reg <= core_digest(31 downto 0);
        when others => read_data_reg <= (others => '0');
      end case;
    end if;
  end process;

  read_data <= read_data_reg;

  process(cs, address)
  begin
    error_reg <= '0';
    if cs = '1' then
      case address is
        when x"00" | x"01" | x"02" | x"08" | x"09" |
             x"10" | x"11" | x"12" | x"13" | x"14" | x"15" | x"16" | x"17" |
             x"18" | x"19" | x"1a" | x"1b" | x"1c" | x"1d" | x"1e" | x"1f" |
             x"20" | x"21" | x"22" | x"23" | x"24" | x"25" | x"26" | x"27" =>
          error_reg <= '0';
        when others =>
          error_reg <= '1';
      end case;
    end if;
  end process;

  error <= error_reg;
end rtl;
