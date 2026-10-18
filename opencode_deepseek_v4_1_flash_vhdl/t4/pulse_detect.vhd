library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity pulse_detect is
    Port ( clk     : in  STD_LOGIC;
           rst_n   : in  STD_LOGIC;
           data_in : in  STD_LOGIC;
           data_out: out STD_LOGIC);
end pulse_detect;

architecture rtl of pulse_detect is
    type state_type is (S0, S1, S2);
    signal state : state_type;
begin

    process(clk, rst_n)
    begin
        if rst_n = '0' then
            state <= S0;
        elsif rising_edge(clk) then
            case state is
                when S0 =>
                    if data_in = '0' then
                        state <= S1;
                    else
                        state <= S0;
                    end if;
                when S1 =>
                    if data_in = '1' then
                        state <= S2;
                    else
                        state <= S1;
                    end if;
                when S2 =>
                    if data_in = '0' then
                        state <= S1;
                    else
                        state <= S0;
                    end if;
                when others =>
                    state <= S0;
            end case;
        end if;
    end process;

    data_out <= '1' when (state = S2 and data_in = '0') else '0';

end rtl;
