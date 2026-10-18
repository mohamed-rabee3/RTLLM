library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity adder_pipe_64bit is
    Port ( clk    : in  STD_LOGIC;
           rst_n  : in  STD_LOGIC;
           i_en   : in  STD_LOGIC;
           adda   : in  STD_LOGIC_VECTOR (63 downto 0);
           addb   : in  STD_LOGIC_VECTOR (63 downto 0);
           result : out STD_LOGIC_VECTOR (64 downto 0);
           o_en   : out STD_LOGIC);
end adder_pipe_64bit;

architecture Behavioral of adder_pipe_64bit is
    signal sum1, sum2, sum3, sum4 : std_logic_vector(64 downto 0);
    signal en                     : std_logic_vector(3 downto 0);
    signal result_reg             : std_logic_vector(64 downto 0);
    signal o_en_reg               : std_logic;
begin
    process(clk, rst_n)
    begin
        if rst_n = '0' then
            sum1       <= (others => '0');
            sum2       <= (others => '0');
            sum3       <= (others => '0');
            sum4       <= (others => '0');
            en         <= (others => '0');
            result_reg <= (others => '0');
            o_en_reg   <= '0';
        elsif rising_edge(clk) then
            sum1 <= std_logic_vector(resize(unsigned(adda), 65) + resize(unsigned(addb), 65));
            sum2 <= sum1;
            sum3 <= sum2;
            sum4 <= sum3;
            en   <= en(2 downto 0) & i_en;
            result_reg <= sum4;
            o_en_reg   <= en(3);
        end if;
    end process;

    result <= result_reg;
    o_en   <= o_en_reg;
end Behavioral;
