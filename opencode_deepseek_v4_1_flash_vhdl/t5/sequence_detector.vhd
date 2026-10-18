library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity sequence_detector is
    Port (
        clk               : in  std_logic;
        reset_n           : in  std_logic;
        data_in           : in  std_logic;
        sequence_detected : out std_logic
    );
end sequence_detector;

architecture rtl of sequence_detector is
    type state_type is (IDLE, S1, S2, S3, S4);
    signal state : state_type;
begin

    process(clk, reset_n)
    begin
        if reset_n = '0' then
            state <= IDLE;
        elsif rising_edge(clk) then
            case state is
                when IDLE =>
                    if data_in = '1' then
                        state <= S1;
                    else
                        state <= IDLE;
                    end if;

                when S1 =>
                    if data_in = '0' then
                        state <= S2;
                    else
                        state <= S1;
                    end if;

                when S2 =>
                    if data_in = '0' then
                        state <= S3;
                    else
                        state <= S1;
                    end if;

                when S3 =>
                    if data_in = '1' then
                        state <= S4;
                    else
                        state <= IDLE;
                    end if;

                when S4 =>
                    if data_in = '1' then
                        state <= S1;
                    else
                        state <= S2;
                    end if;

                when others =>
                    state <= IDLE;
            end case;
        end if;
    end process;

    sequence_detected <= '1' when state = S4 else '0';

end rtl;
