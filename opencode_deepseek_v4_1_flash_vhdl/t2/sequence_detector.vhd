library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity sequence_detector is
    Port (
        clk               : in  STD_LOGIC;
        reset_n           : in  STD_LOGIC;
        data_in           : in  STD_LOGIC;
        sequence_detected : out STD_LOGIC
    );
end sequence_detector;

architecture Behavioral of sequence_detector is
    type state_type is (IDLE, S1, S2, S3, S4);
    signal current_state, next_state : state_type;
begin

    process(clk, reset_n)
    begin
        if reset_n = '0' then
            current_state <= IDLE;
        elsif rising_edge(clk) then
            current_state <= next_state;
        end if;
    end process;

    process(current_state, data_in)
    begin
        case current_state is
            when IDLE =>
                if data_in = '1' then
                    next_state <= S1;
                else
                    next_state <= IDLE;
                end if;
            when S1 =>
                if data_in = '0' then
                    next_state <= S2;
                else
                    next_state <= S1;
                end if;
            when S2 =>
                if data_in = '0' then
                    next_state <= S3;
                else
                    next_state <= S1;
                end if;
            when S3 =>
                if data_in = '1' then
                    next_state <= S4;
                else
                    next_state <= IDLE;
                end if;
            when S4 =>
                if data_in = '1' then
                    next_state <= S1;
                else
                    next_state <= IDLE;
                end if;
            when others =>
                next_state <= IDLE;
        end case;
    end process;

    sequence_detected <= '1' when current_state = S4 else '0';

end Behavioral;
