library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity pulse_detect is
    Port (
        clk      : in  std_logic;
        rst_n    : in  std_logic;
        data_in  : in  std_logic;
        data_out : out std_logic
    );
end pulse_detect;

architecture rtl of pulse_detect is
    type state_type is (IDLE, SEEN_0, SEEN_01);
    signal state : state_type;
begin
    process(clk, rst_n)
    begin
        if rst_n = '0' then
            state    <= IDLE;
            data_out <= '0';
        elsif rising_edge(clk) then
            data_out <= '0';

            case state is
                when IDLE =>
                    if data_in = '0' then
                        state <= SEEN_0;
                    else
                        state <= IDLE;
                    end if;

                when SEEN_0 =>
                    if data_in = '1' then
                        state <= SEEN_01;
                    else
                        state <= SEEN_0;
                    end if;

                when SEEN_01 =>
                    if data_in = '0' then
                        data_out <= '1';
                        state    <= SEEN_0;
                    else
                        state    <= IDLE;
                    end if;

                when others =>
                    state <= IDLE;
            end case;
        end if;
    end process;
end rtl;
