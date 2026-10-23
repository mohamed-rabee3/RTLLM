library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity mul_fast is
    Port ( a : in  STD_LOGIC_VECTOR (15 downto 0);
           b : in  STD_LOGIC_VECTOR (15 downto 0);
           result : out  STD_LOGIC_VECTOR (31 downto 0));
end mul_fast;

architecture Behavioral of mul_fast is

    type pp_array is array (0 to 15) of unsigned(31 downto 0);
    signal pp : pp_array;

    -- Stage 1
    signal s1_0, c1_0, s1_1, c1_1, s1_2, c1_2, s1_3, c1_3, s1_4, c1_4 : unsigned(31 downto 0);
    -- Stage 2
    signal s2_0, c2_0, s2_1, c2_1, s2_2, c2_2 : unsigned(31 downto 0);
    -- Stage 3
    signal s3_0, c3_0, s3_1, c3_1 : unsigned(31 downto 0);
    -- Stage 4
    signal s4_0, c4_0, s4_1, c4_1 : unsigned(31 downto 0);
    -- Stage 5
    signal s5_0, c5_0 : unsigned(31 downto 0);
    -- Stage 6
    signal s6_0, c6_0 : unsigned(31 downto 0);

    function csa_sum(x, y, z : unsigned(31 downto 0)) return unsigned is
        variable s : unsigned(31 downto 0);
    begin
        for i in 0 to 31 loop
            s(i) := x(i) xor y(i) xor z(i);
        end loop;
        return s;
    end function;

    function csa_carry(x, y, z : unsigned(31 downto 0)) return unsigned is
        variable c : unsigned(31 downto 0);
    begin
        c(0) := '0';
        for i in 0 to 30 loop
            c(i+1) := (x(i) and y(i)) or (y(i) and z(i)) or (z(i) and x(i));
        end loop;
        return c;
    end function;

begin

    -- Generate 16 partial products
    gen_pp: for i in 0 to 15 generate
        pp(i) <= shift_left(resize(unsigned(a), 32), i) when b(i) = '1' else (others => '0');
    end generate;

    -- Wallace tree reduction
    -- Stage 1
    s1_0 <= csa_sum(pp(0), pp(1), pp(2));
    c1_0 <= csa_carry(pp(0), pp(1), pp(2));

    s1_1 <= csa_sum(pp(3), pp(4), pp(5));
    c1_1 <= csa_carry(pp(3), pp(4), pp(5));

    s1_2 <= csa_sum(pp(6), pp(7), pp(8));
    c1_2 <= csa_carry(pp(6), pp(7), pp(8));

    s1_3 <= csa_sum(pp(9), pp(10), pp(11));
    c1_3 <= csa_carry(pp(9), pp(10), pp(11));

    s1_4 <= csa_sum(pp(12), pp(13), pp(14));
    c1_4 <= csa_carry(pp(12), pp(13), pp(14));

    -- Stage 2
    s2_0 <= csa_sum(s1_0, c1_0, s1_1);
    c2_0 <= csa_carry(s1_0, c1_0, s1_1);

    s2_1 <= csa_sum(c1_1, s1_2, c1_2);
    c2_1 <= csa_carry(c1_1, s1_2, c1_2);

    s2_2 <= csa_sum(s1_3, c1_3, s1_4);
    c2_2 <= csa_carry(s1_3, c1_3, s1_4);

    -- Stage 3
    s3_0 <= csa_sum(s2_0, c2_0, s2_1);
    c3_0 <= csa_carry(s2_0, c2_0, s2_1);

    s3_1 <= csa_sum(c2_1, s2_2, c2_2);
    c3_1 <= csa_carry(c2_1, s2_2, c2_2);

    -- Stage 4
    s4_0 <= csa_sum(s3_0, c3_0, s3_1);
    c4_0 <= csa_carry(s3_0, c3_0, s3_1);

    s4_1 <= csa_sum(c3_1, c1_4, pp(15));
    c4_1 <= csa_carry(c3_1, c1_4, pp(15));

    -- Stage 5
    s5_0 <= csa_sum(s4_0, c4_0, s4_1);
    c5_0 <= csa_carry(s4_0, c4_0, s4_1);

    -- Stage 6
    s6_0 <= csa_sum(s5_0, c5_0, c4_1);
    c6_0 <= csa_carry(s5_0, c5_0, c4_1);

    -- Final addition
    result <= std_logic_vector(s6_0 + c6_0);

end Behavioral;
