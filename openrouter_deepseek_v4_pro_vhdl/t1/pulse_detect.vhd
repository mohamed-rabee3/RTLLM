library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity pulse_detect is
    port (
        clk      : in  std_logic;
        rst_n    : in  std_logic;
        data_in  : in  std_logic;
        data_out : out std_logic
    );
end pulse_detect;

architecture behavioral of pulse_detect is
    type state_type is (S0, S1, S2);  -- S0: wait for 0, S1: got 0, S2: got 1
    signal state : state_type;
begin

    process (clk, rst_n)
    begin
        if rst_n = '0' then
            state    <= S0;
            data_out <= '0';
        elsif rising_edge(clk) then
            -- Default assignment
            data_out <= '0';
            
            case state is
                when S0 =>
                    -- Waiting for a 0 to start a possible pulse
                    if data_in = '0' then
                        state <= S1;
                    else
                        state <= S0;
                    end if;
                    
                when S1 =>
                    -- Got a 0, waiting for a 1
                    if data_in = '1' then
                        state <= S2;
                    else
                        state <= S1;
                    end if;
                    
                when S2 =>
                    -- Got a 1, waiting for a 0 to complete the pulse
                    if data_in = '0' then
                        state    <= S1;   -- back to having a 0 (can start next pulse)
                        data_out <= '1';  -- pulse detected
                    else
                        state <= S0;       -- 1 stayed high, invalid pulse, wait for 0 again
                    end if;
                    
                when others =>
                    state <= S0;
            end case;
        end if;
    end process;

end behavioral;