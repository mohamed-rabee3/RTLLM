library ieee;
use ieee.std_logic_1164.all;

entity pulse_detect is
    port (
        clk      : in  std_logic;
        rst_n    : in  std_logic;
        data_in  : in  std_logic;
        data_out : out std_logic
    );
end entity pulse_detect;

architecture rtl of pulse_detect is
    type state_type is (INITIAL, SEEN_ZERO, SEEN_ZERO_ONE);
    signal state : state_type;
begin
    process (clk, rst_n)
    begin
        if rst_n = '0' then
            state    <= INITIAL;
            data_out <= '0';
        elsif rising_edge(clk) then
            data_out <= '0';

            case state is
                when INITIAL =>
                    if data_in = '0' then
                        state <= SEEN_ZERO;
                    else
                        state <= INITIAL;
                    end if;

                when SEEN_ZERO =>
                    if data_in = '1' then
                        state <= SEEN_ZERO_ONE;
                    else
                        state <= SEEN_ZERO;
                    end if;

                when SEEN_ZERO_ONE =>
                    if data_in = '0' then
                        data_out <= '1';
                        state    <= SEEN_ZERO;
                    else
                        state <= INITIAL;
                    end if;
            end case;
        end if;
    end process;
end architecture rtl;
