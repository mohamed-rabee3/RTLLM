library ieee;
use ieee.std_logic_1164.all;

entity sequence_detector is
    port (
        clk               : in  std_logic;
        reset_n           : in  std_logic;  -- Note: This design treats reset_n as active-high (reset when '1')
        data_in           : in  std_logic;
        sequence_detected : out std_logic
    );
end entity sequence_detector;

architecture rtl of sequence_detector is

    type state_type is (IDLE, S1, S2, S3, S4);
    signal current_state, next_state : state_type;

begin

    -- Synchronous state register with active-high reset (signal name: reset_n)
    state_register: process(clk)
    begin
        if rising_edge(clk) then
            if reset_n = '1' then
                current_state <= IDLE;
            else
                current_state <= next_state;
            end if;
        end if;
    end process state_register;

    -- Next-state logic for overlapping sequence detector "1001"
    fsm_comb: process(current_state, data_in)
    begin
        -- Default assignments
        next_state <= current_state;
        sequence_detected <= '0';

        case current_state is
            when IDLE =>
                if data_in = '1' then
                    next_state <= S1;
                else
                    next_state <= IDLE;
                end if;

            when S1 =>  -- received '1'
                if data_in = '0' then
                    next_state <= S2;
                else
                    next_state <= S1;  -- stay waiting for first '0'
                end if;

            when S2 =>  -- received '10'
                if data_in = '0' then
                    next_state <= S3;
                else
                    next_state <= S1;  -- '1' could be start of a new sequence
                end if;

            when S3 =>  -- received '100'
                if data_in = '1' then
                    next_state <= S4;
                else
                    next_state <= IDLE; -- '0' breaks the remaining pattern
                end if;

            when S4 =>  -- received '1001' (sequence detected)
                sequence_detected <= '1';  -- Moore output asserted in this state
                if data_in = '0' then
                    next_state <= S2;  -- last '1' could be start, '0' gives '10'
                else
                    next_state <= S1;  -- last '1' stays as start
                end if;

            when others =>
                next_state <= IDLE;
        end case;
    end process fsm_comb;

end architecture rtl;