library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity radix2_div is
    port (
        clk        : in  std_logic;
        rst        : in  std_logic;
        sign       : in  std_logic;
        dividend   : in  std_logic_vector(7 downto 0);
        divisor    : in  std_logic_vector(7 downto 0);
        opn_valid  : in  std_logic;
        res_valid  : out std_logic;
        result     : out std_logic_vector(15 downto 0)
    );
end entity radix2_div;

architecture rtl of radix2_div is

    -- state machine for division process
    type state_type is (IDLE, COMPUTE, DONE);
    signal state : state_type;

    -- internal registers
    signal sr_reg           : unsigned(15 downto 0);  -- combined remainder (upper) and quotient (lower)
    signal cnt_reg          : unsigned(3 downto 0);   -- iteration counter
    signal dividend_sign_r  : std_logic;              -- saved sign of dividend (for signed division)
    signal divisor_sign_r   : std_logic;              -- saved sign of divisor
    signal op_sign_r        : std_logic;              -- saved sign mode (1 = signed)
    signal neg_divisor_r    : unsigned(7 downto 0);   -- negated absolute divisor
    signal result_reg       : unsigned(15 downto 0);  -- final result after sign adjustment
    signal res_valid_i      : std_logic;

begin

    res_valid <= res_valid_i;
    result    <= std_logic_vector(result_reg);

    --------------------------------------------------------------------
    -- Main synchronous process
    --------------------------------------------------------------------
    process (clk, rst)
        -- aliases for the two halves of the shift register
        alias A_reg : unsigned(7 downto 0) is sr_reg(15 downto 8);
        alias Q_reg : unsigned(7 downto 0) is sr_reg(7 downto 0);

        -- variables for computations inside the process
        variable dividend_abs_v : unsigned(7 downto 0);
        variable divisor_abs_v  : unsigned(7 downto 0);
        variable neg_div_v      : unsigned(7 downto 0);
        variable div_sign_v     : std_logic;
        variable dvd_sign_v     : std_logic;

        variable A_shifted_v : unsigned(7 downto 0);
        variable Q_shifted_v : unsigned(7 downto 0);
        variable sum9_v      : unsigned(8 downto 0);
        variable carry_v     : std_logic;
        variable sub_res_v   : unsigned(7 downto 0);
        variable A_new_v     : unsigned(7 downto 0);
        variable Q_new_v     : unsigned(7 downto 0);

        variable rem_abs_v   : unsigned(7 downto 0);
        variable quot_abs_v  : unsigned(7 downto 0);
        variable rem_signed  : unsigned(7 downto 0);
        variable quot_signed : unsigned(7 downto 0);

    begin
        if rst = '1' then
            state         <= IDLE;
            res_valid_i   <= '0';
            sr_reg        <= (others => '0');
            cnt_reg       <= (others => '0');
            dividend_sign_r <= '0';
            divisor_sign_r  <= '0';
            op_sign_r       <= '0';
            neg_divisor_r   <= (others => '0');
            result_reg      <= (others => '0');

        elsif rising_edge(clk) then
            case state is

                -- wait for a new operation request
                when IDLE =>
                    res_valid_i <= '0';
                    if opn_valid = '1' then
                        -- save sign mode
                        op_sign_r <= sign;

                        -- compute absolute values and signs for dividend
                        if sign = '1' and dividend(7) = '1' then
                            dvd_sign_v    := '1';
                            dividend_abs_v := unsigned(-signed(dividend));
                        else
                            dvd_sign_v    := '0';
                            dividend_abs_v := unsigned(dividend);
                        end if;

                        -- compute absolute values and signs for divisor
                        if sign = '1' and divisor(7) = '1' then
                            div_sign_v    := '1';
                            divisor_abs_v := unsigned(-signed(divisor));
                        else
                            div_sign_v    := '0';
                            divisor_abs_v := unsigned(divisor);
                        end if;

                        -- negated absolute divisor = –|divisor|
                        neg_div_v := unsigned(-signed(divisor_abs_v));

                        -- store the computed values
                        dividend_sign_r <= dvd_sign_v;
                        divisor_sign_r  <= div_sign_v;
                        neg_divisor_r   <= neg_div_v;

                        -- initialise shift register with {0, |dividend|}
                        -- (the first left shift will be performed in the 1st iteration)
                        sr_reg  <= x"00" & dividend_abs_v;

                        -- start counter at 1; the algorithm performs
                        -- exactly 8 iterations for an 8‑bit division
                        cnt_reg <= "0001";

                        state <= COMPUTE;
                    end if;

                -- perform restoring radix‑2 division
                when COMPUTE =>
                    -- The loop runs for cnt = 1..8 (8 iterations)
                    -- Stop when cnt reaches 9 (i.e. after 8 iterations)
                    if cnt_reg = "1001" then
                        -- Division complete; determine final signed result
                        rem_abs_v  := sr_reg(15 downto 8);
                        quot_abs_v := sr_reg(7 downto 0);

                        if op_sign_r = '1' then
                            -- rem_sign = dividend_sign, quot_sign = dividend_sign xor divisor_sign
                            if dividend_sign_r = '1' then
                                rem_signed := unsigned(-signed(rem_abs_v));
                            else
                                rem_signed := rem_abs_v;
                            end if;
                            if (dividend_sign_r xor divisor_sign_r) = '1' then
                                quot_signed := unsigned(-signed(quot_abs_v));
                            else
                                quot_signed := quot_abs_v;
                            end if;
                        else
                            -- unsigned operation, no sign change
                            rem_signed  := rem_abs_v;
                            quot_signed := quot_abs_v;
                        end if;

                        -- result: remainder in upper 8 bits, quotient in lower 8 bits
                        result_reg   <= rem_signed & quot_signed;
                        res_valid_i  <= '1';
                        state        <= DONE;

                    else
                        -- Perform one iteration of restoring radix-2 division
                        -- Step 1: shift left the concatenated register
                        A_shifted_v := A_reg(6 downto 0) & Q_reg(7);
                        Q_shifted_v := Q_reg(6 downto 0) & '0';

                        -- Step 2: subtract |divisor| (i.e. add its negated value)
                        sum9_v     := ('0' & A_shifted_v) + ('0' & neg_divisor_r);
                        carry_v    := sum9_v(8);
                        sub_res_v  := sum9_v(7 downto 0);

                        -- Step 3: multiplexer selects new remainder
                        if carry_v = '1' then
                            A_new_v := sub_res_v;     -- subtraction successful
                        else
                            A_new_v := A_shifted_v;   -- restore original shifted value
                        end if;

                        -- Step 4: insert carry-out as LSB of the quotient
                        Q_new_v := Q_shifted_v(7 downto 1) & carry_v;

                        -- update shift register and counter
                        sr_reg  <= A_new_v & Q_new_v;
                        cnt_reg <= cnt_reg + 1;
                    end if;

                -- result is ready, wait until it has been consumed
                when DONE =>
                    if opn_valid = '0' then
                        -- consumer deasserted opn_valid, operation consumed
                        res_valid_i <= '0';
                        state       <= IDLE;
                    else
                        res_valid_i <= '1';  -- keep result valid
                    end if;

            end case;
        end if;
    end process;

end architecture rtl;