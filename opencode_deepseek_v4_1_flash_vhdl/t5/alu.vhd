library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity alu is
    port (
        a       : in  std_logic_vector(31 downto 0);
        b       : in  std_logic_vector(31 downto 0);
        aluc    : in  std_logic_vector(5 downto 0);
        r       : out std_logic_vector(31 downto 0);
        zero    : out std_logic;
        carry   : out std_logic;
        negative: out std_logic;
        overflow: out std_logic;
        flag    : out std_logic
    );
end alu;

architecture rtl of alu is
begin
    process(a, b, aluc)
        variable res_v      : std_logic_vector(31 downto 0);
        variable zero_v     : std_logic;
        variable carry_v    : std_logic;
        variable negative_v : std_logic;
        variable overflow_v : std_logic;
        variable flag_v     : std_logic;
        variable sum_u      : unsigned(32 downto 0);
        variable shift_amt  : integer range 0 to 31;
    begin
        -- default values
        res_v      := (others => '0');
        zero_v     := '0';
        carry_v    := '0';
        negative_v := '0';
        overflow_v := '0';
        flag_v     := 'Z';

        shift_amt := to_integer(unsigned(a(4 downto 0)));

        case aluc is
            when "100000" => -- ADD
                res_v := std_logic_vector(signed(a) + signed(b));
                sum_u := resize(unsigned(a), 33) + resize(unsigned(b), 33);
                carry_v := sum_u(32);
                if (a(31) = b(31)) and (res_v(31) /= a(31)) then
                    overflow_v := '1';
                else
                    overflow_v := '0';
                end if;

            when "100001" => -- ADDU
                res_v := std_logic_vector(unsigned(a) + unsigned(b));
                sum_u := resize(unsigned(a), 33) + resize(unsigned(b), 33);
                carry_v := sum_u(32);
                overflow_v := '0';

            when "100010" => -- SUB
                res_v := std_logic_vector(signed(a) - signed(b));
                sum_u := resize(unsigned(a), 33) + resize(not unsigned(b), 33) + 1;
                carry_v := sum_u(32);
                if (a(31) /= b(31)) and (res_v(31) /= a(31)) then
                    overflow_v := '1';
                else
                    overflow_v := '0';
                end if;

            when "100011" => -- SUBU
                res_v := std_logic_vector(unsigned(a) - unsigned(b));
                sum_u := resize(unsigned(a), 33) + resize(not unsigned(b), 33) + 1;
                carry_v := sum_u(32);
                overflow_v := '0';

            when "100100" => -- AND
                res_v := a and b;

            when "100101" => -- OR
                res_v := a or b;

            when "100110" => -- XOR
                res_v := a xor b;

            when "100111" => -- NOR
                res_v := a nor b;

            when "101010" => -- SLT
                if signed(a) < signed(b) then
                    res_v := (0 => '1', others => '0');
                    flag_v := '1';
                else
                    res_v := (others => '0');
                    flag_v := '0';
                end if;
                overflow_v := '0';
                carry_v := '0';

            when "101011" => -- SLTU
                if unsigned(a) < unsigned(b) then
                    res_v := (0 => '1', others => '0');
                    flag_v := '1';
                else
                    res_v := (others => '0');
                    flag_v := '0';
                end if;
                overflow_v := '0';
                carry_v := '0';

            when "000000" => -- SLL
                res_v := std_logic_vector(shift_left(unsigned(b), shift_amt));

            when "000010" => -- SRL
                res_v := std_logic_vector(shift_right(unsigned(b), shift_amt));

            when "000011" => -- SRA
                res_v := std_logic_vector(shift_right(signed(b), shift_amt));

            when "000100" => -- SLLV
                res_v := std_logic_vector(shift_left(unsigned(b), shift_amt));

            when "000110" => -- SRLV
                res_v := std_logic_vector(shift_right(unsigned(b), shift_amt));

            when "000111" => -- SRAV
                res_v := std_logic_vector(shift_right(signed(b), shift_amt));

            when "001111" => -- LUI
                res_v := a(15 downto 0) & x"0000";

            when others =>
                res_v := (others => 'Z');
                carry_v := '0';
                overflow_v := '0';
                flag_v := 'Z';
        end case;

        if res_v = "00000000000000000000000000000000" then
            zero_v := '1';
        else
            zero_v := '0';
        end if;
        negative_v := res_v(31);

        r <= res_v;
        zero <= zero_v;
        carry <= carry_v;
        negative <= negative_v;
        overflow <= overflow_v;
        flag <= flag_v;
    end process;
end rtl;
