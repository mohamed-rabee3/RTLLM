library IEEE;
use IEEE.std_logic_1164.all;

entity LFSR is
    port (
        clk   : in  std_logic;
        rst   : in  std_logic;
        -- 'out' is a VHDL reserved word; using an extended identifier to meet the specification
        \out\ : out std_logic_vector(3 downto 0)
    );
end LFSR;

architecture Behavioral of LFSR is
    signal reg_val : std_logic_vector(3 downto 0) := (others => '0');
begin
    -- Drive the output port with the current register state
    \out\ <= reg_val;

    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                -- Active high reset: initialize register to zero
                reg_val <= (others => '0');
            else
                -- Left shift: new MSB gets old bit[2], ... , LSB gets feedback
                -- feedback = NOT (reg_val[3] XOR reg_val[2])
                reg_val <= reg_val(2 downto 0) & (not (reg_val(3) xor reg_val(2)));
            end if;
        end if;
    end process;
end Behavioral;