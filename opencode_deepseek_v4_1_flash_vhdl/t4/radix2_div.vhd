library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity radix2_div is
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           sign : in STD_LOGIC;
           dividend : in STD_LOGIC_VECTOR (7 downto 0);
           divisor : in STD_LOGIC_VECTOR (7 downto 0);
           opn_valid : in STD_LOGIC;
           res_valid : out STD_LOGIC;
           result : out STD_LOGIC_VECTOR (15 downto 0));
end radix2_div;

architecture Behavioral of radix2_div is
    signal SR : unsigned(15 downto 0);
    signal NEG_DIVISOR : unsigned(7 downto 0);
    signal cnt : unsigned(3 downto 0);
    signal start_cnt : std_logic;
    signal sign_reg : std_logic;
    signal rem_sign : std_logic;
    signal res_valid_reg : std_logic;
    signal result_reg : std_logic_vector(15 downto 0);
begin
    process(clk, rst)
        variable abs_div : unsigned(7 downto 0);
        variable abs_dvd : unsigned(7 downto 0);
        variable sum : unsigned(8 downto 0);
        variable shifted_SR : unsigned(15 downto 0);
    begin
        if rst = '1' then
            res_valid_reg <= '0';
            result_reg <= (others => '0');
            start_cnt <= '0';
            cnt <= (others => '0');
            SR <= (others => '0');
            NEG_DIVISOR <= (others => '0');
            sign_reg <= '0';
            rem_sign <= '0';
        elsif rising_edge(clk) then
            if opn_valid = '1' and res_valid_reg = '0' and start_cnt = '0' then
                -- Latch inputs and compute absolute values
                if sign = '1' then
                    if dividend(7) = '1' then
                        abs_dvd := unsigned(std_logic_vector(-signed(dividend)));
                    else
                        abs_dvd := unsigned(dividend);
                    end if;
                    if divisor(7) = '1' then
                        abs_div := unsigned(std_logic_vector(-signed(divisor)));
                    else
                        abs_div := unsigned(divisor);
                    end if;
                    sign_reg <= dividend(7) xor divisor(7);
                    rem_sign <= dividend(7);
                else
                    abs_dvd := unsigned(dividend);
                    abs_div := unsigned(divisor);
                    sign_reg <= '0';
                    rem_sign <= '0';
                end if;
                SR(15 downto 8) <= (others => '0');
                SR(7 downto 0) <= abs_dvd;
                NEG_DIVISOR <= (not abs_div) + 1;
                cnt <= (others => '0');
                start_cnt <= '1';
                res_valid_reg <= '0';
            elsif start_cnt = '1' then
                if cnt = 8 then
                    start_cnt <= '0';
                    cnt <= (others => '0');
                    -- Apply signs to remainder and quotient
                    if rem_sign = '1' then
                        result_reg(15 downto 8) <= std_logic_vector(-signed(SR(15 downto 8)));
                    else
                        result_reg(15 downto 8) <= std_logic_vector(SR(15 downto 8));
                    end if;
                    if sign_reg = '1' then
                        result_reg(7 downto 0) <= std_logic_vector(-signed(SR(7 downto 0)));
                    else
                        result_reg(7 downto 0) <= std_logic_vector(SR(7 downto 0));
                    end if;
                    res_valid_reg <= '1';
                else
                    -- One division step (restoring division)
                    shifted_SR := SR(14 downto 0) & '0';
                    sum := ('0' & shifted_SR(15 downto 8)) + ('0' & NEG_DIVISOR);
                    if sum(8) = '1' then
                        SR <= sum(7 downto 0) & shifted_SR(7 downto 1) & '1';
                    else
                        SR <= shifted_SR(15 downto 8) & shifted_SR(7 downto 1) & '0';
                    end if;
                    cnt <= cnt + 1;
                end if;
            elsif res_valid_reg = '1' then
                if opn_valid = '0' then
                    res_valid_reg <= '0';
                end if;
            end if;
        end if;
    end process;

    res_valid <= res_valid_reg;
    result <= result_reg;
end Behavioral;
