library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity mul_fast is
    Port (
        a : in unsigned(15 downto 0);
        b : in unsigned(15 downto 0);
        result : out unsigned(31 downto 0)
    );
end mul_fast;

architecture rtl of mul_fast is
    type pp_array_t is array (natural range <>) of unsigned(31 downto 0);
    signal pp     : pp_array_t(0 to 15);
    signal stage1 : pp_array_t(0 to 10);
    signal stage2 : pp_array_t(0 to 7);
    signal stage3 : pp_array_t(0 to 5);
    signal stage4 : pp_array_t(0 to 3);
    signal stage5 : pp_array_t(0 to 2);
    signal stage6 : pp_array_t(0 to 1);

    function csa_sum(x, y, z : unsigned(31 downto 0)) return unsigned(31 downto 0) is
    begin
        return x xor y xor z;
    end function;

    function csa_carry(x, y, z : unsigned(31 downto 0)) return unsigned(31 downto 0) is
        variable c : unsigned(31 downto 0);
    begin
        c := (x and y) or (x and z) or (y and z);
        return c(30 downto 0) & '0';
    end function;

begin
    gen_pp: for i in 0 to 15 generate
        pp(i) <= resize(a, 32) sll i when b(i) = '1' else (others => '0');
    end generate;

    -- Stage 1: 16 -> 11
    stage1(0) <= csa_sum(pp(0), pp(1), pp(2));
    stage1(1) <= csa_carry(pp(0), pp(1), pp(2));
    stage1(2) <= csa_sum(pp(3), pp(4), pp(5));
    stage1(3) <= csa_carry(pp(3), pp(4), pp(5));
    stage1(4) <= csa_sum(pp(6), pp(7), pp(8));
    stage1(5) <= csa_carry(pp(6), pp(7), pp(8));
    stage1(6) <= csa_sum(pp(9), pp(10), pp(11));
    stage1(7) <= csa_carry(pp(9), pp(10), pp(11));
    stage1(8) <= csa_sum(pp(12), pp(13), pp(14));
    stage1(9) <= csa_carry(pp(12), pp(13), pp(14));
    stage1(10) <= pp(15);

    -- Stage 2: 11 -> 8
    stage2(0) <= csa_sum(stage1(0), stage1(1), stage1(2));
    stage2(1) <= csa_carry(stage1(0), stage1(1), stage1(2));
    stage2(2) <= csa_sum(stage1(3), stage1(4), stage1(5));
    stage2(3) <= csa_carry(stage1(3), stage1(4), stage1(5));
    stage2(4) <= csa_sum(stage1(6), stage1(7), stage1(8));
    stage2(5) <= csa_carry(stage1(6), stage1(7), stage1(8));
    stage2(6) <= stage1(9);
    stage2(7) <= stage1(10);

    -- Stage 3: 8 -> 6
    stage3(0) <= csa_sum(stage2(0), stage2(1), stage2(2));
    stage3(1) <= csa_carry(stage2(0), stage2(1), stage2(2));
    stage3(2) <= csa_sum(stage2(3), stage2(4), stage2(5));
    stage3(3) <= csa_carry(stage2(3), stage2(4), stage2(5));
    stage3(4) <= stage2(6);
    stage3(5) <= stage2(7);

    -- Stage 4: 6 -> 4
    stage4(0) <= csa_sum(stage3(0), stage3(1), stage3(2));
    stage4(1) <= csa_carry(stage3(0), stage3(1), stage3(2));
    stage4(2) <= csa_sum(stage3(3), stage3(4), stage3(5));
    stage4(3) <= csa_carry(stage3(3), stage3(4), stage3(5));

    -- Stage 5: 4 -> 3
    stage5(0) <= csa_sum(stage4(0), stage4(1), stage4(2));
    stage5(1) <= csa_carry(stage4(0), stage4(1), stage4(2));
    stage5(2) <= stage4(3);

    -- Stage 6: 3 -> 2
    stage6(0) <= csa_sum(stage5(0), stage5(1), stage5(2));
    stage6(1) <= csa_carry(stage5(0), stage5(1), stage5(2));

    -- Final adder
    result <= stage6(0) + stage6(1);

end rtl;
