library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sha256_core is
    port (
        clk          : in  std_logic;
        reset_n      : in  std_logic;
        init         : in  std_logic;
        \next\       : in  std_logic;
        mode         : in  std_logic;
        \block\      : in  std_logic_vector(511 downto 0);
        ready        : out std_logic;
        digest_valid : out std_logic;
        digest       : out std_logic_vector(255 downto 0)
    );
end entity sha256_core;

architecture rtl of sha256_core is
    subtype word_t is unsigned(31 downto 0);
    type word_array_t is array (natural range <>) of word_t;
    type state_t is (IDLE, ROUNDS, FINISH);

    constant IV : word_array_t(0 to 7) := (
        x"6a09e667", x"bb67ae85", x"3c6ef372", x"a54ff53a",
        x"510e527f", x"9b05688c", x"1f83d9ab", x"5be0cd19"
    );

    constant K : word_array_t(0 to 63) := (
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

    function big_sigma0(x : word_t) return word_t is
    begin
        return rotate_right(x, 2) xor rotate_right(x, 13)
               xor rotate_right(x, 22);
    end function;

    function big_sigma1(x : word_t) return word_t is
    begin
        return rotate_right(x, 6) xor rotate_right(x, 11)
               xor rotate_right(x, 25);
    end function;

    function small_sigma0(x : word_t) return word_t is
    begin
        return rotate_right(x, 7) xor rotate_right(x, 18)
               xor shift_right(x, 3);
    end function;

    function small_sigma1(x : word_t) return word_t is
    begin
        return rotate_right(x, 17) xor rotate_right(x, 19)
               xor shift_right(x, 10);
    end function;

    function choose(x, y, z : word_t) return word_t is
    begin
        return (x and y) xor ((not x) and z);
    end function;

    function majority(x, y, z : word_t) return word_t is
    begin
        return (x and y) xor (x and z) xor (y and z);
    end function;

    signal state       : state_t;
    signal round_index : integer range 0 to 63;
    signal schedule    : word_array_t(0 to 63);
    signal hash_state  : word_array_t(0 to 7);
    signal a_reg       : word_t;
    signal b_reg       : word_t;
    signal c_reg       : word_t;
    signal d_reg       : word_t;
    signal e_reg       : word_t;
    signal f_reg       : word_t;
    signal g_reg       : word_t;
    signal h_reg       : word_t;
    signal valid_reg   : std_logic;
begin
    -- This implementation performs SHA-256 for either value of mode.
    ready        <= '1' when state = IDLE else '0';
    digest_valid <= valid_reg;

    digest_words : for i in 0 to 7 generate
        digest(255 - 32*i downto 224 - 32*i) <=
            std_logic_vector(hash_state(i));
    end generate;

    process(clk, reset_n)
        variable w_round : word_t;
        variable t1      : word_t;
        variable t2      : word_t;
    begin
        if reset_n = '0' then
            state       <= IDLE;
            round_index <= 0;
            schedule    <= (others => (others => '0'));
            hash_state  <= (others => (others => '0'));
            a_reg       <= (others => '0');
            b_reg       <= (others => '0');
            c_reg       <= (others => '0');
            d_reg       <= (others => '0');
            e_reg       <= (others => '0');
            f_reg       <= (others => '0');
            g_reg       <= (others => '0');
            h_reg       <= (others => '0');
            valid_reg   <= '0';
        elsif rising_edge(clk) then
            case state is
                when IDLE =>
                    if init = '1' or \next\ = '1' then
                        valid_reg   <= '0';
                        round_index <= 0;

                        for i in 0 to 15 loop
                            schedule(i) <=
                                unsigned(\block\(511 - 32*i downto 480 - 32*i));
                        end loop;

                        if init = '1' then
                            hash_state <= IV;
                            a_reg <= IV(0);
                            b_reg <= IV(1);
                            c_reg <= IV(2);
                            d_reg <= IV(3);
                            e_reg <= IV(4);
                            f_reg <= IV(5);
                            g_reg <= IV(6);
                            h_reg <= IV(7);
                        else
                            a_reg <= hash_state(0);
                            b_reg <= hash_state(1);
                            c_reg <= hash_state(2);
                            d_reg <= hash_state(3);
                            e_reg <= hash_state(4);
                            f_reg <= hash_state(5);
                            g_reg <= hash_state(6);
                            h_reg <= hash_state(7);
                        end if;

                        state <= ROUNDS;
                    end if;

                when ROUNDS =>
                    if round_index < 16 then
                        w_round := schedule(round_index);
                    else
                        w_round :=
                            small_sigma1(schedule(round_index - 2)) +
                            schedule(round_index - 7) +
                            small_sigma0(schedule(round_index - 15)) +
                            schedule(round_index - 16);
                        schedule(round_index) <= w_round;
                    end if;

                    t1 := h_reg + big_sigma1(e_reg) +
                          choose(e_reg, f_reg, g_reg) +
                          K(round_index) + w_round;
                    t2 := big_sigma0(a_reg) +
                          majority(a_reg, b_reg, c_reg);

                    h_reg <= g_reg;
                    g_reg <= f_reg;
                    f_reg <= e_reg;
                    e_reg <= d_reg + t1;
                    d_reg <= c_reg;
                    c_reg <= b_reg;
                    b_reg <= a_reg;
                    a_reg <= t1 + t2;

                    if round_index = 63 then
                        state <= FINISH;
                    else
                        round_index <= round_index + 1;
                    end if;

                when FINISH =>
                    hash_state(0) <= hash_state(0) + a_reg;
                    hash_state(1) <= hash_state(1) + b_reg;
                    hash_state(2) <= hash_state(2) + c_reg;
                    hash_state(3) <= hash_state(3) + d_reg;
                    hash_state(4) <= hash_state(4) + e_reg;
                    hash_state(5) <= hash_state(5) + f_reg;
                    hash_state(6) <= hash_state(6) + g_reg;
                    hash_state(7) <= hash_state(7) + h_reg;
                    valid_reg <= '1';
                    state     <= IDLE;
            end case;
        end if;
    end process;
end architecture rtl;


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
end entity sha256;

architecture rtl of sha256 is
    type block_words_t is array (0 to 15) of
        std_logic_vector(31 downto 0);

    constant NAME0   : std_logic_vector(31 downto 0) := x"73686132";
    constant NAME1   : std_logic_vector(31 downto 0) := x"2d323536";
    constant VERSION : std_logic_vector(31 downto 0) := x"312e3030";

    signal block_words : block_words_t;
    signal core_block  : std_logic_vector(511 downto 0);
    signal core_digest : std_logic_vector(255 downto 0);
    signal core_ready  : std_logic;
    signal core_valid  : std_logic;
    signal init_reg    : std_logic;
    signal next_reg    : std_logic;
    signal mode_reg    : std_logic;
begin
    pack_block : for i in 0 to 15 generate
        core_block(511 - 32*i downto 480 - 32*i) <= block_words(i);
    end generate;

    core_inst : entity work.sha256_core
        port map (
            clk          => clk,
            reset_n      => reset_n,
            init         => init_reg,
            \next\       => next_reg,
            mode         => mode_reg,
            \block\      => core_block,
            ready        => core_ready,
            digest_valid => core_valid,
            digest       => core_digest
        );

    process(clk, reset_n)
        variable addr : integer range 0 to 255;
    begin
        if reset_n = '0' then
            block_words <= (others => (others => '0'));
            init_reg    <= '0';
            next_reg    <= '0';
            mode_reg    <= '1';
        elsif rising_edge(clk) then
            init_reg <= '0';
            next_reg <= '0';

            if cs = '1' and we = '1' then
                addr := to_integer(unsigned(address));
                if addr = 16#08# then
                    init_reg <= write_data(0);
                    next_reg <= write_data(1);
                    mode_reg <= write_data(2);
                elsif addr >= 16#10# and addr <= 16#1f# then
                    block_words(addr - 16#10#) <= write_data;
                end if;
            end if;
        end if;
    end process;

    process(cs, we, address, block_words, core_digest, core_ready,
            core_valid, init_reg, next_reg, mode_reg)
        variable addr         : integer range 0 to 255;
        variable data_v       : std_logic_vector(31 downto 0);
        variable defined_addr : boolean;
        variable word_index   : integer range 0 to 7;
    begin
        read_data <= (others => '0');
        error     <= '0';
        data_v    := (others => '0');
        defined_addr := false;
        word_index := 0;
        addr := 0;

        if cs = '1' then
            addr := to_integer(unsigned(address));

            case addr is
                when 16#00# =>
                    defined_addr := true;
                    data_v := NAME0;

                when 16#01# =>
                    defined_addr := true;
                    data_v := NAME1;

                when 16#02# =>
                    defined_addr := true;
                    data_v := VERSION;

                when 16#08# =>
                    defined_addr := true;
                    data_v(0) := init_reg;
                    data_v(1) := next_reg;
                    data_v(2) := mode_reg;

                when 16#09# =>
                    defined_addr := true;
                    data_v(0) := core_ready;
                    data_v(1) := core_valid;

                when 16#10# to 16#1f# =>
                    defined_addr := true;
                    data_v := block_words(addr - 16#10#);

                when 16#20# to 16#27# =>
                    defined_addr := true;
                    word_index := addr - 16#20#;
                    data_v := core_digest(
                        255 - 32*word_index downto 224 - 32*word_index
                    );

                when others =>
                    null;
            end case;

            if not defined_addr then
                error <= '1';
            end if;

            if we = '0' then
                read_data <= data_v;
            end if;
        end if;
    end process;
end architecture rtl;
