library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity accu is
    Port (
        clk       : in  STD_LOGIC;
        rst_n     : in  STD_LOGIC;
        data_in   : in  STD_LOGIC_VECTOR(7 downto 0);
        valid_in  : in  STD_LOGIC;
        valid_out : out STD_LOGIC;
        data_out  : out STD_LOGIC_VECTOR(9 downto 0)
    );
end accu;

architecture rtl of accu is
    signal count : unsigned(1 downto 0);
    signal acc   : unsigned(9 downto 0);
begin

    process(clk, rst_n)
    begin
        if rst_n = '0' then
            count     <= (others => '0');
            acc       <= (others => '0');
            valid_out <= '0';
            data_out  <= (others => '0');
        elsif rising_edge(clk) then
            valid_out <= '0';

            if valid_in = '1' then
                if count = 3 then
                    data_out  <= std_logic_vector(acc + resize(unsigned(data_in), 10));
                    acc       <= (others => '0');
                    count     <= (others => '0');
                    valid_out <= '1';
                else
                    acc   <= acc + resize(unsigned(data_in), 10);
                    count <= count + 1;
                end if;
            end if;
        end if;
    end process;

end rtl;
