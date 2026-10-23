library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity synchronizer is
    Port (
        clk_a   : in  STD_LOGIC;
        clk_b   : in  STD_LOGIC;
        arstn   : in  STD_LOGIC;
        brstn   : in  STD_LOGIC;
        data_in : in  STD_LOGIC_VECTOR(3 downto 0);
        data_en : in  STD_LOGIC;
        dataout : out STD_LOGIC_VECTOR(3 downto 0)
    );
end synchronizer;

architecture rtl of synchronizer is
    signal data_reg    : STD_LOGIC_VECTOR(3 downto 0);
    signal en_data_reg : STD_LOGIC;
    signal en_clap_one : STD_LOGIC;
    signal en_clap_two : STD_LOGIC;
begin

    process(clk_a, arstn)
    begin
        if arstn = '0' then
            data_reg <= (others => '0');
        elsif rising_edge(clk_a) then
            data_reg <= data_in;
        end if;
    end process;

    process(clk_a, arstn)
    begin
        if arstn = '0' then
            en_data_reg <= '0';
        elsif rising_edge(clk_a) then
            en_data_reg <= data_en;
        end if;
    end process;

    process(clk_b, brstn)
    begin
        if brstn = '0' then
            en_clap_one <= '0';
            en_clap_two <= '0';
        elsif rising_edge(clk_b) then
            en_clap_one <= en_data_reg;
            en_clap_two <= en_clap_one;
        end if;
    end process;

    process(clk_b, brstn)
    begin
        if brstn = '0' then
            dataout <= (others => '0');
        elsif rising_edge(clk_b) then
            if en_clap_two = '1' then
                dataout <= data_reg;
            end if;
        end if;
    end process;

end rtl;
