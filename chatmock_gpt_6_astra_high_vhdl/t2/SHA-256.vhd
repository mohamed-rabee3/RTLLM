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
    type hash_array_t is array (0 to 7) of word_t;
    type schedule_array_t is array (0 to 63) of word_t;

    constant INITIAL_HASH : hash_array_t := (
        x"6a09e667", x"bb67ae85", x"3c6ef372", x"a54ff53a",
        x"510e527f", x"9b05688c", x"1f83d9ab", x"5be0cd19"
    );

    constant K : schedule_array_t := (
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

    type state_t is (IDLE, COMPRESS, ACCUMULATE);
    signal state        : state_t;
    signal hash_state   : hash_array_t;
    signal work_state   : hash_array_t;
    signal schedule     : schedule_array_t;
    signal round_index  : integer range 0 to 63;
    signal valid_reg    : std_logic;

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
begin
    -- The specified engine implements SHA-256 for either mode input value.
    ready        <= '1' when state = IDLE else '0';
    digest_valid <= valid_reg;

    digest_words : for i in 0 to 7 generate
        digest(255 - 32*i downto 224 - 32*i) <=
            std_logic_vector(hash_state(i));
    end generate;

    process (clk, reset_n)
        variable current_word : word_t;
        variable temp1        : word_t;
        variable temp2        : word_t;
    begin
        if reset_n = '0' then
            state       <= IDLE;
            hash_state  <= (others => (others => '0'));
            work_state  <= (others => (others => '0'));
            schedule    <= (others => (others => '0'));
            round_index <= 0;
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
                            hash_state <= INITIAL_HASH;
                            work_state <= INITIAL_HASH;
                        else
                            work_state <= hash_state;
                        end if;

                        state <= COMPRESS;
                    end if;

                when COMPRESS =>
                    if round_index < 16 then
                        current_word := schedule(round_index);
                    else
                        current_word :=
                            small_sigma1(schedule(round_index - 2)) +
                            schedule(round_index - 7) +
                            small_sigma0(schedule(round_index - 15)) +
                            schedule(round_index - 16);
                        schedule(round_index) <= current_word;
                    end if;

                    temp1 := work_state(7) +
                             big_sigma1(work_state(4)) +
                             choose(work_state(4), work_state(5), work_state(6)) +
                             K(round_index) + current_word;

                    temp2 := big_sigma0(work_state(0)) +
                             majority(work_state(0), work_state(1), work_state(2));

                    work_state(0) <= temp1 + temp2;
                    work_state(1) <= work_state(0);
                    work_state(2) <= work_state(1);
                    work_state(3) <= work_state(2);
                    work_state(4) <= work_state(3) + temp1;
                    work_state(5) <= work_state(4);
                    work_state(6) <= work_state(5);
                    work_state(7) <= work_state(6);

                    if round_index = 63 then
                        state <= ACCUMULATE;
                    else
                        round_index <= round_index + 1;
                    end if;

                when ACCUMULATE =>
                    for i in 0 to 7 loop
                        hash_state(i) <= hash_state(i) + work_state(i);
                    end loop;
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
    type block_array_t is array (0 to 15) of std_logic_vector(31 downto 0);

    constant NAME0   : std_logic_vector(31 downto 0) := x"73686132";
    constant NAME1   : std_logic_vector(31 downto 0) := x"2d323536";
    constant VERSION : std_logic_vector(31 downto 0) := x"312e3830";

    signal block_regs        : block_array_t;
    signal block_bus         : std_logic_vector(511 downto 0);
    signal init_reg          : std_logic;
    signal next_reg          : std_logic;
    signal mode_reg          : std_logic;
    signal core_ready        : std_logic;
    signal core_digest_valid : std_logic;
    signal core_digest       : std_logic_vector(255 downto 0);
begin
    block_words : for i in 0 to 15 generate
        block_bus(511 - 32*i downto 480 - 32*i) <= block_regs(i);
    end generate;

    core_inst : entity work.sha256_core(rtl)
        port map (
            clk          => clk,
            reset_n      => reset_n,
            init         => init_reg,
            \next\       => next_reg,
            mode         => mode_reg,
            \block\      => block_bus,
            ready        => core_ready,
            digest_valid => core_digest_valid,
            digest       => core_digest
        );

    process (clk, reset_n)
        variable addr : integer range 0 to 255;
    begin
        if reset_n = '0' then
            block_regs <= (others => (others => '0'));
            init_reg   <= '0';
            next_reg   <= '0';
            mode_reg   <= '0';
        elsif rising_edge(clk) then
            init_reg <= '0';
            next_reg <= '0';

            if cs = '1' and we = '1' then
                addr := to_integer(unsigned(address));
                if addr = 16#08# then
                    init_reg <= write_data(0);
                    next_reg <= write_data(1);
                    mode_reg <= write_data(2);
                elsif addr >= 16#10# and addr <= 16#1F# then
                    block_regs(addr - 16#10#) <= write_data;
                end if;
            end if;
        end if;
    end process;

    process (
        cs, we, address, block_regs, init_reg, next_reg, mode_reg,
        core_ready, core_digest_valid, core_digest
    )
        variable addr         : integer range 0 to 255;
        variable word_index   : integer range 0 to 7;
        variable defined_addr : boolean;
        variable result       : std_logic_vector(31 downto 0);
    begin
        read_data    <= (others => '0');
        error        <= '0';
        result       := (others => '0');
        defined_addr := true;
        addr         := 0;
        word_index   := 0;

        if cs = '1' then
            addr := to_integer(unsigned(address));

            case addr is
                when 16#00# =>
                    result := NAME0;

                when 16#01# =>
                    result := NAME1;

                when 16#02# =>
                    result := VERSION;

                when 16#08# =>
                    result(0) := init_reg;
                    result(1) := next_reg;
                    result(2) := mode_reg;

                when 16#09# =>
                    result(0) := core_ready;
                    result(1) := core_digest_valid;

                when 16#10# to 16#1F# =>
                    result := block_regs(addr - 16#10#);

                when 16#20# to 16#27# =>
                    word_index := addr - 16#20#;
                    result := core_digest(
                        255 - 32*word_index downto 224 - 32*word_index
                    );

                when others =>
                    defined_addr := false;
            end case;

            if not defined_addr then
                error <= '1';
            end if;

            if we = '0' then
                read_data <= result;
            end if;
        end if;
    end process;
end architecture rtl;
