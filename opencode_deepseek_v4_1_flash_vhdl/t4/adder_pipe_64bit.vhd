library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity adder_pipe_64bit is
    Port (
        clk    : in  std_logic;
        rst_n  : in  std_logic;
        i_en   : in  std_logic;
        adda   : in  std_logic_vector(63 downto 0);
        addb   : in  std_logic_vector(63 downto 0);
        result : out std_logic_vector(64 downto 0);
        o_en   : out std_logic
    );
end adder_pipe_64bit;

architecture rtl of adder_pipe_64bit is
    signal en_pipe : std_logic_vector(3 downto 0);
    signal sum1, sum2, sum3, sum4 : unsigned(16 downto 0);
begin
    process(clk, rst_n)
        variable c1, c2, c3 : unsigned(16 downto 0);
    begin
        if rst_n = '0' then
            en_pipe <= (others => '0');
            sum1 <= (others => '0');
            sum2 <= (others => '0');
            sum3 <= (others => '0');
            sum4 <= (others => '0');
        elsif rising_edge(clk) then
            en_pipe <= en_pipe(2 downto 0) & i_en;

            sum1 <= resize(unsigned(adda(15 downto 0)), 17) + resize(unsigned(addb(15 downto 0)), 17);

            c1 := (others => '0');
            c1(0) := sum1(16);
            sum2 <= resize(unsigned(adda(31 downto 16)), 17) + resize(unsigned(addb(31 downto 16)), 17) + c1;

            c2 := (others => '0');
            c2(0) := sum2(16);
            sum3 <= resize(unsigned(adda(47 downto 32)), 17) + resize(unsigned(addb(47 downto 32)), 17) + c2;

            c3 := (others => '0');
            c3(0) := sum3(16);
            sum4 <= resize(unsigned(adda(63 downto 48)), 17) + resize(unsigned(addb(63 downto 48)), 17) + c3;
        end if;
    end process;

    process(clk, rst_n)
    begin
        if rst_n = '0' then
            result <= (others => '0');
            o_en <= '0';
        elsif rising_edge(clk) then
            result <= sum4(16) & std_logic_vector(sum4(15 downto 0)) &
                      std_logic_vector(sum3(15 downto 0)) &
                      std_logic_vector(sum2(15 downto 0)) &
                      std_logic_vector(sum1(15 downto 0));
            o_en <= en_pipe(3);
        end if;
    end process;
end rtl;
