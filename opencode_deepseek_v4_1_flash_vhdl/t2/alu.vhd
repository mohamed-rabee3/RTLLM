library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity alu is
    Port (
        a : in  STD_LOGIC_VECTOR (31 downto 0);
        b : in  STD_LOGIC_VECTOR (31 downto 0);
        aluc : in  STD_LOGIC_VECTOR (5 downto 0);
        r : out STD_LOGIC_VECTOR (31 downto 0);
        zero : out STD_LOGIC;
        carry : out STD_LOGIC;
        negative : out STD_LOGIC;
        overflow : out STD_LOGIC;
        flag : out STD_LOGIC
    );
end alu;

architecture Behavioral of alu is
begin
    process(a, b, aluc)
        variable sum : unsigned(32 downto 0);
        variable result : std_logic_vector(31 downto 0);
        variable carry_v : std_logic;
        variable overflow_v : std_logic;
        variable flag_v : std_logic;
        variable shift_amt : integer range 0 to 31;
    begin
        result := (others => 'Z');
        carry_v := '0';
        overflow_v := '0';
        flag_v := 'Z';
        shift_amt := to_integer(unsigned(a(4 downto 0)));

        case aluc is
            when "100000" => -- ADD
                sum := resize(unsigned(a), 33) + resize(unsigned(b), 33);
                result := std_logic_vector(sum(31 downto 0));
                carry_v := sum(32);
                if (a(31) = b(31)) and (result(31) /= a(31)) then
                    overflow_v := '1';
                else
                    overflow_v := '0';
                end if;

            when "100001" => -- ADDU
                sum := resize(unsigned(a), 33) + resize(unsigned(b), 33);
                result := std_logic_vector(sum(31 downto 0));
                carry_v := sum(32);
                overflow_v := '0';

            when "100010" => -- SUB
                sum := resize(unsigned(a), 33) - resize(unsigned(b), 33);
                result := std_logic_vector(sum(31 downto 0));
                carry_v := sum(32);
                if (a(31) /= b(31)) and (result(31) /= a(31)) then
                    overflow_v := '1';
                else
                    overflow_v := '0';
                end if;

            when "100011" => -- SUBU
                sum := resize(unsigned(a), 33) - resize(unsigned(b), 33);
                result := std_logic_vector(sum(31 downto 0));
                carry_v := sum(32);
                overflow_v := '0';

            when "100100" => -- AND
                result := a and b;

            when "100101" => -- OR
                result := a or b;

            when "100110" => -- XOR
                result := a xor b;

            when "100111" => -- NOR
                result := not (a or b);

            when "101010" => -- SLT
                if signed(a) < signed(b) then
                    result := x"00000001";
                    flag_v := '1';
                else
                    result := x"00000000";
                    flag_v := '0';
                end if;

            when "101011" => -- SLTU
                if unsigned(a) < unsigned(b) then
                    result := x"00000001";
                    flag_v := '1';
                else
                    result := x"00000000";
                    flag_v := '0';
                end if;

            when "000000" => -- SLL
                result := std_logic_vector(shift_left(unsigned(b), shift_amt));

            when "000010" => -- SRL
                result := std_logic_vector(shift_right(unsigned(b), shift_amt));

            when "000011" => -- SRA
                result := std_logic_vector(shift_right(signed(b), shift_amt));

            when "000100" => -- SLLV
                result := std_logic_vector(shift_left(unsigned(b), shift_amt));

            when "000110" => -- SRLV
                result := std_logic_vector(shift_right(unsigned(b), shift_amt));

            when "000111" => -- SRAV
                result := std_logic_vector(shift_right(signed(b), shift_amt));

            when "001111" => -- LUI
                result := a(15 downto 0) & x"0000";

            when others =>
                result := (others => 'Z');
                carry_v := '0';
                overflow_v := '0';
                flag_v := 'Z';
        end case;

        r <= result;
        if result = x"00000000" then
            zero <= '1';
        else
            zero <= '0';
        end if;
        negative <= result(31);
        carry <= carry_v;
        overflow <= overflow_v;
        flag <= flag_v;
    end process;
end Behavioral;
