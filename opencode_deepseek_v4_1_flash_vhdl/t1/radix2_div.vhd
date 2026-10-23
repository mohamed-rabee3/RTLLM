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

architecture Behavioral of radix2_div is
    signal SR : unsigned(16 downto 0);
    signal NEG_DIVISOR : signed(8 downto 0);
    signal cnt : unsigned(3 downto 0);
    signal start_cnt : std_logic;
    signal res_valid_reg : std_logic;
    signal sign_reg : std_logic;
    signal sign_quotient : std_logic;
    signal sign_dividend : std_logic;
begin
    process(clk, rst)
        variable abs_dividend : unsigned(8 downto 0);
        variable abs_divisor : unsigned(8 downto 0);
        variable SR_shift : unsigned(16 downto 0);
        variable R_shift : signed(8 downto 0);
        variable R_new : signed(8 downto 0);
        variable Q_shift : unsigned(7 downto 0);
        variable Q_new : unsigned(7 downto 0);
    begin
        if rst = '1' then
            SR <= (others => '0');
            NEG_DIVISOR <= (others => '0');
            cnt <= (others => '0');
            start_cnt <= '0';
            res_valid_reg <= '0';
            sign_reg <= '0';
            sign_quotient <= '0';
            sign_dividend <= '0';
        elsif rising_edge(clk) then
            if opn_valid = '1' and res_valid_reg = '0' then
                -- Start operation
                sign_reg <= sign;
                if sign = '1' then
                    abs_dividend := abs(resize(signed(dividend), 9));
                    abs_divisor := abs(resize(signed(divisor), 9));
                    sign_quotient <= dividend(7) xor divisor(7);
                    sign_dividend <= dividend(7);
                else
                    abs_dividend := unsigned('0' & dividend);
                    abs_divisor := unsigned('0' & divisor);
                    sign_quotient <= '0';
                    sign_dividend <= '0';
                end if;
                -- Initialize SR with abs(dividend) shifted left by one bit
                SR <= (others => '0');
                SR(8) <= abs_dividend(7);
                SR(7 downto 1) <= abs_dividend(6 downto 0);
                SR(0) <= '0';
                -- NEG_DIVISOR = -abs(divisor)
                NEG_DIVISOR <= -signed(std_logic_vector(abs_divisor));
                cnt <= "0001";
                start_cnt <= '1';
                res_valid_reg <= '0';
            elsif start_cnt = '1' then
                if cnt = "1000" then
                    cnt <= (others => '0');
                    start_cnt <= '0';
                    res_valid_reg <= '1';
                    -- Final correction
                    if SR(16) = '1' then
                        SR(16 downto 8) <= std_logic_vector(signed(SR(16 downto 8)) - NEG_DIVISOR);
                    end if;
                    -- Apply signs
                    if sign_reg = '1' then
                        if sign_quotient = '1' then
                            SR(7 downto 0) <= std_logic_vector(-signed(SR(7 downto 0)));
                        end if;
                        if sign_dividend = '1' then
                            SR(15 downto 8) <= std_logic_vector(-signed(SR(15 downto 8)));
                        end if;
                    end if;
                else
                    cnt <= cnt + 1;
                    -- Perform non-restoring step
                    SR_shift := SR(15 downto 0) & '0';
                    R_shift := signed(SR_shift(16 downto 8));
                    Q_shift := SR_shift(7 downto 0);
                    if SR(16) = '0' then
                        R_new := R_shift + NEG_DIVISOR;
                    else
                        R_new := R_shift - NEG_DIVISOR;
                    end if;
                    Q_new := Q_shift(7 downto 1) & (not R_new(8));
                    SR(16 downto 8) <= std_logic_vector(R_new);
                    SR(7 downto 0) <= std_logic_vector(Q_new);
                end if;
            end if;
            if res_valid_reg = '1' and opn_valid = '0' then
                res_valid_reg <= '0';
            end if;
        end if;
    end process;

    res_valid <= res_valid_reg;
    result <= std_logic_vector(SR(15 downto 0));

end Behavioral;
