library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity instr_reg is
    Port (
        clk   : in  STD_LOGIC;
        rst   : in  STD_LOGIC;
        fetch : in  STD_LOGIC_VECTOR(1 downto 0);
        data  : in  STD_LOGIC_VECTOR(7 downto 0);
        ins   : out STD_LOGIC_VECTOR(2 downto 0);
        ad1   : out STD_LOGIC_VECTOR(4 downto 0);
        ad2   : out STD_LOGIC_VECTOR(7 downto 0)
    );
end instr_reg;

architecture Behavioral of instr_reg is
    signal ins_p1 : STD_LOGIC_VECTOR(7 downto 0);
    signal ins_p2 : STD_LOGIC_VECTOR(7 downto 0);
begin

    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '0' then
                ins_p1 <= (others => '0');
                ins_p2 <= (others => '0');
            else
                case fetch is
                    when "01" =>
                        ins_p1 <= data;
                    when "10" =>
                        ins_p2 <= data;
                    when others =>
                        null;
                end case;
            end if;
        end if;
    end process;

    ins <= ins_p1(7 downto 5);
    ad1 <= ins_p1(4 downto 0);
    ad2 <= ins_p2;

end Behavioral;
