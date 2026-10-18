library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity fsm is
    Port (
        \IN\   : in  STD_LOGIC;
        CLK    : in  STD_LOGIC;
        RST    : in  STD_LOGIC;
        MATCH  : out STD_LOGIC
    );
end fsm;

architecture rtl of fsm is
    type state_type is (S0, S1, S2, S3, S4);
    signal state, next_state : state_type;
begin

    process(CLK, RST)
    begin
        if RST = '1' then
            state <= S0;
        elsif rising_edge(CLK) then
            state <= next_state;
        end if;
    end process;

    process(state, \IN\)
    begin
        next_state <= state;
        case state is
            when S0 =>
                if \IN\ = '1' then
                    next_state <= S1;
                else
                    next_state <= S0;
                end if;
            when S1 =>
                if \IN\ = '0' then
                    next_state <= S2;
                else
                    next_state <= S1;
                end if;
            when S2 =>
                if \IN\ = '0' then
                    next_state <= S3;
                else
                    next_state <= S1;
                end if;
            when S3 =>
                if \IN\ = '1' then
                    next_state <= S4;
                else
                    next_state <= S0;
                end if;
            when S4 =>
                if \IN\ = '1' then
                    next_state <= S1;
                else
                    next_state <= S2;
                end if;
            when others =>
                next_state <= S0;
        end case;
    end process;

    process(state, \IN\, RST)
    begin
        if RST = '1' then
            MATCH <= '0';
        else
            if (state = S4 and \IN\ = '1') then
                MATCH <= '1';
            else
                MATCH <= '0';
            end if;
        end if;
    end process;

end rtl;
