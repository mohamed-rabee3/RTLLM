library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity alu is
    port (
        a        : in  std_logic_vector(31 downto 0);
        b        : in  std_logic_vector(31 downto 0);
        aluc     : in  std_logic_vector(5 downto 0);
        r        : out std_logic_vector(31 downto 0);
        zero     : out std_logic;
        carry    : out std_logic;
        negative : out std_logic;
        overflow : out std_logic;
        flag     : out std_logic
    );
end entity alu;

architecture Behavioral of alu is

    -- Opcode constants
    constant ADD  : std_logic_vector(5 downto 0) := "100000";
    constant ADDU : std_logic_vector(5 downto 0) := "100001";
    constant SUB  : std_logic_vector(5 downto 0) := "100010";
    constant SUBU : std_logic_vector(5 downto 0) := "100011";
    constant AND_OP : std_logic_vector(5 downto 0) := "100100";
    constant OR_OP  : std_logic_vector(5 downto 0) := "100101";
    constant XOR_OP : std_logic_vector(5 downto 0) := "100110";
    constant NOR_OP : std_logic_vector(5 downto 0) := "100111";
    constant SLT  : std_logic_vector(5 downto 0) := "101010";
    constant SLTU : std_logic_vector(5 downto 0) := "101011";
    constant SLL  : std_logic_vector(5 downto 0) := "000000";
    constant SRL  : std_logic_vector(5 downto 0) := "000010";
    constant SRA  : std_logic_vector(5 downto 0) := "000011";
    constant SLLV : std_logic_vector(5 downto 0) := "000100";
    constant SRLV : std_logic_vector(5 downto 0) := "000110";
    constant SRAV : std_logic_vector(5 downto 0) := "000111";
    constant LUI  : std_logic_vector(5 downto 0) := "001111";

    signal res_int      : std_logic_vector(31 downto 0);
    signal carry_int    : std_logic;
    signal overflow_int : std_logic;
    signal negative_int : std_logic;
    signal zero_int     : std_logic;
    signal flag_int     : std_logic;

begin

    process(a, b, aluc)
        variable a_signed   : signed(31 downto 0);
        variable b_signed   : signed(31 downto 0);
        variable a_unsigned : unsigned(31 downto 0);
        variable b_unsigned : unsigned(31 downto 0);
        variable temp_unsigned : unsigned(32 downto 0);
        variable shift_amt  : integer range 0 to 31;
        variable res_var    : std_logic_vector(31 downto 0);
    begin
        -- Default values (high‑impedance result, flags to '0', flag to 'Z')
        res_var      := (others => 'Z');
        carry_int    <= '0';
        overflow_int <= '0';
        flag_int     <= 'Z';

        -- Convert operands to signed and unsigned for convenience
        a_signed   := signed(a);
        b_signed   := signed(b);
        a_unsigned := unsigned(a);
        b_unsigned := unsigned(b);
        shift_amt  := to_integer(unsigned(a(4 downto 0)));  -- shift amount from a[4:0]

        case aluc is
            when ADD =>
                res_var := std_logic_vector(a_signed + b_signed);
                -- signed overflow detection
                if (a_signed(31) = b_signed(31)) and (res_var(31) /= a_signed(31)) then
                    overflow_int <= '1';
                end if;
                -- carry out from 33‑bit addition
                temp_unsigned := ('0' & a_unsigned) + ('0' & b_unsigned);
                carry_int <= temp_unsigned(32);

            when ADDU =>
                res_var := std_logic_vector(a_unsigned + b_unsigned);
                temp_unsigned := ('0' & a_unsigned) + ('0' & b_unsigned);
                carry_int <= temp_unsigned(32);

            when SUB =>
                res_var := std_logic_vector(a_signed - b_signed);
                if (a_signed(31) /= b_signed(31)) and (res_var(31) /= a_signed(31)) then
                    overflow_int <= '1';
                end if;
                -- borrow detection through addition of complement
                temp_unsigned := ('0' & a_unsigned) + ('0' & (not b_unsigned)) + 1;
                carry_int <= temp_unsigned(32);

            when SUBU =>
                res_var := std_logic_vector(a_unsigned - b_unsigned);
                temp_unsigned := ('0' & a_unsigned) + ('0' & (not b_unsigned)) + 1;
                carry_int <= temp_unsigned(32);

            when AND_OP =>
                res_var := a and b;

            when OR_OP =>
                res_var := a or b;

            when XOR_OP =>
                res_var := a xor b;

            when NOR_OP =>
                res_var := a nor b;

            when SLT =>
                if a_signed < b_signed then
                    res_var := x"00000001";
                    flag_int <= '1';
                else
                    res_var := x"00000000";
                    flag_int <= '0';
                end if;

            when SLTU =>
                if a_unsigned < b_unsigned then
                    res_var := x"00000001";
                    flag_int <= '1';
                else
                    res_var := x"00000000";
                    flag_int <= '0';
                end if;

            when SLL =>
                res_var := std_logic_vector(shift_left(b_unsigned, shift_amt));

            when SRL =>
                res_var := std_logic_vector(shift_right(b_unsigned, shift_amt));

            when SRA =>
                res_var := std_logic_vector(shift_right(b_signed, shift_amt));

            when SLLV =>
                res_var := std_logic_vector(shift_left(b_unsigned, shift_amt));

            when SRLV =>
                res_var := std_logic_vector(shift_right(b_unsigned, shift_amt));

            when SRAV =>
                res_var := std_logic_vector(shift_right(b_signed, shift_amt));

            when LUI =>
                res_var := a(31 downto 16) & x"0000";

            when others =>
                -- Keep high‑impedance result and default control outputs
                null;
        end case;

        -- Drive internal result
        res_int <= res_var;

        -- Compute zero and negative flags from the actual result
        if res_var = x"00000000" then
            zero_int <= '1';
        else
            zero_int <= '0';
        end if;
        negative_int <= res_var(31);

        -- flag_int already set in SLT/SLTU cases, otherwise stays 'Z'

    end process;

    -- Output assignments
    r        <= res_int;
    zero     <= zero_int;
    carry    <= carry_int;
    negative <= negative_int;
    overflow <= overflow_int;
    flag     <= flag_int;

end architecture Behavioral;