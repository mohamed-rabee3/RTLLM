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
    process (a, b, aluc)
        variable res         : std_logic_vector(32 downto 0);
        variable shift_count : natural range 0 to 33;
        variable ov          : std_logic;
        variable fl          : std_logic;
    begin
        res := (others => '0');
        ov  := '0';
        fl  := 'Z';

        if aluc = OP_SLLV or aluc = OP_SRLV or aluc = OP_SRAV then
            shift_count := to_integer(unsigned(a(4 downto 0)));
        elsif unsigned(a) > to_unsigned(32, 32) then
            shift_count := 33;
        else
            shift_count := to_integer(unsigned(a(5 downto 0)));
        end if;

        case aluc is
            when OP_ADD | OP_ADDU =>
                res := std_logic_vector(
                    resize(unsigned(a), 33) + resize(unsigned(b), 33)
                );
                if aluc = OP_ADD then
                    ov := (not (a(31) xor b(31))) and
                          (res(31) xor a(31));
                end if;

            when OP_SUB | OP_SUBU =>
                res := std_logic_vector(
                    resize(unsigned(a), 33) - resize(unsigned(b), 33)
                );
                if aluc = OP_SUB then
                    ov := (a(31) xor b(31)) and
                          (res(31) xor a(31));
                end if;

            when OP_AND =>
                res(31 downto 0) := a and b;

            when OP_OR =>
                res(31 downto 0) := a or b;

            when OP_XOR =>
                res(31 downto 0) := a xor b;

            when OP_NOR =>
                res(31 downto 0) := not (a or b);

            when OP_SLT =>
                fl := '1';
                if signed(a) < signed(b) then
                    res(0) := '1';
                end if;

            when OP_SLTU =>
                fl := '1';
                if unsigned(a) < unsigned(b) then
                    res(0) := '1';
                end if;

            when OP_SLL | OP_SLLV =>
                res := std_logic_vector(
                    shift_left(resize(unsigned(b), 33), shift_count)
                );

            when OP_SRL | OP_SRLV =>
                res := std_logic_vector(
                    shift_right(resize(unsigned(b), 33), shift_count)
                );

            when OP_SRA | OP_SRAV =>
                res := std_logic_vector(
                    shift_right(resize(signed(b), 33), shift_count)
                );

            when OP_LUI =>
                res(31 downto 0) := a(31 downto 16) & x"0000";

            when others =>
                res := (others => 'Z');
        end case;

        r        <= res(31 downto 0);
        carry    <= res(32);
        negative <= res(31);
        overflow <= ov;
        flag     <= fl;

        if res(31 downto 0) = x"00000000" then
            zero <= '1';
        else
            zero <= '0';
        end if;
    end process;
end architecture rtl;
