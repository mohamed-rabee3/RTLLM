library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity traffic_light is
    port (
        rst_n        : in  std_logic;
        clk          : in  std_logic;
        pass_request : in  std_logic;
        clock        : out std_logic_vector(7 downto 0);
        red          : out std_logic;
        yellow       : out std_logic;
        green        : out std_logic
    );
end traffic_light;

architecture rtl of traffic_light is
    type state_t is (idle, s1_red, s2_yellow, s3_green);
    signal state : state_t;

    signal cnt     : unsigned(7 downto 0);
    signal p_red   : std_logic;
    signal p_yellow: std_logic;
    signal p_green : std_logic;
    signal red_r   : std_logic;
    signal yellow_r: std_logic;
    signal green_r : std_logic;
begin

    -- State transition and next output logic
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
                    if cnt = 0 then
                        state <= s3_green;
                    end if;

                when s2_yellow =>
                    p_red    <= '0';
                    p_yellow <= '1';
                    p_green  <= '0';
                    if cnt = 0 then
                        state <= s1_red;
                    end if;

                when s3_green =>
                    p_red    <= '0';
                    p_yellow <= '0';
                    p_green  <= '1';
                    if cnt = 0 then
                        state <= s2_yellow;
                    end if;
            end case;
        end if;
    end process;

    -- Counter logic
    process(clk, rst_n)
    begin
        if rst_n = '0' then
            cnt <= to_unsigned(10, 8);
        elsif rising_edge(clk) then
            if pass_request = '1' and green_r = '1' then
                cnt <= to_unsigned(10, 8);
            elsif green_r = '0' and p_green = '1' then
                cnt <= to_unsigned(60, 8);
            elsif yellow_r = '0' and p_yellow = '1' then
                cnt <= to_unsigned(5, 8);
            elsif red_r = '0' and p_red = '1' then
                cnt <= to_unsigned(10, 8);
            else
                cnt <= cnt - 1;
            end if;
        end if;
    end process;

    -- Output register logic
    process(clk, rst_n)
    begin
        if rst_n = '0' then
            red_r    <= '0';
            yellow_r <= '0';
            green_r  <= '0';
        elsif rising_edge(clk) then
            red_r    <= p_red;
            yellow_r <= p_yellow;
            green_r  <= p_green;
        end if;
    end process;

    red    <= red_r;
    yellow <= yellow_r;
    green  <= green_r;
    clock  <= std_logic_vector(cnt);

end rtl;
