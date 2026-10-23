library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity pulse_detect is
    Port (
        clk      : in  STD_LOGIC;
        rst_n    : in  STD_LOGIC;
        data_in  : in  STD_LOGIC;
        data_out : out STD_LOGIC
    );
end pulse_detect;

architecture rtl of pulse_detect is
    type state_type is (IDLE, GOT0, GOT01);
    signal state : state_type;
begin
    process(clk, rst_n)
    begin
        if rst_n = '0' then
            state    <= IDLE;
            data_out <= '0';
        elsif rising_edge(clk) then
            case state is
                when IDLE =>
                    data_out <= '0';
                    if data_in = '0' then
                        state <= GOT0;
                    else
                        state <= IDLE;
                    end if;

                when GOT0 =>
                    data_out <= '0';
                    if data_in = '1' then
                        state <= GOT01;
                    else
                        state <= GOT0;
                    end if;

                when GOT01 =>
                    if data_in = '0' then
                        data_out <= '1';
                        state    <= GOT0;
                    else
                        data_out <= '0';
                        state    <= IDLE;
                    end if;
            end case;
        end if;
    end process;
end rtl;
