library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity mul_fast is
    port (
        a      : in  std_logic_vector(15 downto 0);
        b      : in  std_logic_vector(15 downto 0);
        result : out std_logic_vector(31 downto 0)
    );
end mul_fast;

architecture rtl of mul_fast is
    type pp_array is array (0 to 15) of unsigned(31 downto 0);
    type csa_out is record
        sum   : unsigned(31 downto 0);
        carry : unsigned(31 downto 0);
    end record;
    type csa_array_5 is array (0 to 4) of csa_out;
    type csa_array_3 is array (0 to 2) of csa_out;
    type csa_array_2 is array (0 to 1) of csa_out;

    function csa(a, b, c : unsigned(31 downto 0)) return csa_out is
        variable r     : csa_out;
        variable carry : unsigned(31 downto 0);
    begin
        r.sum := a xor b xor c;
        carry := (others => '0');
        for i in 0 to 30 loop
            carry(i+1) := (a(i) and b(i)) or (a(i) and c(i)) or (b(i) and c(i));
        end loop;
        r.carry := carry;
        return r;
    end function;

    signal pp  : pp_array;
    signal st1 : csa_array_5;
    signal st2 : csa_array_3;
    signal st3 : csa_array_2;
    signal st4 : csa_array_2;
    signal st5 : csa_out;
    signal st6 : csa_out;
begin
    gen_pp: for i in 0 to 15 generate
        gen_j: for j in 0 to 31 generate
            gen_bit: if (j >= i and j < i+16) generate
                pp(i)(j) <= a(j-i) and b(i);
            else generate
                pp(i)(j) <= '0';
            end generate;
        end generate;
    end generate;

    st1(0) <= csa(pp(0), pp(1), pp(2));
    st1(1) <= csa(pp(3), pp(4), pp(5));
    st1(2) <= csa(pp(6), pp(7), pp(8));
    st1(3) <= csa(pp(9), pp(10), pp(11));
    st1(4) <= csa(pp(12), pp(13), pp(14));

    st2(0) <= csa(st1(0).sum, st1(0).carry, st1(1).sum);
    st2(1) <= csa(st1(1).carry, st1(2).sum, st1(2).carry);
    st2(2) <= csa(st1(3).sum, st1(3).carry, st1(4).sum);

    st3(0) <= csa(st2(0).sum, st2(0).carry, st2(1).sum);
    st3(1) <= csa(st2(1).carry, st2(2).sum, st2(2).carry);

    st4(0) <= csa(st3(0).sum, st3(0).carry, st3(1).sum);
    st4(1) <= csa(st3(1).carry, st1(4).carry, pp(15));

    st5 <= csa(st4(0).sum, st4(0).carry, st4(1).sum);

    st6 <= csa(st5.sum, st5.carry, st4(1).carry);

    result <= std_logic_vector(st6.sum + st6.carry);
end rtl;
