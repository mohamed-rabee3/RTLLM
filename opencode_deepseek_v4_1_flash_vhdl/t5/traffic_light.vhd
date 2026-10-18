library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity traffic_light is
    Port (
        rst_n : in STD_LOGIC;
        clk : in STD_LOGIC;
        pass_request : in STD_LOGIC;
        clock : out STD_LOGIC_VECTOR(7 downto 0);
        red : out STD_LOGIC;
        yellow : out STD_LOGIC;
        green : out STD_LOGIC
    );
end traffic_light;

architecture Behavioral of traffic_light is
    type state_type is (idle, s1_red, s2_yellow, s3_green);
    signal state : state_type;
    signal cnt : unsigned(7 downto 0);
begin

    process(clk, rst_n)
    begin
        if rst_n = '0' then
            state <= idle;
            cnt <= to_unsigned(10, 8);
        elsif rising_edge(clk) then
            case state is
                when idle =>
                    state <= s1_red;
                    cnt <= to_unsigned(10, 8);
                when s1_red =>
                    if cnt = 0 then
                        state <= s3_green;
                        cnt <= to_unsigned(60, 8);
                    else
                        cnt <= cnt - 1;
                    end if;
                when s3_green =>
                    if cnt = 0 then
                        state <= s2_yellow;
                        cnt <= to_unsigned(5, 8);
                    else
                        if pass_request = '1' and cnt > to_unsigned(10, 8) then
                            cnt <= to_unsigned(10, 8);
                        else
                            cnt <= cnt - 1;
                        end if;
                    end if;
                when s2_yellow =>
                    if cnt = 0 then
                        state <= s1_red;
                        cnt <= to_unsigned(10, 8);
                    else
                        cnt <= cnt - 1;
                    end if;
            end case;
        end if;
    end process;

    clock <= std_logic_vector(cnt);

    red <= '1' when state = s1_red else '0';
    yellow <= '1' when state = s2_yellow else '0';
    green <= '1' when state = s3_green else '0';

end Behavioral;
