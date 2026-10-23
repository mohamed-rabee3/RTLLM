library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity fsm is
    Port (
        \IN\ : in STD_LOGIC;
        CLK  : in STD_LOGIC;
        RST  : in STD_LOGIC;
        MATCH: out STD_LOGIC
    );
end fsm;

architecture Behavioral of fsm is
    type state_type is (S0, S1, S2, S3, S4);
    signal state : state_type;
begin

    process(CLK, RST)
    begin
        if RST = '1' then
            state <= S0;
        elsif rising_edge(CLK) then
            case state is
                when S0 =>
                    if \IN\ = '1' then
                        state <= S1;
                    else
                        state <= S0;
                    end if;
                when S1 =>
                    if \IN\ = '0' then
                        state <= S2;
                    else
                        state <= S1;
                    end if;
                when S2 =>
                    if \IN\ = '0' then
                        state <= S3;
                    else
                        state <= S1;
                    end if;
                when S3 =>
                    if \IN\ = '1' then
                        state <= S4;
                    else
                        state <= S0;
                    end if;
                when S4 =>
                    if \IN\ = '1' then
                        state <= S1;
                    else
                        state <= S2;
                    end if;
                when others =>
                    state <= S0;
            end case;
        end if;
    end process;

    MATCH <= '1' when (RST = '0' and state = S4 and \IN\ = '1') else '0';

end Behavioral;
