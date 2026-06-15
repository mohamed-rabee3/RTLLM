library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity fsm is
    Port (
        IN    : in  STD_LOGIC;
        CLK   : in  STD_LOGIC;
        RST   : in  STD_LOGIC;
        MATCH : out STD_LOGIC
    );
end fsm;

architecture Behavioral of fsm is

    type state_type is (S0, S1, S2, S3, S4);
    signal current_state, next_state : state_type;

begin

    -- Synchronous state register with asynchronous reset
    process(CLK, RST)
    begin
        if (RST = '1') then
            current_state <= S0;
        elsif (rising_edge(CLK)) then
            current_state <= next_state;
        end if;
    end process;

    -- Mealy next state and output logic
    process(current_state, IN)
    begin
        -- Default values
        next_state <= current_state;
        MATCH <= '0';

        case current_state is
            when S0 =>
                if (IN = '1') then
                    next_state <= S1;
                else
                    next_state <= S0;
                end if;

            when S1 =>
                if (IN = '0') then
                    next_state <= S2;
                else
                    next_state <= S1;
                end if;

            when S2 =>
                if (IN = '0') then
                    next_state <= S3;
                else
                    next_state <= S1;
                end if;

            when S3 =>
                if (IN = '1') then
                    next_state <= S4;
                else
                    next_state <= S0;
                end if;

            when S4 =>
                if (IN = '1') then
                    next_state <= S1;
                    MATCH <= '1';
                else
                    next_state <= S2;
                end if;

            when others =>
                next_state <= S0;
        end case;
    end process;

end Behavioral;