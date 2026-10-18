library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity accu is
    Port (
        clk       : in  std_logic;
        rst_n     : in  std_logic;
        data_in   : in  std_logic_vector(7 downto 0);
        valid_in  : in  std_logic;
        valid_out : out std_logic;
        data_out  : out std_logic_vector(9 downto 0)
    );
end accu;

architecture rtl of accu is
    signal acc       : unsigned(9 downto 0) := (others => '0');
    signal count     : unsigned(2 downto 0) := (others => '0');
    signal data_reg  : std_logic_vector(9 downto 0) := (others => '0');
    signal valid_reg : std_logic := '0';
begin

    data_out  <= data_reg;
    valid_out <= valid_reg;

    process(clk, rst_n)
    begin
        if rst_n = '0' then
            acc       <= (others => '0');
            count     <= (others => '0');
            data_reg  <= (others => '0');
            valid_reg <= '0';
        elsif rising_edge(clk) then
            valid_reg <= '0';

            if valid_in = '1' then
                if count = 3 then
                    data_reg  <= std_logic_vector(acc + resize(unsigned(data_in), 10));
                    valid_reg <= '1';
                    acc       <= (others => '0');
                    count     <= (others => '0');
                else
                    acc   <= acc + resize(unsigned(data_in), 10);
                    count <= count + 1;
                end if;
            end if;
        end if;
    end process;

end rtl;
