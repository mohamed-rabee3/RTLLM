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
        x"6A09E667", x"BB67AE85", x"3C6EF372", x"A54FF53A",
        x"510E527F", x"9B05688C", x"1F83D9AB", x"5BE0CD19"
    );

    constant K : schedule_array_t := (
        x"428A2F98", x"71374491", x"B5C0FBCF", x"E9B5DBA5",
        x"3956C25B", x"59F111F1", x"923F82A4", x"AB1C5ED5",
        x"D807AA98", x"12835B01", x"243185BE", x"550C7DC3",
        x"72BE5D74", x"80DEB1FE", x"9BDC06A7", x"C19BF174",
        x"E49B69C1", x"EFBE4786", x"0FC19DC6", x"240CA1CC",
        x"2DE92C6F", x"4A7484AA", x"5CB0A9DC", x"76F988DA",
        x"983E5152", x"A831C66D", x"B00327C8", x"BF597FC7",
        x"C6E00BF3", x"D5A79147", x"06CA6351", x"14292967",
        x"27B70A85", x"2E1B2138", x"4D2C6DFC", x"53380D13",
        x"650A7354", x"766A0ABB", x"81C2C92E", x"92722C85",
        x"A2BFE8A1", x"A81A664B", x"C24B8B70", x"C76C51A3",
        x"D192E819", x"D6990624", x"F40E3585", x"106AA070",
        x"19A4C116", x"1E376C08", x"2748774C", x"34B0BCB5",
        x"391C0CB3", x"4ED8AA4A", x"5B9CCA4F", x"682E6FF3",
        x"748F82EE", x"78A5636F", x"84C87814", x"8CC70208",
        x"90BEFFFA", x"A4506CEB", x"BEF9A3F7", x"C67178F2"
    );

    type state_t is (IDLE, ROUNDS, FINISH);
    signal state_reg : state_t;
    signal round_reg : integer range 0 to 63;
    signal hash_reg  : hash_array_t;
    signal work_reg  : hash_array_t;
    signal w_reg     : schedule_array_t;
    signal valid_reg : std_logic;

    function big_sigma0(x : word_t) return word_t is
    begin
        return rotate_right(x, 2) xor
               rotate_right(x, 13) xor
               rotate_right(x, 22);
    end function;

    function big_sigma1(x : word_t) return word_t is
    begin
        return rotate_right(x, 6) xor
               rotate_right(x, 11) xor
               rotate_right(x, 25);
    end function;

    function small_sigma0(x : word_t) return word_t is
    begin
        return rotate_right(x, 7) xor
               rotate_right(x, 18) xor
               shift_right(x, 3);
    end function;

    function small_sigma1(x : word_t) return word_t is
    begin
        return rotate_right(x, 17) xor
               rotate_right(x, 19) xor
               shift_right(x, 10);
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
    -- The specified engine always computes SHA-256. The mode input is
    -- retained for interface compatibility.
    ready        <= '1' when state_reg = IDLE else '0';
    digest_valid <= valid_reg;

    digest_words : for i in 0 to 7 generate
        digest(255 - i * 32 downto 224 - i * 32) <=
            std_logic_vector(hash_reg(i));
    end generate;

    process(clk, reset_n)
        variable wt : word_t;
        variable t1 : word_t;
        variable t2 : word_t;
    begin
        if reset_n = '0' then
            state_reg <= IDLE;
            round_reg <= 0;
            hash_reg  <= (others => (others => '0'));
            work_reg  <= (others => (others => '0'));
            w_reg     <= (others => (others => '0'));
            valid_reg <= '0';
        elsif rising_edge(clk) then
            case state_reg is
                when IDLE =>
                    if init = '1' or \next\ = '1' then
                        valid_reg <= '0';
                        round_reg <= 0;

                        for i in 0 to 15 loop
                            w_reg(i) <= unsigned(
                                \block\(511 - i * 32 downto 480 - i * 32)
                            );
                        end loop;

                        if init = '1' then
                            hash_reg <= INITIAL_HASH;
                            work_reg <= INITIAL_HASH;
                        else
                            work_reg <= hash_reg;
                        end if;

                        state_reg <= ROUNDS;
                    end if;

                when ROUNDS =>
                    if round_reg < 16 then
                        wt := w_reg(round_reg);
                    else
                        wt := small_sigma1(w_reg(round_reg - 2)) +
                              w_reg(round_reg - 7) +
                              small_sigma0(w_reg(round_reg - 15)) +
                              w_reg(round_reg - 16);
                        w_reg(round_reg) <= wt;
                    end if;

                    t1 := work_reg(7) +
                          big_sigma1(work_reg(4)) +
                          choose(work_reg(4), work_reg(5), work_reg(6)) +
                          K(round_reg) + wt;

                    t2 := big_sigma0(work_reg(0)) +
                          majority(work_reg(0), work_reg(1), work_reg(2));

                    work_reg(0) <= t1 + t2;
                    work_reg(1) <= work_reg(0);
                    work_reg(2) <= work_reg(1);
                    work_reg(3) <= work_reg(2);
                    work_reg(4) <= work_reg(3) + t1;
                    work_reg(5) <= work_reg(4);
                    work_reg(6) <= work_reg(5);
                    work_reg(7) <= work_reg(6);

                    if round_reg = 63 then
                        state_reg <= FINISH;
                    else
                        round_reg <= round_reg + 1;
                    end if;

                when FINISH =>
                    for i in 0 to 7 loop
                        hash_reg(i) <= hash_reg(i) + work_reg(i);
                    end loop;
                    valid_reg <= '1';
                    state_reg <= IDLE;
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
    constant NAME0   : std_logic_vector(31 downto 0) := x"73686132";
    constant NAME1   : std_logic_vector(31 downto 0) := x"2D323536";
    constant VERSION : std_logic_vector(31 downto 0) := x"312E3830";

    signal block_reg        : std_logic_vector(511 downto 0);
    signal init_reg         : std_logic;
    signal next_reg         : std_logic;
    signal mode_reg         : std_logic;
    signal core_ready       : std_logic;
    signal core_valid       : std_logic;
    signal core_digest      : std_logic_vector(255 downto 0);
begin
    core_inst : entity work.sha256_core
        port map (
            clk          => clk,
            reset_n      => reset_n,
            init         => init_reg,
            \next\       => next_reg,
            mode         => mode_reg,
            \block\      => block_reg,
            ready        => core_ready,
            digest_valid => core_valid,
            digest       => core_digest
        );

    process(clk, reset_n)
        variable addr : integer range 0 to 255;
    begin
        if reset_n = '0' then
            block_reg <= (others => '0');
            init_reg  <= '0';
            next_reg  <= '0';
            mode_reg  <= '1';
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
                    block_reg(
                        511 - (addr - 16#10#) * 32 downto
                        480 - (addr - 16#10#) * 32
                    ) <= write_data;
                end if;
            end if;
        end if;
    end process;

    process(cs, we, address, block_reg, init_reg, next_reg, mode_reg,
            core_ready, core_valid, core_digest)
        variable addr    : integer range 0 to 255;
        variable defined : boolean;
        variable result  : std_logic_vector(31 downto 0);
    begin
        read_data <= (others => '0');
        error     <= '0';
        result    := (others => '0');
        defined   := true;

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
                    result(1) := core_valid;

                when 16#10# to 16#1F# =>
                    result := block_reg(
                        511 - (addr - 16#10#) * 32 downto
                        480 - (addr - 16#10#) * 32
                    );

                when 16#20# to 16#27# =>
                    result := core_digest(
                        255 - (addr - 16#20#) * 32 downto
                        224 - (addr - 16#20#) * 32
                    );

                when others =>
                    defined := false;
            end case;

            if not defined then
                error <= '1';
            elsif we = '0' then
                read_data <= result;
            end if;
        end if;
    end process;
end architecture rtl;
