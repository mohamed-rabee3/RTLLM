library ieee;
use ieee.std_logic_1164.all;

entity fsm is
    port (
        \IN\  : in  std_logic;
        CLK   : in  std_logic;
        RST   : in  std_logic;
        MATCH : out std_logic
    );
end entity fsm;

architecture rtl of fsm is
    type state_type is (IDLE, SEEN_1, SEEN_10, SEEN_100, SEEN_1001);
    signal state      : state_type;
    signal next_state : state_type;
begin
    process (CLK, RST)
    begin
        if RST = '1' then
            state <= IDLE;
        elsif rising_edge(CLK) then
            state <= next_state;
        end if;
    end process;

    process (state, \IN\, RST)
    begin
        next_state <= state;
        MATCH <= '0';

        if RST = '1' then
            next_state <= IDLE;
        else
            case state is
                when IDLE =>
                    if \IN\ = '1' then
                        next_state <= SEEN_1;
                    else
                        next_state <= IDLE;
                    end if;

                when SEEN_1 =>
                    if \IN\ = '0' then
                        next_state <= SEEN_10;
                    else
                        next_state <= SEEN_1;
                    end if;

                when SEEN_10 =>
                    if \IN\ = '0' then
                        next_state <= SEEN_100;
                    else
                        next_state <= SEEN_1;
                    end if;

                when SEEN_100 =>
                    if \IN\ = '1' then
                        next_state <= SEEN_1001;
                    else
                        next_state <= IDLE;
                    end if;

                when SEEN_1001 =>
                    if \IN\ = '1' then
                        MATCH <= '1';
                        next_state <= SEEN_1;
                    else
                        next_state <= SEEN_10;
                    end if;
            end case;
        end if;
    end process;
end architecture rtl;
