library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity alu is
    Port (
        a     : in  STD_LOGIC_VECTOR (31 downto 0);
        b     : in  STD_LOGIC_VECTOR (31 downto 0);
        aluc  : in  STD_LOGIC_VECTOR (5 downto 0);
        r     : out STD_LOGIC_VECTOR (31 downto 0);
        zero  : out STD_LOGIC;
        carry : out STD_LOGIC;
        negative : out STD_LOGIC;
        overflow : out STD_LOGIC;
        flag  : out STD_LOGIC
    );
end alu;

architecture Behavioral of alu is
    constant ADD  : STD_LOGIC_VECTOR(5 downto 0) := "100000";
    constant ADDU : STD_LOGIC_VECTOR(5 downto 0) := "100001";
    constant SUB  : STD_LOGIC_VECTOR(5 downto 0) := "100010";
    constant SUBU : STD_LOGIC_VECTOR(5 downto 0) := "100011";
    constant AND_OP : STD_LOGIC_VECTOR(5 downto 0) := "100100";
    constant OR_OP  : STD_LOGIC_VECTOR(5 downto 0) := "100101";
    constant XOR_OP : STD_LOGIC_VECTOR(5 downto 0) := "100110";
    constant NOR_OP : STD_LOGIC_VECTOR(5 downto 0) := "100111";
    constant SLT  : STD_LOGIC_VECTOR(5 downto 0) := "101010";
    constant SLTU : STD_LOGIC_VECTOR(5 downto 0) := "101011";
    constant SLL  : STD_LOGIC_VECTOR(5 downto 0) := "000000";
    constant SRL  : STD_LOGIC_VECTOR(5 downto 0) := "000010";
    constant SRA  : STD_LOGIC_VECTOR(5 downto 0) := "000011";
    constant SLLV : STD_LOGIC_VECTOR(5 downto 0) := "000100";
    constant SRLV : STD_LOGIC_VECTOR(5 downto 0) := "000110";
    constant SRAV : STD_LOGIC_VECTOR(5 downto 0) := "000111";
    constant LUI  : STD_LOGIC_VECTOR(5 downto 0) := "001111";
begin
    process(a, b, aluc)
        variable sum33 : unsigned(32 downto 0);
        variable shift_amt : integer range 0 to 31;
        variable res_var : std_logic_vector(31 downto 0);
        variable carry_var : std_logic;
        variable overflow_var : std_logic;
        variable flag_var : std_logic;
    begin
        -- defaults
        res_var := (others => '0');
        carry_var := '0';
        overflow_var := '0';
        flag_var := 'Z';
        shift_amt := to_integer(unsigned(a(4 downto 0)));

        if aluc = ADD then
            sum33 := ('0' & unsigned(a)) + ('0' & unsigned(b));
            res_var := std_logic_vector(sum33(31 downto 0));
            carry_var := sum33(32);
            overflow_var := (not (a(31) xor b(31))) and (a(31) xor sum33(31));
        elsif aluc = ADDU then
            sum33 := ('0' & unsigned(a)) + ('0' & unsigned(b));
            res_var := std_logic_vector(sum33(31 downto 0));
            carry_var := sum33(32);
            overflow_var := '0';
        elsif aluc = SUB then
            sum33 := ('0' & unsigned(a)) + (not ('0' & unsigned(b))) + 1;
            res_var := std_logic_vector(sum33(31 downto 0));
            carry_var := sum33(32);
            overflow_var := (a(31) xor b(31)) and (a(31) xor sum33(31));
        elsif aluc = SUBU then
            sum33 := ('0' & unsigned(a)) + (not ('0' & unsigned(b))) + 1;
            res_var := std_logic_vector(sum33(31 downto 0));
            carry_var := sum33(32);
            overflow_var := '0';
        elsif aluc = AND_OP then
            res_var := a and b;
        elsif aluc = OR_OP then
            res_var := a or b;
        elsif aluc = XOR_OP then
            res_var := a xor b;
        elsif aluc = NOR_OP then
            res_var := a nor b;
        elsif aluc = SLT then
            if signed(a) < signed(b) then
                res_var := x"00000001";
                flag_var := '1';
            else
                res_var := x"00000000";
                flag_var := '0';
            end if;
        elsif aluc = SLTU then
            if unsigned(a) < unsigned(b) then
                res_var := x"00000001";
                flag_var := '1';
            else
                res_var := x"00000000";
                flag_var := '0';
            end if;
        elsif aluc = SLL then
            res_var := std_logic_vector(shift_left(unsigned(b), shift_amt));
        elsif aluc = SRL then
            res_var := std_logic_vector(shift_right(unsigned(b), shift_amt));
        elsif aluc = SRA then
            res_var := std_logic_vector(shift_right(signed(b), shift_amt));
        elsif aluc = SLLV then
            res_var := std_logic_vector(shift_left(unsigned(b), shift_amt));
        elsif aluc = SRLV then
            res_var := std_logic_vector(shift_right(unsigned(b), shift_amt));
        elsif aluc = SRAV then
            res_var := std_logic_vector(shift_right(signed(b), shift_amt));
        elsif aluc = LUI then
            res_var := a(15 downto 0) & x"0000";
        else
            res_var := (others => 'Z');
            -- carry_var and overflow_var remain '0'
            -- flag_var remains 'Z'
        end if;

        r <= res_var;
        carry <= carry_var;
        overflow <= overflow_var;
        flag <= flag_var;
        if res_var = x"00000000" then
            zero <= '1';
        else
            zero <= '0';
        end if;
        negative <= res_var(31);
    end process;
end Behavioral;
