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
end traffic_light;

architecture rtl of traffic_light is

    -- Enumerated states
    type state_type is (idle, s1_red, s2_yellow, s3_green);

    -- Internal registers and signals
    signal state, next_state : state_type;
    signal cnt_int           : integer range 0 to 255;

    -- Next output values (combinational)
    signal p_red    : std_logic;
    signal p_yellow : std_logic;
    signal p_green  : std_logic;

begin

    ----------------------------------------------------------------------------
    -- State register
    ----------------------------------------------------------------------------
    state_reg : process(clk, rst_n)
    begin
        if rst_n = '0' then
            state <= idle;
        elsif rising_edge(clk) then
            state <= next_state;
        end if;
    end process;

    ----------------------------------------------------------------------------
    -- Combinational next-state and output logic
    ----------------------------------------------------------------------------
    comb_logic : process(state, cnt_int)
    begin
        -- Default assignments
        next_state <= state;
        p_red      <= '0';
        p_yellow   <= '0';
        p_green    <= '0';

        case state is
            when idle =>
                next_state <= s1_red;

            when s1_red =>
                p_red <= '1';
                if cnt_int = 3 then
                    next_state <= s3_green;
                end if;

            when s2_yellow =>
                p_yellow <= '1';
                if cnt_int = 3 then
                    next_state <= s1_red;
                end if;

            when s3_green =>
                p_green <= '1';
                if cnt_int = 3 then
                    next_state <= s2_yellow;
                end if;

            when others =>
                next_state <= idle;
        end case;
    end process;

    ----------------------------------------------------------------------------
    -- Output registers (registered red, yellow, green)
    ----------------------------------------------------------------------------
    output_reg : process(clk, rst_n)
    begin
        if rst_n = '0' then
            red    <= '0';
            yellow <= '0';
            green  <= '0';
        elsif rising_edge(clk) then
            red    <= p_red;
            yellow <= p_yellow;
            green  <= p_green;
        end if;
    end process;

    ----------------------------------------------------------------------------
    -- Counter logic
    ----------------------------------------------------------------------------
    cnt_proc : process(clk, rst_n)
    begin
        if rst_n = '0' then
            cnt_int <= 10;
        elsif rising_edge(clk) then
            if pass_request = '1' and green = '1' then
                cnt_int <= 10;
            elsif green = '0' and p_green = '1' then
                cnt_int <= 60;
            elsif yellow = '0' and p_yellow = '1' then
                cnt_int <= 5;
            elsif red = '0' and p_red = '1' then
                cnt_int <= 10;
            else
                cnt_int <= cnt_int - 1;
            end if;
        end if;
    end process;

    ----------------------------------------------------------------------------
    -- Output clock assignment
    ----------------------------------------------------------------------------
    clock <= std_logic_vector(to_unsigned(cnt_int, 8));

end rtl;