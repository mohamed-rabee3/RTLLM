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
    type word_array_t is array (0 to 63) of word_t;

    constant INITIAL_HASH : hash_array_t := (
        x"6A09E667", x"BB67AE85", x"3C6EF372", x"A54FF53A",
        x"510E527F", x"9B05688C", x"1F83D9AB", x"5BE0CD19"
    );

    constant K : word_array_t := (
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

    signal hash_state : hash_array_t;
    signal schedule   : word_array_t;
    signal a_reg      : word_t;
    signal b_reg      : word_t;
    signal c_reg      : word_t;
    signal d_reg      : word_t;
    signal e_reg      : word_t;
    signal f_reg      : word_t;
    signal g_reg      : word_t;
    signal h_reg      : word_t;
    signal round_reg  : integer range 0 to 63;
    signal busy_reg   : std_logic;
    signal valid_reg  : std_logic;
begin
    ready        <= not busy_reg;
    digest_valid <= valid_reg;

    digest_words : for i in 0 to 7 generate
        digest(255 - 32*i downto 224 - 32*i) <=
            std_logic_vector(hash_state(i));
    end generate;

    -- This engine implements SHA-256 for either value of the mode input.
    process(clk, reset_n)
        variable w_value : word_t;
        variable t1      : word_t;
        variable t2      : word_t;
    begin
        if reset_n = '0' then
            hash_state <= (others => (others => '0'));
            schedule   <= (others => (others => '0'));
            a_reg      <= (others => '0');
            b_reg      <= (others => '0');
            c_reg      <= (others => '0');
            d_reg      <= (others => '0');
            e_reg      <= (others => '0');
            f_reg      <= (others => '0');
            g_reg      <= (others => '0');
            h_reg      <= (others => '0');
            round_reg  <= 0;
            busy_reg   <= '0';
            valid_reg  <= '0';
        elsif rising_edge(clk) then
            if busy_reg = '0' then
                if init = '1' or \next\ = '1' then
                    for i in 0 to 15 loop
                        schedule(i) <=
                            unsigned(\block\(511 - 32*i downto 480 - 32*i));
                    end loop;

                    if init = '1' then
                        hash_state <= INITIAL_HASH;
                        a_reg <= INITIAL_HASH(0);
                        b_reg <= INITIAL_HASH(1);
                        c_reg <= INITIAL_HASH(2);
                        d_reg <= INITIAL_HASH(3);
                        e_reg <= INITIAL_HASH(4);
                        f_reg <= INITIAL_HASH(5);
                        g_reg <= INITIAL_HASH(6);
                        h_reg <= INITIAL_HASH(7);
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

                    round_reg <= 0;
                    busy_reg  <= '1';
                    valid_reg <= '0';
                end if;
            else
                if round_reg < 16 then
                    w_value := schedule(round_reg);
                else
                    w_value :=
                        small_sigma1(schedule(round_reg - 2)) +
                        schedule(round_reg - 7) +
                        small_sigma0(schedule(round_reg - 15)) +
                        schedule(round_reg - 16);
                    schedule(round_reg) <= w_value;
                end if;

                t1 := h_reg +
                      big_sigma1(e_reg) +
                      choose(e_reg, f_reg, g_reg) +
                      K(round_reg) +
                      w_value;

                t2 := big_sigma0(a_reg) +
                      majority(a_reg, b_reg, c_reg);

                a_reg <= t1 + t2;
                b_reg <= a_reg;
                c_reg <= b_reg;
                d_reg <= c_reg;
                e_reg <= d_reg + t1;
                f_reg <= e_reg;
                g_reg <= f_reg;
                h_reg <= g_reg;

                if round_reg = 63 then
                    hash_state(0) <= hash_state(0) + t1 + t2;
                    hash_state(1) <= hash_state(1) + a_reg;
                    hash_state(2) <= hash_state(2) + b_reg;
                    hash_state(3) <= hash_state(3) + c_reg;
                    hash_state(4) <= hash_state(4) + d_reg + t1;
                    hash_state(5) <= hash_state(5) + e_reg;
                    hash_state(6) <= hash_state(6) + f_reg;
                    hash_state(7) <= hash_state(7) + g_reg;

                    busy_reg  <= '0';
                    valid_reg <= '1';
                else
                    round_reg <= round_reg + 1;
                end if;
            end if;
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

    type block_array_t is array (0 to 15) of
        std_logic_vector(31 downto 0);

    signal block_reg  : block_array_t;
    signal core_block : std_logic_vector(511 downto 0);
    signal init_reg   : std_logic;
    signal next_reg   : std_logic;
    signal mode_reg   : std_logic;
    signal core_ready : std_logic;
    signal core_valid : std_logic;
    signal core_hash  : std_logic_vector(255 downto 0);
begin
    block_words : for i in 0 to 15 generate
        core_block(511 - 32*i downto 480 - 32*i) <= block_reg(i);
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
            digest       => core_hash
        );

    process(clk, reset_n)
        variable addr : integer range 0 to 255;
    begin
        if reset_n = '0' then
            block_reg <= (others => (others => '0'));
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
                    block_reg(addr - 16#10#) <= write_data;
                end if;
            end if;
        end if;
    end process;

    process(cs, we, address, block_reg, init_reg, next_reg,
            mode_reg, core_ready, core_valid, core_hash)
        variable addr       : integer range 0 to 255;
        variable result     : std_logic_vector(31 downto 0);
        variable defined    : boolean;
        variable word_index : integer range 0 to 7;
    begin
        result  := (others => '0');
        defined := false;
        error   <= '0';

        if cs = '1' then
            addr := to_integer(unsigned(address));

            case addr is
                when 16#00# =>
                    defined := true;
                    result := NAME0;

                when 16#01# =>
                    defined := true;
                    result := NAME1;

                when 16#02# =>
                    defined := true;
                    result := VERSION;

                when 16#08# =>
                    defined := true;
                    result(0) := init_reg;
                    result(1) := next_reg;
                    result(2) := mode_reg;

                when 16#09# =>
                    defined := true;
                    result(0) := core_ready;
                    result(1) := core_valid;

                when 16#10# to 16#1F# =>
                    defined := true;
                    result := block_reg(addr - 16#10#);

                when 16#20# to 16#27# =>
                    defined := true;
                    word_index := addr - 16#20#;
                    result := core_hash(
                        255 - 32*word_index downto
                        224 - 32*word_index
                    );

                when others =>
                    null;
            end case;

            if not defined then
                error <= '1';
            end if;
        end if;

        if cs = '1' and we = '0' then
            read_data <= result;
        else
            read_data <= (others => '0');
        end if;
    end process;
end architecture rtl;
