library ieee;
use ieee.std_logic_1164.all;

entity sequence_detector is
    port (
        clk               : in  std_logic;
        reset_n           : in  std_logic;
        data_in           : in  std_logic;
        sequence_detected : out std_logic
    );
end entity sequence_detector;

architecture rtl of sequence_detector is
    type state_type is (IDLE, S1, S2, S3, S4);
    signal state, next_state : state_type;
begin

    -- Active-high reset as specified.
    process (clk, reset_n)
    begin
        if reset_n = '1' then
            state <= IDLE;
        elsif rising_edge(clk) then
            state <= next_state;
        end if;
    end process;

    process (state, data_in)
    begin
        next_state <= state;

        case state is
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
                -- The final '1' can begin an overlapping sequence.
                if data_in = '0' then
                    next_state <= S2;
                else
                    next_state <= S1;
                end if;
        end case;
    end process;

    sequence_detected <= '1' when state = S4 else '0';

end architecture rtl;
