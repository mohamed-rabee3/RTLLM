library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity radix2_div is
    Port ( clk : in  STD_LOGIC;
           rst : in  STD_LOGIC;
           sign : in  STD_LOGIC;
           dividend : in  STD_LOGIC_VECTOR (7 downto 0);
           divisor : in  STD_LOGIC_VECTOR (7 downto 0);
           opn_valid : in  STD_LOGIC;
           res_valid : out  STD_LOGIC;
           result : out  STD_LOGIC_VECTOR (15 downto 0));
end radix2_div;

architecture rtl of radix2_div is
    type state_type is (IDLE, BUSY, DONE);
    signal state : state_type;
    signal SR : unsigned(15 downto 0);
    signal abs_divisor : unsigned(7 downto 0);
    signal sign_reg : std_logic;
    signal sign_dividend : std_logic;
    signal sign_divisor : std_logic;
    signal counter : integer range 0 to 8;
    signal res_valid_reg : std_logic;
    signal result_reg : std_logic_vector(15 downto 0);
begin

    process(clk, rst)
        variable next_SR : unsigned(15 downto 0);
        variable rem_abs : unsigned(7 downto 0);
        variable quo_abs : unsigned(7 downto 0);
        variable rem_signed : unsigned(7 downto 0);
        variable quo_signed : unsigned(7 downto 0);
    begin
        if rst = '1' then
            state <= IDLE;
            res_valid_reg <= '0';
            counter <= 0;
            SR <= (others => '0');
            abs_divisor <= (others => '0');
            sign_reg <= '0';
            sign_dividend <= '0';
            sign_divisor <= '0';
            result_reg <= (others => '0');
        elsif rising_edge(clk) then
            case state is
                when IDLE =>
                    res_valid_reg <= '0';
                    if opn_valid = '1' then
                        sign_reg <= sign;
                        if sign = '1' then
                            if dividend(7) = '1' then
                                SR(7 downto 0) <= unsigned(not dividend) + 1;
                                sign_dividend <= '1';
                            else
                                SR(7 downto 0) <= unsigned(dividend);
                                sign_dividend <= '0';
                            end if;
                            if divisor(7) = '1' then
                                abs_divisor <= unsigned(not divisor) + 1;
                                sign_divisor <= '1';
                            else
                                abs_divisor <= unsigned(divisor);
                                sign_divisor <= '0';
                            end if;
                        else
                            SR(7 downto 0) <= unsigned(dividend);
                            abs_divisor <= unsigned(divisor);
                            sign_dividend <= '0';
                            sign_divisor <= '0';
                        end if;
                        SR(15 downto 8) <= (others => '0');
                        counter <= 0;
                        state <= BUSY;
                    end if;

                when BUSY =>
                    next_SR := SR(14 downto 0) & '0';
                    if next_SR(15 downto 8) >= abs_divisor then
                        next_SR(15 downto 8) := next_SR(15 downto 8) - abs_divisor;
                        next_SR(0) := '1';
                    else
                        next_SR(0) := '0';
                    end if;
                    SR <= next_SR;
                    counter <= counter + 1;
                    if counter = 7 then
                        state <= DONE;
                        res_valid_reg <= '1';
                        rem_abs := next_SR(15 downto 8);
                        quo_abs := next_SR(7 downto 0);
                        if sign_reg = '1' then
                            if (sign_dividend xor sign_divisor) = '1' then
                                quo_signed := unsigned(not std_logic_vector(quo_abs)) + 1;
                            else
                                quo_signed := quo_abs;
                            end if;
                            if sign_dividend = '1' then
                                rem_signed := unsigned(not std_logic_vector(rem_abs)) + 1;
                            else
                                rem_signed := rem_abs;
                            end if;
                        else
                            quo_signed := quo_abs;
                            rem_signed := rem_abs;
                        end if;
                        result_reg <= std_logic_vector(rem_signed & quo_signed);
                    end if;

                when DONE =>
                    if opn_valid = '0' then
                        res_valid_reg <= '0';
                        state <= IDLE;
                    end if;
            end case;
        end if;
    end process;

    res_valid <= res_valid_reg;
    result <= result_reg;

end rtl;
