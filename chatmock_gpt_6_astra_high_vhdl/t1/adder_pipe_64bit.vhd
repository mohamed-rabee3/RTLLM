library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity adder_pipe_64bit is
    port (
        clk    : in  std_logic;
        rst_n  : in  std_logic;
        i_en   : in  std_logic;
        adda   : in  std_logic_vector(63 downto 0);
        addb   : in  std_logic_vector(63 downto 0);
        result : out std_logic_vector(64 downto 0);
        o_en   : out std_logic
    );
end entity adder_pipe_64bit;

architecture rtl of adder_pipe_64bit is
    -- Four pipeline stages, each adding one 16-bit slice.
    signal valid_pipe : std_logic_vector(3 downto 0);

    signal a_stage1, b_stage1 : unsigned(47 downto 0);
    signal a_stage2, b_stage2 : unsigned(31 downto 0);
    signal a_stage3, b_stage3 : unsigned(15 downto 0);

    signal sum_stage1 : unsigned(15 downto 0);
    signal sum_stage2 : unsigned(31 downto 0);
    signal sum_stage3 : unsigned(47 downto 0);

    signal carry_stage1 : std_logic;
    signal carry_stage2 : std_logic;
    signal carry_stage3 : std_logic;

    signal result_reg : std_logic_vector(64 downto 0);
begin
    result <= result_reg;
    o_en   <= valid_pipe(3);

    process (clk, rst_n)
        variable sum1 : unsigned(16 downto 0);
        variable sum2 : unsigned(16 downto 0);
        variable sum3 : unsigned(16 downto 0);
        variable sum4 : unsigned(16 downto 0);
    begin
        if rst_n = '0' then
            valid_pipe  <= (others => '0');

            a_stage1    <= (others => '0');
            b_stage1    <= (others => '0');
            a_stage2    <= (others => '0');
            b_stage2    <= (others => '0');
            a_stage3    <= (others => '0');
            b_stage3    <= (others => '0');

            sum_stage1  <= (others => '0');
            sum_stage2  <= (others => '0');
            sum_stage3  <= (others => '0');

            carry_stage1 <= '0';
            carry_stage2 <= '0';
            carry_stage3 <= '0';

            result_reg  <= (others => '0');

        elsif rising_edge(clk) then
            valid_pipe <= valid_pipe(2 downto 0) & i_en;

            -- Stage 1: bits 15:0.
            sum1 := resize(unsigned(adda(15 downto 0)), 17)
                  + resize(unsigned(addb(15 downto 0)), 17);

            sum_stage1   <= sum1(15 downto 0);
            carry_stage1 <= sum1(16);
            a_stage1     <= unsigned(adda(63 downto 16));
            b_stage1     <= unsigned(addb(63 downto 16));

            -- Stage 2: bits 31:16.
            sum2 := resize(a_stage1(15 downto 0), 17)
                  + resize(b_stage1(15 downto 0), 17);
            if carry_stage1 = '1' then
                sum2 := sum2 + to_unsigned(1, 17);
            end if;

            sum_stage2   <= sum2(15 downto 0) & sum_stage1;
            carry_stage2 <= sum2(16);
            a_stage2     <= a_stage1(47 downto 16);
            b_stage2     <= b_stage1(47 downto 16);

            -- Stage 3: bits 47:32.
            sum3 := resize(a_stage2(15 downto 0), 17)
                  + resize(b_stage2(15 downto 0), 17);
            if carry_stage2 = '1' then
                sum3 := sum3 + to_unsigned(1, 17);
            end if;

            sum_stage3   <= sum3(15 downto 0) & sum_stage2;
            carry_stage3 <= sum3(16);
            a_stage3     <= a_stage2(31 downto 16);
            b_stage3     <= b_stage2(31 downto 16);

            -- Stage 4: bits 63:48 and final carry.
            sum4 := resize(a_stage3, 17)
                  + resize(b_stage3, 17);
            if carry_stage3 = '1' then
                sum4 := sum4 + to_unsigned(1, 17);
            end if;

            result_reg <= std_logic_vector(sum4 & sum_stage3);
        end if;
    end process;
end architecture rtl;
