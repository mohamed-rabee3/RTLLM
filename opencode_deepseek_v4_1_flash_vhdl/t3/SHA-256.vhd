library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity sha256_core is
    port (
        clk         : in  std_logic;
        reset_n     : in  std_logic;
        init        : in  std_logic;
        \next\      : in  std_logic;
        mode        : in  std_logic;
        block       : in  std_logic_vector(511 downto 0);
        ready       : out std_logic;
        digest_valid: out std_logic;
        digest      : out std_logic_vector(255 downto 0)
    );
end entity;

architecture rtl of sha256_core is
    type state_t is (IDLE, COMPUTE, FINAL);
    signal state : state_t := IDLE;
    signal t : integer range 0 to 63 := 0;
    signal a, b, c, d, e, f, g, h : unsigned(31 downto 0);
    signal H0, H1, H2, H3, H4, H5, H6, H7 : unsigned(31 downto 0);
    type w_array is array (0 to 63) of unsigned(31 downto 0);
    signal W : w_array;
    signal ready_reg : std_logic := '1';
    signal digest_valid_reg : std_logic := '0';

    constant INIT_H0 : unsigned(31 downto 0) := x"6a09e667";
    constant INIT_H1 : unsigned(31 downto 0) := x"bb67ae85";
    constant INIT_H2 : unsigned(31 downto 0) := x"3c6ef372";
    constant INIT_H3 : unsigned(31 downto 0) := x"a54ff53a";
    constant INIT_H4 : unsigned(31 downto 0) := x"510e527f";
    constant INIT_H5 : unsigned(31 downto 0) := x"9b05688c";
    constant INIT_H6 : unsigned(31 downto 0) := x"1f83d9ab";
    constant INIT_H7 : unsigned(31 downto 0) := x"5be0cd19";

    type k_array is array (0 to 63) of unsigned(31 downto 0);
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

    function rotr(x : unsigned(31 downto 0); n : integer) return unsigned is
    begin
        return x(n-1 downto 0) & x(31 downto n);
    end function;

    function shr(x : unsigned(31 downto 0); n : integer) return unsigned is
        variable r : unsigned(31 downto 0) := (others => '0');
    begin
        r(31-n downto 0) := x(31 downto n);
        return r;
    end function;

    function sigma0(x : unsigned(31 downto 0)) return unsigned is
    begin
        return rotr(x, 2) xor rotr(x, 13) xor rotr(x, 22);
    end function;

    function sigma1(x : unsigned(31 downto 0)) return unsigned is
    begin
        return rotr(x, 6) xor rotr(x, 11) xor rotr(x, 25);
    end function;

    function gamma0(x : unsigned(31 downto 0)) return unsigned is
    begin
        return rotr(x, 7) xor rotr(x, 18) xor shr(x, 3);
    end function;

    function gamma1(x : unsigned(31 downto 0)) return unsigned is
    begin
        return rotr(x, 17) xor rotr(x, 19) xor shr(x, 10);
    end function;

    function ch(x, y, z : unsigned(31 downto 0)) return unsigned is
    begin
        return (x and y) xor ((not x) and z);
    end function;

    function maj(x, y, z : unsigned(31 downto 0)) return unsigned is
    begin
        return (x and y) xor (x and z) xor (y and z);
    end function;

begin

    ready <= ready_reg;
    digest_valid <= digest_valid_reg;
    digest <= std_logic_vector(H0) & std_logic_vector(H1) & std_logic_vector(H2) & std_logic_vector(H3) &
              std_logic_vector(H4) & std_logic_vector(H5) & std_logic_vector(H6) & std_logic_vector(H7);

    process(clk, reset_n)
        variable Wt_v : unsigned(31 downto 0);
        variable T1_v : unsigned(31 downto 0);
        variable T2_v : unsigned(31 downto 0);
    begin
        if reset_n = '0' then
            state <= IDLE;
            t <= 0;
            ready_reg <= '1';
            digest_valid_reg <= '0';
            H0 <= INIT_H0;
            H1 <= INIT_H1;
            H2 <= INIT_H2;
            H3 <= INIT_H3;
            H4 <= INIT_H4;
            H5 <= INIT_H5;
            H6 <= INIT_H6;
            H7 <= INIT_H7;
            a <= INIT_H0;
            b <= INIT_H1;
            c <= INIT_H2;
            d <= INIT_H3;
            e <= INIT_H4;
            f <= INIT_H5;
            g <= INIT_H6;
            h <= INIT_H7;
        elsif rising_edge(clk) then
            case state is
                when IDLE =>
                    ready_reg <= '1';
                    digest_valid_reg <= '0';
                    if (init = '1' or \next\ = '1') then
                        if init = '1' then
                            H0 <= INIT_H0;
                            H1 <= INIT_H1;
                            H2 <= INIT_H2;
                            H3 <= INIT_H3;
                            H4 <= INIT_H4;
                            H5 <= INIT_H5;
                            H6 <= INIT_H6;
                            H7 <= INIT_H7;
                            a <= INIT_H0;
                            b <= INIT_H1;
                            c <= INIT_H2;
                            d <= INIT_H3;
                            e <= INIT_H4;
                            f <= INIT_H5;
                            g <= INIT_H6;
                            h <= INIT_H7;
                        else
                            a <= H0;
                            b <= H1;
                            c <= H2;
                            d <= H3;
                            e <= H4;
                            f <= H5;
                            g <= H6;
                            h <= H7;
                        end if;
                        W(0) <= unsigned(block(511 downto 480));
                        W(1) <= unsigned(block(479 downto 448));
                        W(2) <= unsigned(block(447 downto 416));
                        W(3) <= unsigned(block(415 downto 384));
                        W(4) <= unsigned(block(383 downto 352));
                        W(5) <= unsigned(block(351 downto 320));
                        W(6) <= unsigned(block(319 downto 288));
                        W(7) <= unsigned(block(287 downto 256));
                        W(8) <= unsigned(block(255 downto 224));
                        W(9) <= unsigned(block(223 downto 192));
                        W(10) <= unsigned(block(191 downto 160));
                        W(11) <= unsigned(block(159 downto 128));
                        W(12) <= unsigned(block(127 downto 96));
                        W(13) <= unsigned(block(95 downto 64));
                        W(14) <= unsigned(block(63 downto 32));
                        W(15) <= unsigned(block(31 downto 0));
                        t <= 0;
                        ready_reg <= '0';
                        digest_valid_reg <= '0';
                        state <= COMPUTE;
                    end if;

                when COMPUTE =>
                    if t < 16 then
                        Wt_v := W(t);
                    else
                        Wt_v := gamma1(W(t-2)) + W(t-7) + gamma0(W(t-15)) + W(t-16);
                        W(t) <= Wt_v;
                    end if;

                    T1_v := h + sigma1(e) + ch(e, f, g) + K(t) + Wt_v;
                    T2_v := sigma0(a) + maj(a, b, c);

                    h <= g;
                    g <= f;
                    f <= e;
                    e <= d + T1_v;
                    d <= c;
                    c <= b;
                    b <= a;
                    a <= T1_v + T2_v;

                    if t = 63 then
                        state <= FINAL;
                    else
                        t <= t + 1;
                    end if;

                when FINAL =>
                    H0 <= H0 + a;
                    H1 <= H1 + b;
                    H2 <= H2 + c;
                    H3 <= H3 + d;
                    H4 <= H4 + e;
                    H5 <= H5 + f;
                    H6 <= H6 + g;
                    H7 <= H7 + h;
                    ready_reg <= '1';
                    digest_valid_reg <= '1';
                    state <= IDLE;

            end case;
        end if;
    end process;

end architecture;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity sha256 is
    port (
        clk         : in  std_logic;
        reset_n     : in  std_logic;
        cs          : in  std_logic;
        we          : in  std_logic;
        address     : in  std_logic_vector(7 downto 0);
        write_data  : in  std_logic_vector(31 downto 0);
        read_data   : out std_logic_vector(31 downto 0);
        error       : out std_logic
    );
end entity;

architecture rtl of sha256 is
    signal block_reg : std_logic_vector(511 downto 0);
    signal control_reg : std_logic_vector(31 downto 0);
    signal mode_reg : std_logic;
    signal core_init : std_logic;
    signal core_next : std_logic;
    signal core_ready : std_logic;
    signal core_digest_valid : std_logic;
    signal core_digest : std_logic_vector(255 downto 0);
    signal valid_reg : std_logic;
    signal read_data_reg : std_logic_vector(31 downto 0);
    signal error_reg : std_logic;
begin

    u_sha256_core : entity work.sha256_core
        port map (
            clk          => clk,
            reset_n      => reset_n,
            init         => core_init,
            \next\       => core_next,
            mode         => mode_reg,
            block        => block_reg,
            ready        => core_ready,
            digest_valid => core_digest_valid,
            digest       => core_digest
        );

    process(clk, reset_n)
    begin
        if reset_n = '0' then
            block_reg <= (others => '0');
            control_reg <= (others => '0');
            mode_reg <= '0';
            core_init <= '0';
            core_next <= '0';
            valid_reg <= '0';
        elsif rising_edge(clk) then
            core_init <= '0';
            core_next <= '0';

            if cs = '1' and we = '1' then
                case address is
                    when x"08" =>
                        control_reg <= write_data;
                        mode_reg <= write_data(2);
                        if write_data(0) = '1' then
                            core_init <= '1';
                            valid_reg <= '0';
                        elsif write_data(1) = '1' then
                            core_next <= '1';
                            valid_reg <= '0';
                        end if;
                    when x"10" =>
                        block_reg(511 downto 480) <= write_data;
                    when x"11" =>
                        block_reg(479 downto 448) <= write_data;
                    when x"12" =>
                        block_reg(447 downto 416) <= write_data;
                    when x"13" =>
                        block_reg(415 downto 384) <= write_data;
                    when x"14" =>
                        block_reg(383 downto 352) <= write_data;
                    when x"15" =>
                        block_reg(351 downto 320) <= write_data;
                    when x"16" =>
                        block_reg(319 downto 288) <= write_data;
                    when x"17" =>
                        block_reg(287 downto 256) <= write_data;
                    when x"18" =>
                        block_reg(255 downto 224) <= write_data;
                    when x"19" =>
                        block_reg(223 downto 192) <= write_data;
                    when x"1a" =>
                        block_reg(191 downto 160) <= write_data;
                    when x"1b" =>
                        block_reg(159 downto 128) <= write_data;
                    when x"1c" =>
                        block_reg(127 downto 96) <= write_data;
                    when x"1d" =>
                        block_reg(95 downto 64) <= write_data;
                    when x"1e" =>
                        block_reg(63 downto 32) <= write_data;
                    when x"1f" =>
                        block_reg(31 downto 0) <= write_data;
                    when others =>
                        null;
                end case;
            end if;

            if core_digest_valid = '1' then
                valid_reg <= '1';
            end if;
        end if;
    end process;

    process(cs, we, address, control_reg, valid_reg, core_ready, core_digest_valid, block_reg, core_digest)
    begin
        read_data_reg <= (others => '0');
        error_reg <= '0';

        if cs = '1' then
            if we = '0' then
                case address is
                    when x"00" =>
                        read_data_reg <= x"53484132";
                    when x"01" =>
                        read_data_reg <= x"35360000";
                    when x"02" =>
                        read_data_reg <= x"00000100";
                    when x"08" =>
                        read_data_reg <= control_reg;
                    when x"09" =>
                        read_data_reg <= (31 downto 2 => '0') & (valid_reg or core_digest_valid) & core_ready;
                    when x"10" =>
                        read_data_reg <= block_reg(511 downto 480);
                    when x"11" =>
                        read_data_reg <= block_reg(479 downto 448);
                    when x"12" =>
                        read_data_reg <= block_reg(447 downto 416);
                    when x"13" =>
                        read_data_reg <= block_reg(415 downto 384);
                    when x"14" =>
                        read_data_reg <= block_reg(383 downto 352);
                    when x"15" =>
                        read_data_reg <= block_reg(351 downto 320);
                    when x"16" =>
                        read_data_reg <= block_reg(319 downto 288);
                    when x"17" =>
                        read_data_reg <= block_reg(287 downto 256);
                    when x"18" =>
                        read_data_reg <= block_reg(255 downto 224);
                    when x"19" =>
                        read_data_reg <= block_reg(223 downto 192);
                    when x"1a" =>
                        read_data_reg <= block_reg(191 downto 160);
                    when x"1b" =>
                        read_data_reg <= block_reg(159 downto 128);
                    when x"1c" =>
                        read_data_reg <= block_reg(127 downto 96);
                    when x"1d" =>
                        read_data_reg <= block_reg(95 downto 64);
                    when x"1e" =>
                        read_data_reg <= block_reg(63 downto 32);
                    when x"1f" =>
                        read_data_reg <= block_reg(31 downto 0);
                    when x"20" =>
                        read_data_reg <= core_digest(255 downto 224);
                    when x"21" =>
                        read_data_reg <= core_digest(223 downto 192);
                    when x"22" =>
                        read_data_reg <= core_digest(191 downto 160);
                    when x"23" =>
                        read_data_reg <= core_digest(159 downto 128);
                    when x"24" =>
                        read_data_reg <= core_digest(127 downto 96);
                    when x"25" =>
                        read_data_reg <= core_digest(95 downto 64);
                    when x"26" =>
                        read_data_reg <= core_digest(63 downto 32);
                    when x"27" =>
                        read_data_reg <= core_digest(31 downto 0);
                    when others =>
                        error_reg <= '1';
                        read_data_reg <= (others => '0');
                end case;
            else
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
        end if;
    end process;

    read_data <= read_data_reg;
    error <= error_reg;

end architecture;
