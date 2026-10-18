library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity radix2_div is
    Port (
        clk : in STD_LOGIC;
        rst : in STD_LOGIC;
        sign : in STD_LOGIC;
        dividend : in STD_LOGIC_VECTOR (7 downto 0);
        divisor : in STD_LOGIC_VECTOR (7 downto 0);
        opn_valid : in STD_LOGIC;
        res_valid : out STD_LOGIC;
        result : out STD_LOGIC_VECTOR (15 downto 0)
    );
end radix2_div;

architecture rtl of radix2_div is
    type state_t is (IDLE, COMPUTE, DONE);
    signal state : state_t := IDLE;
    signal SR : unsigned(15 downto 0) := (others => '0');
    signal divisor_abs : unsigned(7 downto 0) := (others => '0');
    signal sign_quot : std_logic := '0';
    signal sign_rem : std_logic := '0';
    signal count : unsigned(3 downto 0) := (others => '0');
    signal res_valid_reg : std_logic := '0';
    signal result_reg : unsigned(15 downto 0) := (others => '0');
begin
    res_valid <= res_valid_reg;
    result <= std_logic_vector(result_reg);

    process(clk, rst)
        variable next_sr : unsigned(15 downto 0);
        variable quotient_v : unsigned(7 downto 0);
        variable remainder_v : unsigned(7 downto 0);
    begin
        if rst = '1' then
            state <= IDLE;
            SR <= (others => '0');
            divisor_abs <= (others => '0');
            sign_quot <= '0';
            sign_rem <= '0';
            count <= (others => '0');
            res_valid_reg <= '0';
            result_reg <= (others => '0');
        elsif rising_edge(clk) then
            case state is
                when IDLE =>
                    if opn_valid = '1' then
                        if sign = '1' then
                            if dividend(7) = '1' then
                                SR(7 downto 0) <= unsigned(not dividend) + 1;
                            else
                                SR(7 downto 0) <= unsigned(dividend);
                            end if;
                            if divisor(7) = '1' then
                                divisor_abs <= unsigned(not divisor) + 1;
                            else
                                divisor_abs <= unsigned(divisor);
                            end if;
                            sign_quot <= dividend(7) xor divisor(7);
                            sign_rem <= dividend(7);
                        else
                            SR(7 downto 0) <= unsigned(dividend);
                            divisor_abs <= unsigned(divisor);
                            sign_quot <= '0';
                            sign_rem <= '0';
                        end if;
                        SR(15 downto 8) <= (others => '0');
                        count <= (others => '0');
                        res_valid_reg <= '0';
                        state <= COMPUTE;
                    end if;

                when COMPUTE =>
                    next_sr := SR(14 downto 0) & '0';
                    if next_sr(15 downto 8) >= divisor_abs then
                        next_sr(15 downto 8) := next_sr(15 downto 8) - divisor_abs;
                        next_sr(0) := '1';
                    else
                        next_sr(0) := '0';
                    end if;
                    SR <= next_sr;

                    if count = 7 then
                        quotient_v := next_sr(7 downto 0);
                        remainder_v := next_sr(15 downto 8);
                        if sign_quot = '1' then
                            result_reg(7 downto 0) <= to_unsigned(0, 8) - quotient_v;
                        else
                            result_reg(7 downto 0) <= quotient_v;
                        end if;
                        if sign_rem = '1' then
                            result_reg(15 downto 8) <= to_unsigned(0, 8) - remainder_v;
                        else
                            result_reg(15 downto 8) <= remainder_v;
                        end if;
                        res_valid_reg <= '1';
                        state <= DONE;
                    else
                        count <= count + 1;
                    end if;

                when DONE =>
                    if opn_valid = '0' then
                        state <= IDLE;
                    end if;
            end case;
        end if;
    end process;
end rtl;
