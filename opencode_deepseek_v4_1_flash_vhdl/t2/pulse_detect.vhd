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
    type state_type is (IDLE, SAW_0, SAW_01);
    signal state : state_type;
begin
    process(clk, rst_n)
    begin
        if rst_n = '0' then
            state <= IDLE;
            data_out <= '0';
        elsif rising_edge(clk) then
            case state is
                when IDLE =>
                    if data_in = '0' then
                        state <= SAW_0;
                    else
                        state <= IDLE;
                    end if;
                    data_out <= '0';

                when SAW_0 =>
                    if data_in = '1' then
                        state <= SAW_01;
                    else
                        state <= SAW_0;
                    end if;
                    data_out <= '0';

                when SAW_01 =>
                    if data_in = '0' then
                        state <= SAW_0;
                        data_out <= '1';
                    else
                        state <= IDLE;
                        data_out <= '0';
                    end if;
            end case;
        end if;
    end process;
end rtl;
