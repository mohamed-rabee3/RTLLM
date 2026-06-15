library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity accu is
    port (
        clk       : in  std_logic;
        rst_n     : in  std_logic;
        data_in   : in  std_logic_vector(7 downto 0);
        valid_in  : in  std_logic;
        valid_out : out std_logic;
        data_out  : out std_logic_vector(9 downto 0)
    );
end entity accu;

architecture rtl of accu is
begin
    process(clk, rst_n)
        variable acc : unsigned(9 downto 0);
        variable cnt : integer range 0 to 3;
    begin
        if rst_n = '0' then
            -- asynchronous active-low reset
            acc := (others => '0');
            cnt := 0;
            valid_out <= '0';
            data_out  <= (others => '0');
        elsif rising_edge(clk) then
            valid_out <= '0';   -- default; overwritten only when a group completes

            if valid_in = '1' then
                if cnt = 3 then
                    -- 4th valid input: compute sum including current data, output result
                    data_out  <= std_logic_vector(acc + unsigned(data_in));
                    valid_out <= '1';
                    -- reset accumulator and counter for the next group of 4
                    acc := (others => '0');
                    cnt := 0;
                else
                    -- accumulate current data and increment counter
                    acc := acc + unsigned(data_in);
                    cnt := cnt + 1;
                end if;
            end if;
        end if;
    end process;
end architecture rtl;