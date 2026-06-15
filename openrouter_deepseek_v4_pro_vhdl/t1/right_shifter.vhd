library ieee;
use ieee.std_logic_1164.all;

entity right_shifter is
    port (
        clk : in  std_logic;
        d   : in  std_logic;
        q   : out std_logic_vector(7 downto 0)
    );
end entity right_shifter;

architecture rtl of right_shifter is
    -- 8-bit register initialised to 0 (equivalent to Verilog initial statement)
    signal q_reg : std_logic_vector(7 downto 0) := (others => '0');
begin

    shift_process : process(clk)
    begin
        if rising_edge(clk) then
            -- Right-shift by one: q(6 downto 0) go to q(7 downto 1), MSB gets d
            q_reg <= d & q_reg(7 downto 1);
        end if;
    end process shift_process;

    -- Drive output
    q <= q_reg;

end architecture rtl;