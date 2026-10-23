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
        variable res_v      : std_logic_vector(32 downto 0);
        variable overflow_v : std_logic;
        variable flag_v     : std_logic;
        variable amount_v   : natural range 0 to 33;
    begin
        res_v      := (others => '0');
        overflow_v := '0';
        flag_v     := 'Z';
        amount_v   := 0;

        case aluc is
            when OP_SLLV | OP_SRLV | OP_SRAV =>
                amount_v := to_integer(unsigned(a(4 downto 0)));

            when OP_SLL | OP_SRL | OP_SRA =>
                if unsigned(a) > to_unsigned(32, 32) then
                    amount_v := 33;
                else
                    amount_v := to_integer(unsigned(a(5 downto 0)));
                end if;

            when others =>
                null;
        end case;

        case aluc is
            when OP_ADD | OP_ADDU =>
                res_v := std_logic_vector(
                    resize(unsigned(a), 33) + resize(unsigned(b), 33)
                );

                if aluc = OP_ADD then
                    overflow_v := (not (a(31) xor b(31))) and
                                  (res_v(31) xor a(31));
                end if;

            when OP_SUB | OP_SUBU =>
                res_v := std_logic_vector(
                    resize(unsigned(a), 33) - resize(unsigned(b), 33)
                );

                if aluc = OP_SUB then
                    overflow_v := (a(31) xor b(31)) and
                                  (res_v(31) xor a(31));
                end if;

            when OP_AND =>
                res_v(31 downto 0) := a and b;

            when OP_OR =>
                res_v(31 downto 0) := a or b;

            when OP_XOR =>
                res_v(31 downto 0) := a xor b;

            when OP_NOR =>
                res_v(31 downto 0) := not (a or b);

            when OP_SLT =>
                if signed(a) < signed(b) then
                    res_v(0) := '1';
                end if;
                flag_v := '1';

            when OP_SLTU =>
                if unsigned(a) < unsigned(b) then
                    res_v(0) := '1';
                end if;
                flag_v := '1';

            when OP_SLL | OP_SLLV =>
                res_v := std_logic_vector(
                    shift_left(resize(unsigned(b), 33), amount_v)
                );

            when OP_SRL | OP_SRLV =>
                res_v := std_logic_vector(
                    shift_right(resize(unsigned(b), 33), amount_v)
                );

            when OP_SRA | OP_SRAV =>
                res_v(31 downto 0) := std_logic_vector(
                    shift_right(signed(b), amount_v)
                );

            when OP_LUI =>
                res_v(31 downto 0) := a(31 downto 16) & x"0000";

            when others =>
                res_v := (others => 'Z');
        end case;

        r        <= res_v(31 downto 0);
        carry    <= res_v(32);
        negative <= res_v(31);
        overflow <= overflow_v;
        flag     <= flag_v;

        if res_v(31 downto 0) = x"00000000" then
            zero <= '1';
        else
            zero <= '0';
        end if;
    end process;
end architecture rtl;
