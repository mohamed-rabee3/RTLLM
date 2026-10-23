library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

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
end entity traffic_light;

architecture rtl of traffic_light is
    constant idle      : std_logic_vector(1 downto 0) := "00";
    constant s1_red    : std_logic_vector(1 downto 0) := "01";
    constant s2_yellow : std_logic_vector(1 downto 0) := "10";
    constant s3_green  : std_logic_vector(1 downto 0) := "11";

    signal cnt   : unsigned(7 downto 0);
    signal state : std_logic_vector(1 downto 0);

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

    process (clk, rst_n)
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
                    if cnt = to_unsigned(3, cnt'length) then
                        state <= s3_green;
                    else
                        state <= s1_red;
                    end if;

                when s2_yellow =>
                    p_red    <= '0';
                    p_yellow <= '1';
                    p_green  <= '0';
                    if cnt = to_unsigned(3, cnt'length) then
                        state <= s1_red;
                    else
                        state <= s2_yellow;
                    end if;

                when s3_green =>
                    p_red    <= '0';
                    p_yellow <= '0';
                    p_green  <= '1';
                    if cnt = to_unsigned(3, cnt'length) then
                        state <= s2_yellow;
                    else
                        state <= s3_green;
                    end if;

                when others =>
                    state    <= idle;
                    p_red    <= '0';
                    p_yellow <= '0';
                    p_green  <= '0';
            end case;
        end if;
    end process;

    process (clk, rst_n)
    begin
        if rst_n = '0' then
            cnt <= to_unsigned(10, cnt'length);
        elsif rising_edge(clk) then
            if pass_request = '1' and green_reg = '1'
               and cnt > to_unsigned(10, cnt'length) then
                cnt <= to_unsigned(10, cnt'length);
            elsif green_reg = '0' and p_green = '1' then
                cnt <= to_unsigned(60, cnt'length);
            elsif yellow_reg = '0' and p_yellow = '1' then
                cnt <= to_unsigned(5, cnt'length);
            elsif red_reg = '0' and p_red = '1' then
                cnt <= to_unsigned(10, cnt'length);
            else
                cnt <= cnt - to_unsigned(1, cnt'length);
            end if;
        end if;
    end process;

    process (clk, rst_n)
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
end architecture rtl;
