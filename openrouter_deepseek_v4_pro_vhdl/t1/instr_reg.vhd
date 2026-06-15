library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity instr_reg is
    port (
        clk   : in  std_logic;
        rst   : in  std_logic;
        fetch : in  std_logic_vector(1 downto 0);
        data  : in  std_logic_vector(7 downto 0);
        ins   : out std_logic_vector(2 downto 0);
        ad1   : out std_logic_vector(4 downto 0);
        ad2   : out std_logic_vector(7 downto 0)
    );
end entity instr_reg;

architecture rtl of instr_reg is

    signal ins_p1 : std_logic_vector(7 downto 0);
    signal ins_p2 : std_logic_vector(7 downto 0);

begin

    -- Register update process
    process (clk, rst)
    begin
        if rst = '0' then
            ins_p1 <= (others => '0');
            ins_p2 <= (others => '0');
        elsif rising_edge(clk) then
            case fetch is
                when "01" =>   -- fetch from data into ins_p1
                    ins_p1 <= data;
                when "10" =>   -- fetch from data into ins_p2
                    ins_p2 <= data;
                when others =>
                    -- retain previous values (no assignment needed)
                    null;
            end case;
        end if;
    end process;

    -- Output assignments
    ins <= ins_p1(7 downto 5);
    ad1 <= ins_p1(4 downto 0);
    ad2 <= ins_p2;

end architecture rtl;