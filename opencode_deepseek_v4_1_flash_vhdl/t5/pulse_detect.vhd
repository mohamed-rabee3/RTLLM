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
    type state_t is (S0, S1, S2);
    signal state : state_t;
begin
    process(clk, rst_n)
    begin
        if rst_n = '0' then
            state <= S0;
            data_out <= '0';
        elsif rising_edge(clk) then
            case state is
                when S0 =>
                    data_out <= '0';
                    if data_in = '0' then
                        state <= S1;
                    else
                        state <= S0;
                    end if;

                when S1 =>
                    data_out <= '0';
                    if data_in = '1' then
                        state <= S2;
                    else
                        state <= S1;
                    end if;

                when S2 =>
                    if data_in = '0' then
                        data_out <= '1';
                        state <= S1;
                    else
                        data_out <= '0';
                        state <= S0;
                    end if;
            end case;
        end if;
    end process;
end rtl;
