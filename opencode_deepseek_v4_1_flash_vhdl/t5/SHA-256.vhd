library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity sha256_core is
    Port (
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
    type w_array_type is array (0 to 63) of std_logic_vector(31 downto 0);
    type k_array_type is array (0 to 63) of std_logic_vector(31 downto 0);

    constant K : k_array_type := (
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

    signal state          : std_logic_vector(1 downto 0);
    signal t              : integer range 0 to 64;
    signal w              : w_array_type;
    signal h0, h1, h2, h3 : std_logic_vector(31 downto 0);
    signal h4, h5, h6, h7 : std_logic_vector(31 downto 0);
    signal a, b, c, d     : std_logic_vector(31 downto 0);
    signal e, f, g, hh    : std_logic_vector(31 downto 0);
    signal ready_reg      : std_logic;
    signal digest_valid_reg : std_logic;
    signal digest_reg     : std_logic_vector(255 downto 0);

    function rotr(x : std_logic_vector(31 downto 0); n : integer) return std_logic_vector is
    begin
        return x(n-1 downto 0) & x(31 downto n);
    end function;

    function shr(x : std_logic_vector(31 downto 0); n : integer) return std_logic_vector is
        variable r : std_logic_vector(31 downto 0);
    begin
        r := (others => '0');
        r(31-n downto 0) := x(31 downto n);
        return r;
    end function;

    function sigma0(x : std_logic_vector(31 downto 0)) return std_logic_vector is
    begin
        return rotr(x, 2) xor rotr(x, 13) xor rotr(x, 22);
    end function;

    function sigma1(x : std_logic_vector(31 downto 0)) return std_logic_vector is
    begin
        return rotr(x, 6) xor rotr(x, 11) xor rotr(x, 25);
    end function;

    function gamma0(x : std_logic_vector(31 downto 0)) return std_logic_vector is
    begin
        return rotr(x, 7) xor rotr(x, 18) xor shr(x, 3);
    end function;

    function gamma1(x : std_logic_vector(31 downto 0)) return std_logic_vector is
    begin
        return rotr(x, 17) xor rotr(x, 19) xor shr(x, 10);
    end function;

    function Ch(x, y, z : std_logic_vector(31 downto 0)) return std_logic_vector is
    begin
        return (x and y) xor ((not x) and z);
    end function;

    function Maj(x, y, z : std_logic_vector(31 downto 0)) return std_logic_vector is
    begin
        return (x and y) xor (x and z) xor (y and z);
    end function;

begin
    ready        <= ready_reg;
    digest_valid <= digest_valid_reg;
    digest       <= digest_reg;

    process(clk, reset_n)
        variable Wt   : std_logic_vector(31 downto 0);
        variable T1   : std_logic_vector(31 downto 0);
        variable T2   : std_logic_vector(31 downto 0);
        variable sum0 : std_logic_vector(31 downto 0);
        variable sum1 : std_logic_vector(31 downto 0);
        variable sum2 : std_logic_vector(31 downto 0);
        variable sum3 : std_logic_vector(31 downto 0);
        variable sum4 : std_logic_vector(31 downto 0);
        variable sum5 : std_logic_vector(31 downto 0);
        variable sum6 : std_logic_vector(31 downto 0);
        variable sum7 : std_logic_vector(31 downto 0);
    begin
        if reset_n = '0' then
            state <= "00";
            t <= 0;
            w <= (others => (others => '0'));
            h0 <= x"6a09e667";
            h1 <= x"bb67ae85";
            h2 <= x"3c6ef372";
            h3 <= x"a54ff53a";
            h4 <= x"510e527f";
            h5 <= x"9b05688c";
            h6 <= x"1f83d9ab";
            h7 <= x"5be0cd19";
            a  <= x"6a09e667";
            b  <= x"bb67ae85";
            c  <= x"3c6ef372";
            d  <= x"a54ff53a";
            e  <= x"510e527f";
            f  <= x"9b05688c";
            g  <= x"1f83d9ab";
            hh <= x"5be0cd19";
            ready_reg <= '1';
            digest_valid_reg <= '0';
            digest_reg <= x"6a09e667bb67ae853c6ef372a54ff53a510e527f9b05688c1f83d9ab5be0cd19";
        elsif rising_edge(clk) then
            case state is
                when "00" => -- IDLE
                    ready_reg <= '1';
                    if init = '1' or next = '1' then
                        if init = '1' then
                            h0 <= x"6a09e667"; h1 <= x"bb67ae85"; h2 <= x"3c6ef372"; h3 <= x"a54ff53a";
                            h4 <= x"510e527f"; h5 <= x"9b05688c"; h6 <= x"1f83d9ab"; h7 <= x"5be0cd19";
                            a  <= x"6a09e667"; b  <= x"bb67ae85"; c  <= x"3c6ef372"; d  <= x"a54ff53a";
                            e  <= x"510e527f"; f  <= x"9b05688c"; g  <= x"1f83d9ab"; hh <= x"5be0cd19";
                        else
                            a <= h0; b <= h1; c <= h2; d <= h3;
                            e <= h4; f <= h5; g <= h6; hh <= h7;
                        end if;
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
                        t <= 0;
                        ready_reg <= '0';
                        digest_valid_reg <= '0';
                        state <= "01";
                    end if;

                when "01" => -- RUN
                    ready_reg <= '0';
                    if t < 64 then
                        if t < 16 then
                            Wt := w(t);
                        else
                            Wt := std_logic_vector(unsigned(gamma1(w(t-2))) + unsigned(w(t-7)) + unsigned(gamma0(w(t-15))) + unsigned(w(t-16)));
                            w(t) <= Wt;
                        end if;

                        T1 := std_logic_vector(unsigned(hh) + unsigned(sigma1(e)) + unsigned(Ch(e, f, g)) + unsigned(K(t)) + unsigned(Wt));
                        T2 := std_logic_vector(unsigned(sigma0(a)) + unsigned(Maj(a, b, c)));

                        if t = 63 then
                            sum0 := std_logic_vector(unsigned(h0) + unsigned(T1) + unsigned(T2));
                            sum1 := std_logic_vector(unsigned(h1) + unsigned(a));
                            sum2 := std_logic_vector(unsigned(h2) + unsigned(b));
                            sum3 := std_logic_vector(unsigned(h3) + unsigned(c));
                            sum4 := std_logic_vector(unsigned(h4) + unsigned(d) + unsigned(T1));
                            sum5 := std_logic_vector(unsigned(h5) + unsigned(e));
                            sum6 := std_logic_vector(unsigned(h6) + unsigned(f));
                            sum7 := std_logic_vector(unsigned(h7) + unsigned(g));
                            h0 <= sum0; h1 <= sum1; h2 <= sum2; h3 <= sum3;
                            h4 <= sum4; h5 <= sum5; h6 <= sum6; h7 <= sum7;
                            digest_reg <= sum0 & sum1 & sum2 & sum3 & sum4 & sum5 & sum6 & sum7;
                            state <= "10";
                            ready_reg <= '1';
                            digest_valid_reg <= '1';
                        else
                            hh <= g;
                            g  <= f;
                            f  <= e;
                            e  <= std_logic_vector(unsigned(d) + unsigned(T1));
                            d  <= c;
                            c  <= b;
                            b  <= a;
                            a  <= std_logic_vector(unsigned(T1) + unsigned(T2));
                            t <= t + 1;
                        end if;
                    end if;

                when "10" => -- DONE
                    ready_reg <= '1';
                    digest_valid_reg <= '1';
                    if init = '1' or next = '1' then
                        if init = '1' then
                            h0 <= x"6a09e667"; h1 <= x"bb67ae85"; h2 <= x"3c6ef372"; h3 <= x"a54ff53a";
                            h4 <= x"510e527f"; h5 <= x"9b05688c"; h6 <= x"1f83d9ab"; h7 <= x"5be0cd19";
                            a  <= x"6a09e667"; b  <= x"bb67ae85"; c  <= x"3c6ef372"; d  <= x"a54ff53a";
                            e  <= x"510e527f"; f  <= x"9b05688c"; g  <= x"1f83d9ab"; hh <= x"5be0cd19";
                        else
                            a <= h0; b <= h1; c <= h2; d <= h3;
                            e <= h4; f <= h5; g <= h6; hh <= h7;
                        end if;
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
                        t <= 0;
                        ready_reg <= '0';
                        digest_valid_reg <= '0';
                        state <= "01";
                    end if;

                when others =>
                    state <= "00";
                    ready_reg <= '1';
                    digest_valid_reg <= '0';
            end case;
        end if;
    end process;
end rtl;


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity sha256 is
    Port (
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
    signal block_reg   : std_logic_vector(511 downto 0);
    signal control_reg : std_logic_vector(2 downto 0);
    signal core_init   : std_logic;
    signal core_next   : std_logic;
    signal mode_reg    : std_logic;
    signal ready       : std_logic;
    signal digest_valid : std_logic;
    signal digest      : std_logic_vector(255 downto 0);
begin
    u_core : entity work.sha256_core
        port map (
            clk          => clk,
            reset_n      => reset_n,
            init         => core_init,
            next         => core_next,
            mode         => mode_reg,
            block        => block_reg,
            ready        => ready,
            digest_valid => digest_valid,
            digest       => digest
        );

    process(clk, reset_n)
    begin
        if reset_n = '0' then
            block_reg   <= (others => '0');
            control_reg <= (others => '0');
            core_init   <= '0';
            core_next   <= '0';
            mode_reg    <= '0';
        elsif rising_edge(clk) then
            core_init <= '0';
            core_next <= '0';
            if cs = '1' and we = '1' then
                case address is
                    when x"08" =>
                        control_reg <= write_data(2 downto 0);
                        core_init   <= write_data(0);
                        core_next   <= write_data(1);
                        mode_reg    <= write_data(2);
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
                    when x"1A" => block_reg(191 downto 160) <= write_data;
                    when x"1B" => block_reg(159 downto 128) <= write_data;
                    when x"1C" => block_reg(127 downto 96)  <= write_data;
                    when x"1D" => block_reg(95 downto 64)   <= write_data;
                    when x"1E" => block_reg(63 downto 32)   <= write_data;
                    when x"1F" => block_reg(31 downto 0)    <= write_data;
                    when others => null;
                end case;
            end if;
        end if;
    end process;

    process(cs, we, address, control_reg, ready, digest_valid, digest, block_reg)
    begin
        read_data <= (others => '0');
        if cs = '1' and we = '0' then
            case address is
                when x"00" => read_data <= x"53484132";
                when x"01" => read_data <= x"35360000";
                when x"02" => read_data <= x"00000100";
                when x"08" => read_data <= (31 downto 3 => '0') & control_reg;
                when x"09" => read_data <= (31 downto 2 => '0') & digest_valid & ready;
                when x"10" => read_data <= block_reg(511 downto 480);
                when x"11" => read_data <= block_reg(479 downto 448);
                when x"12" => read_data <= block_reg(447 downto 416);
                when x"13" => read_data <= block_reg(415 downto 384);
                when x"14" => read_data <= block_reg(383 downto 352);
                when x"15" => read_data <= block_reg(351 downto 320);
                when x"16" => read_data <= block_reg(319 downto 288);
                when x"17" => read_data <= block_reg(287 downto 256);
                when x"18" => read_data <= block_reg(255 downto 224);
                when x"19" => read_data <= block_reg(223 downto 192);
                when x"1A" => read_data <= block_reg(191 downto 160);
                when x"1B" => read_data <= block_reg(159 downto 128);
                when x"1C" => read_data <= block_reg(127 downto 96);
                when x"1D" => read_data <= block_reg(95 downto 64);
                when x"1E" => read_data <= block_reg(63 downto 32);
                when x"1F" => read_data <= block_reg(31 downto 0);
                when x"20" => read_data <= digest(255 downto 224);
                when x"21" => read_data <= digest(223 downto 192);
                when x"22" => read_data <= digest(191 downto 160);
                when x"23" => read_data <= digest(159 downto 128);
                when x"24" => read_data <= digest(127 downto 96);
                when x"25" => read_data <= digest(95 downto 64);
                when x"26" => read_data <= digest(63 downto 32);
                when x"27" => read_data <= digest(31 downto 0);
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
end rtl;
