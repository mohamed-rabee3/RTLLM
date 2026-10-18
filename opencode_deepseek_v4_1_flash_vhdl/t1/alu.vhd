library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity alu is
    Port (
        a        : in  STD_LOGIC_VECTOR (31 downto 0);
        b        : in  STD_LOGIC_VECTOR (31 downto 0);
        aluc     : in  STD_LOGIC_VECTOR (5 downto 0);
        r        : out STD_LOGIC_VECTOR (31 downto 0);
        zero     : out STD_LOGIC;
        carry    : out STD_LOGIC;
        negative : out STD_LOGIC;
        overflow : out STD_LOGIC;
        flag     : out STD_LOGIC
    );
end alu;

architecture Behavioral of alu is
    constant ADD   : STD_LOGIC_VECTOR(5 downto 0) := "100000";
    constant ADDU  : STD_LOGIC_VECTOR(5 downto 0) := "100001";
    constant SUB   : STD_LOGIC_VECTOR(5 downto 0) := "100010";
    constant SUBU  : STD_LOGIC_VECTOR(5 downto 0) := "100011";
    constant ANDOP : STD_LOGIC_VECTOR(5 downto 0) := "100100";
    constant OROP  : STD_LOGIC_VECTOR(5 downto 0) := "100101";
    constant XOROP : STD_LOGIC_VECTOR(5 downto 0) := "100110";
    constant NOROP : STD_LOGIC_VECTOR(5 downto 0) := "100111";
    constant SLT   : STD_LOGIC_VECTOR(5 downto 0) := "101010";
    constant SLTU  : STD_LOGIC_VECTOR(5 downto 0) := "101011";
    constant SLL   : STD_LOGIC_VECTOR(5 downto 0) := "000000";
    constant SRL   : STD_LOGIC_VECTOR(5 downto 0) := "000010";
    constant SRA   : STD_LOGIC_VECTOR(5 downto 0) := "000011";
    constant SLLV  : STD_LOGIC_VECTOR(5 downto 0) := "000100";
    constant SRLV  : STD_LOGIC_VECTOR(5 downto 0) := "000110";
    constant SRAV  : STD_LOGIC_VECTOR(5 downto 0) := "000111";
    constant LUI   : STD_LOGIC_VECTOR(5 downto 0) := "001111";
begin
    process(a, b, aluc)
        variable res       : STD_LOGIC_VECTOR(31 downto 0);
        variable zero_v    : STD_LOGIC;
        variable carry_v   : STD_LOGIC;
        variable negative_v: STD_LOGIC;
        variable overflow_v: STD_LOGIC;
        variable flag_v    : STD_LOGIC;
        variable sum33     : unsigned(32 downto 0);
        variable diff33    : unsigned(32 downto 0);
        variable sa        : integer range 0 to 31;
    begin
        res        := (others => '0');
        zero_v     := '0';
        carry_v    := '0';
        negative_v := '0';
        overflow_v := '0';
        flag_v     := 'Z';

        case aluc is
            when ADD | ADDU =>
                sum33 := unsigned('0' & a) + unsigned('0' & b);
                res := std_logic_vector(sum33(31 downto 0));
                carry_v := sum33(32);
                if aluc = ADD then
                    overflow_v := (a(31) xnor b(31)) and (res(31) xor a(31));
                else
                    overflow_v := '0';
                end if;
                negative_v := res(31);

            when SUB | SUBU =>
                diff33 := unsigned('0' & a) - unsigned('0' & b);
                res := std_logic_vector(diff33(31 downto 0));
                carry_v := diff33(32);
                if aluc = SUB then
                    overflow_v := (a(31) xor b(31)) and (res(31) xor a(31));
                else
                    overflow_v := '0';
                end if;
                negative_v := res(31);

            when ANDOP =>
                res := a and b;
                negative_v := res(31);

            when OROP =>
                res := a or b;
                negative_v := res(31);

            when XOROP =>
                res := a xor b;
                negative_v := res(31);

            when NOROP =>
                res := not (a or b);
                negative_v := res(31);

            when SLT =>
                if signed(a) < signed(b) then
                    res := x"00000001";
                    flag_v := '1';
                else
                    res := x"00000000";
                    flag_v := '0';
                end if;
                negative_v := res(31);

            when SLTU =>
                if unsigned(a) < unsigned(b) then
                    res := x"00000001";
                    flag_v := '1';
                else
                    res := x"00000000";
                    flag_v := '0';
                end if;
                negative_v := res(31);

            when SLL =>
                sa := to_integer(unsigned(a(4 downto 0)));
                res := std_logic_vector(shift_left(unsigned(b), sa));
                negative_v := res(31);

            when SRL =>
                sa := to_integer(unsigned(a(4 downto 0)));
                res := std_logic_vector(shift_right(unsigned(b), sa));
                negative_v := res(31);

            when SRA =>
                sa := to_integer(unsigned(a(4 downto 0)));
                res := std_logic_vector(shift_right(signed(b), sa));
                negative_v := res(31);

            when SLLV =>
                sa := to_integer(unsigned(a(4 downto 0)));
                res := std_logic_vector(shift_left(unsigned(b), sa));
                negative_v := res(31);

            when SRLV =>
                sa := to_integer(unsigned(a(4 downto 0)));
                res := std_logic_vector(shift_right(unsigned(b), sa));
                negative_v := res(31);

            when SRAV =>
                sa := to_integer(unsigned(a(4 downto 0)));
                res := std_logic_vector(shift_right(signed(b), sa));
                negative_v := res(31);

            when LUI =>
                res := a(31 downto 16) & x"0000";
                negative_v := res(31);

            when others =>
                res        := (others => 'Z');
                zero_v     := '0';
                carry_v    := '0';
                negative_v := '0';
                overflow_v := '0';
                flag_v     := 'Z';
        end case;

        if res = x"00000000" then
            zero_v := '1';
        else
            zero_v := '0';
        end if;

        r        <= res;
        zero     <= zero_v;
        carry    <= carry_v;
        negative <= negative_v;
        overflow <= overflow_v;
        flag     <= flag_v;
    end process;
end Behavioral;
