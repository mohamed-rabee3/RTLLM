library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

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

architecture rtl of alu is
    constant OP_ADD  : std_logic_vector(5 downto 0) := "100000";
    constant OP_ADDU : std_logic_vector(5 downto 0) := "100001";
    constant OP_SUB  : std_logic_vector(5 downto 0) := "100010";
    constant OP_SUBU : std_logic_vector(5 downto 0) := "100011";
    constant OP_AND  : std_logic_vector(5 downto 0) := "100100";
    constant OP_OR   : std_logic_vector(5 downto 0) := "100101";
    constant OP_XOR  : std_logic_vector(5 downto 0) := "100110";
    constant OP_NOR  : std_logic_vector(5 downto 0) := "100111";
    constant OP_SLT  : std_logic_vector(5 downto 0) := "101010";
    constant OP_SLTU : std_logic_vector(5 downto 0) := "101011";
    constant OP_SLL  : std_logic_vector(5 downto 0) := "000000";
    constant OP_SRL  : std_logic_vector(5 downto 0) := "000010";
    constant OP_SRA  : std_logic_vector(5 downto 0) := "000011";
    constant OP_SLLV : std_logic_vector(5 downto 0) := "000100";
    constant OP_SRLV : std_logic_vector(5 downto 0) := "000110";
    constant OP_SRAV : std_logic_vector(5 downto 0) := "000111";
    constant OP_LUI  : std_logic_vector(5 downto 0) := "001111";
begin
    process(a, b, aluc)
        variable result_v   : std_logic_vector(31 downto 0);
        variable extended_v : unsigned(32 downto 0);
        variable carry_v    : std_logic;
        variable overflow_v : std_logic;
        variable flag_v     : std_logic;
        variable amount_v   : natural range 0 to 33;
    begin
        result_v   := (others => '0');
        extended_v := (others => '0');
        carry_v    := '0';
        overflow_v := '0';
        flag_v     := 'Z';
        amount_v   := 0;

        if aluc = OP_SLLV or aluc = OP_SRLV or aluc = OP_SRAV then
            amount_v := to_integer(unsigned(a(4 downto 0)));
        elsif aluc = OP_SLL or aluc = OP_SRL or aluc = OP_SRA then
            if unsigned(a) > to_unsigned(32, 32) then
                amount_v := 33;
            else
                amount_v := to_integer(unsigned(a(5 downto 0)));
            end if;
        end if;

        case aluc is
            when OP_ADD | OP_ADDU =>
                extended_v := resize(unsigned(a), 33)
                            + resize(unsigned(b), 33);
                result_v := std_logic_vector(extended_v(31 downto 0));
                carry_v := extended_v(32);
                if aluc = OP_ADD then
                    overflow_v := (not (a(31) xor b(31)))
                                  and (result_v(31) xor a(31));
                end if;

            when OP_SUB | OP_SUBU =>
                extended_v := resize(unsigned(a), 33)
                            - resize(unsigned(b), 33);
                result_v := std_logic_vector(extended_v(31 downto 0));
                carry_v := extended_v(32);
                if aluc = OP_SUB then
                    overflow_v := (a(31) xor b(31))
                                  and (result_v(31) xor a(31));
                end if;

            when OP_AND =>
                result_v := a and b;

            when OP_OR =>
                result_v := a or b;

            when OP_XOR =>
                result_v := a xor b;

            when OP_NOR =>
                result_v := not (a or b);

            when OP_SLT =>
                if signed(a) < signed(b) then
                    result_v(0) := '1';
                end if;
                flag_v := '1';

            when OP_SLTU =>
                if unsigned(a) < unsigned(b) then
                    result_v(0) := '1';
                end if;
                flag_v := '1';

            when OP_SLL | OP_SLLV =>
                extended_v := shift_left(resize(unsigned(b), 33), amount_v);
                result_v := std_logic_vector(extended_v(31 downto 0));
                carry_v := extended_v(32);

            when OP_SRL | OP_SRLV =>
                result_v := std_logic_vector(shift_right(unsigned(b), amount_v));
                if amount_v >= 1 and amount_v <= 32 then
                    carry_v := b(amount_v - 1);
                end if;

            when OP_SRA | OP_SRAV =>
                result_v := std_logic_vector(shift_right(signed(b), amount_v));
                if amount_v >= 1 and amount_v <= 32 then
                    carry_v := b(amount_v - 1);
                elsif amount_v > 32 then
                    carry_v := b(31);
                end if;

            when OP_LUI =>
                result_v := a(31 downto 16) & x"0000";

            when others =>
                result_v := (others => 'Z');
                carry_v := 'Z';
                overflow_v := 'Z';
        end case;

        r        <= result_v;
        carry    <= carry_v;
        negative <= result_v(31);
        overflow <= overflow_v;
        flag     <= flag_v;

        if result_v = x"00000000" then
            zero <= '1';
        else
            zero <= '0';
        end if;
    end process;
end architecture rtl;
