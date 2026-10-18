library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity traffic_light is
    Port (
        rst_n        : in  STD_LOGIC;
        clk          : in  STD_LOGIC;
        pass_request : in  STD_LOGIC;
        clock        : out STD_LOGIC_VECTOR(7 downto 0);
        red          : out STD_LOGIC;
        yellow       : out STD_LOGIC;
        green        : out STD_LOGIC
    );
end traffic_light;

architecture rtl of traffic_light is
    type state_type is (idle, s1_red, s2_yellow, s3_green);

    signal state    : state_type;
    signal cnt      : unsigned(7 downto 0);
    signal p_red    : std_logic;
    signal p_yellow : std_logic;
    signal p_green  : std_logic;
    signal red_reg    : std_logic;
    signal yellow_reg : std_logic;
    signal green_reg  : std_logic;
begin
    clock  <= std_logic_vector(cnt);
    red    <= red_reg;
    yellow <= yellow_reg;
    green  <= green_reg;

    process(clk, rst_n)
    begin
        if rst_n = '0' then
            state    <= idle;
            p_red    <= '0';
            p_yellow <= '0';
            p_green  <= '0';
        elsif rising_edge(clk) then
            case state is
                when idle =>
                    p_red    <= '0';
                    p_yellow <= '0';
                    p_green  <= '0';
                    state    <= s1_red;

                when s1_red =>
                    p_red    <= '1';
                    p_yellow <= '0';
                    p_green  <= '0';
                    if cnt = 3 then
                        state <= s3_green;
                    else
                        state <= s1_red;
                    end if;

                when s2_yellow =>
                    p_red    <= '0';
                    p_yellow <= '1';
                    p_green  <= '0';
                    if cnt = 3 then
                        state <= s1_red;
                    else
                        state <= s2_yellow;
                    end if;

                when s3_green =>
                    p_red    <= '0';
                    p_yellow <= '0';
                    p_green  <= '1';
                    if cnt = 3 then
                        state <= s2_yellow;
                    else
                        state <= s3_green;
                    end if;

                when others =>
                    state <= idle;
            end case;
        end if;
    end process;

    process(clk, rst_n)
    begin
        if rst_n = '0' then
            cnt <= to_unsigned(10, 8);
        elsif rising_edge(clk) then
            if pass_request = '1' and green_reg = '1' then
                cnt <= to_unsigned(10, 8);
            elsif green_reg = '0' and p_green = '1' then
                cnt <= to_unsigned(60, 8);
            elsif yellow_reg = '0' and p_yellow = '1' then
                cnt <= to_unsigned(5, 8);
            elsif red_reg = '0' and p_red = '1' then
                cnt <= to_unsigned(10, 8);
            else
                cnt <= cnt - 1;
            end if;
        end if;
    end process;

    process(clk, rst_n)
    begin
        if rst_n = '0' then
            red_reg    <= '0';
            yellow_reg <= '0';
            green_reg  <= '0';
        elsif rising_edge(clk) then
            red_reg    <= p_red;
            yellow_reg <= p_yellow;
            green_reg  <= p_green;
        end if;
    end process;
end rtl;
