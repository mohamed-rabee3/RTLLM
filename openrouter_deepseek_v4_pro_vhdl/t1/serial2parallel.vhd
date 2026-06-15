library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity serial2parallel is
    port (
        clk          : in  std_logic;
        rst_n        : in  std_logic;
        din_serial   : in  std_logic;
        din_valid    : in  std_logic;
        dout_parallel: out std_logic_vector(7 downto 0);
        dout_valid   : out std_logic
    );
end serial2parallel;

architecture behavioral of serial2parallel is
    -- 4-bit counter to track the number of received bits (0 to 7)
    signal cnt : unsigned(3 downto 0);
begin
    process(clk)
        -- Shift register to assemble the parallel output
        variable shift_reg : std_logic_vector(7 downto 0);
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                -- Active-low reset: clear all registers and outputs
                shift_reg := (others => '0');
                cnt <= (others => '0');
                dout_parallel <= (others => '0');
                dout_valid <= '0';
            else
                -- Default dout_valid to '0'; overridden when a full byte is ready
                dout_valid <= '0';

                if din_valid = '1' then
                    -- Shift in the new serial bit. This order places the first
                    -- received bit at the MSB and the last at the LSB.
                    shift_reg := shift_reg(6 downto 0) & din_serial;

                    if cnt = 7 then
                        -- 8 bits have been received: output the assembled byte
                        dout_parallel <= shift_reg;
                        dout_valid <= '1';
                        cnt <= (others => '0');
                        -- Clear the shift register for the next byte
                        shift_reg := (others => '0');
                    else
                        cnt <= cnt + 1;
                    end if;
                end if;
            end if;
        end if;
    end process;
end behavioral;