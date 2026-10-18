library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

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
end alu;

architecture Behavioral of alu is
    constant ADD_OP  : std_logic_vector(5 downto 0) := "100000";
    constant ADDU_OP : std_logic_vector(5 downto 0) := "100001";
    constant SUB_OP  : std_logic_vector(5 downto 0) := "100010";
    constant SUBU_OP : std_logic_vector(5 downto 0) := "100011";
    constant AND_OP  : std_logic_vector(5 downto 0) := "100100";
    constant OR_OP   : std_logic_vector(5 downto 0) := "100101";
    constant XOR_OP  : std_logic_vector(5 downto 0) := "100110";
    constant NOR_OP  : std_logic_vector(5 downto 0) := "100111";
    constant SLT_OP  : std_logic_vector(5 downto 0) := "101010";
    constant SLTU_OP : std_logic_vector(5 downto 0) := "101011";
    constant SLL_OP  : std_logic_vector(5 downto 0) := "000000";
    constant SRL_OP  : std_logic_vector(5 downto 0) := "000010";
    constant SRA_OP  : std_logic_vector(5 downto 0) := "000011";
    constant SLLV_OP : std_logic_vector(5 downto 0) := "000100";
    constant SRLV_OP : std_logic_vector(5 downto 0) := "000110";
    constant SRAV_OP : std_logic_vector(5 downto 0) := "000111";
    constant LUI_OP  : std_logic_vector(5 downto 0) := "001111";

    signal res        : std_logic_vector(31 downto 0);
    signal carry_i    : std_logic;
    signal overflow_i : std_logic;
    signal flag_i     : std_logic;
begin
    process(a, b, aluc)
        variable a_u, b_u : unsigned(31 downto 0);
        variable a_s, b_s : signed(31 downto 0);
        variable sum_v    : unsigned(32 downto 0);
        variable diff_v   : unsigned(32 downto 0);
        variable res_v    : std_logic_vector(31 downto 0);
        variable carry_v  : std_logic;
        variable overflow_v : std_logic;
        variable shift_amt : integer range 0 to 31;
        variable temp      : std_logic_vector(31 downto 0);
    begin
        a_u := unsigned(a);
        b_u := unsigned(b);
        a_s := signed(a);
        b_s := signed(b);

        res_v    := (others => '0');
        carry_v  := '0';
        overflow_v := '0';
        shift_amt := to_integer(a_u(4 downto 0));

        case aluc is
            when ADD_OP =>
                sum_v := ('0' & a_u) + ('0' & b_u);
                res_v := std_logic_vector(sum_v(31 downto 0));
                carry_v := sum_v(32);
                if (a_s(31) = b_s(31)) and (res_v(31) /= a_s(31)) then
                    overflow_v := '1';
                end if;

            when ADDU_OP =>
                sum_v := ('0' & a_u) + ('0' & b_u);
                res_v := std_logic_vector(sum_v(31 downto 0));
                carry_v := sum_v(32);
                overflow_v := '0';

            when SUB_OP =>
                diff_v := ('0' & a_u) - ('0' & b_u);
                res_v := std_logic_vector(diff_v(31 downto 0));
                carry_v := diff_v(32);
                if (a_s(31) /= b_s(31)) and (res_v(31) /= a_s(31)) then
                    overflow_v := '1';
                end if;

            when SUBU_OP =>
                diff_v := ('0' & a_u) - ('0' & b_u);
                res_v := std_logic_vector(diff_v(31 downto 0));
                carry_v := diff_v(32);
                overflow_v := '0';

            when AND_OP =>
                res_v := a and b;

            when OR_OP =>
                res_v := a or b;

            when XOR_OP =>
                res_v := a xor b;

            when NOR_OP =>
                res_v := not (a or b);

            when SLT_OP =>
                if a_s < b_s then
                    res_v := X"00000001";
                else
                    res_v := X"00000000";
                end if;

            when SLTU_OP =>
                if a_u < b_u then
                    res_v := X"00000001";
                else
                    res_v := X"00000000";
                end if;

            when SLL_OP | SLLV_OP =>
                res_v := std_logic_vector(shift_left(unsigned(b), shift_amt));

            when SRL_OP | SRLV_OP =>
                res_v := std_logic_vector(shift_right(unsigned(b), shift_amt));

            when SRA_OP | SRAV_OP =>
                temp := b;
                for i in 0 to 30 loop
                    if i < shift_amt then
                        temp := temp(31) & temp(31 downto 1);
                    end if;
                end loop;
                res_v := temp;

            when LUI_OP =>
                res_v := a(15 downto 0) & X"0000";

            when others =>
                res_v := (others => 'Z');
        end case;

        res        <= res_v;
        carry_i    <= carry_v;
        overflow_i <= overflow_v;
        negative   <= res_v(31);

        if res_v = X"00000000" then
            zero <= '1';
        else
            zero <= '0';
        end if;

        if (aluc = SLT_OP) or (aluc = SLTU_OP) then
            if res_v(0) = '1' then
                flag_i <= '1';
            else
                flag_i <= '0';
            end if;
        else
            flag_i <= 'Z';
        end if;
    end process;

    r        <= res;
    carry    <= carry_i;
    overflow <= overflow_i;
    flag     <= flag_i;
end Behavioral;
