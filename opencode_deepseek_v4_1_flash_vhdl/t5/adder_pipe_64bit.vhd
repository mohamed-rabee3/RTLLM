library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity adder_pipe_64bit is
    Port ( clk : in STD_LOGIC;
           rst_n : in STD_LOGIC;
           i_en : in STD_LOGIC;
           adda : in STD_LOGIC_VECTOR (63 downto 0);
           addb : in STD_LOGIC_VECTOR (63 downto 0);
           result : out STD_LOGIC_VECTOR (64 downto 0);
           o_en : out STD_LOGIC);
end adder_pipe_64bit;

architecture Behavioral of adder_pipe_64bit is
    signal a1, a2, a3, a4 : std_logic_vector(15 downto 0);
    signal b1, b2, b3, b4 : std_logic_vector(15 downto 0);
    signal sum1, sum2, sum3, sum4 : std_logic_vector(16 downto 0);
    signal en1, en2, en3, en4 : std_logic;
begin
    process(clk, rst_n)
    begin
        if rst_n = '0' then
            a1 <= (others => '0');
            b1 <= (others => '0');
            en1 <= '0';
            a2 <= (others => '0');
            b2 <= (others => '0');
            en2 <= '0';
            a3 <= (others => '0');
            b3 <= (others => '0');
            en3 <= '0';
            a4 <= (others => '0');
            b4 <= (others => '0');
            en4 <= '0';
            sum1 <= (others => '0');
            sum2 <= (others => '0');
            sum3 <= (others => '0');
            sum4 <= (others => '0');
            result <= (others => '0');
            o_en <= '0';
        elsif rising_edge(clk) then
            en1 <= i_en;
            a1 <= adda(15 downto 0);
            b1 <= addb(15 downto 0);
            sum1 <= ('0' & a1) + ('0' & b1);
            
            en2 <= en1;
            a2 <= adda(31 downto 16);
            b2 <= addb(31 downto 16);
            sum2 <= ('0' & a2) + ('0' & b2) + sum1(16);
            
            en3 <= en2;
            a3 <= adda(47 downto 32);
            b3 <= addb(47 downto 32);
            sum3 <= ('0' & a3) + ('0' & b3) + sum2(16);
            
            en4 <= en3;
            a4 <= adda(63 downto 48);
            b4 <= addb(63 downto 48);
            sum4 <= ('0' & a4) + ('0' & b4) + sum3(16);
            
            result <= sum4(16) & sum4(15 downto 0) & sum3(15 downto 0) & sum2(15 downto 0) & sum1(15 downto 0);
            o_en <= en4;
        end if;
    end process;
end Behavioral;
