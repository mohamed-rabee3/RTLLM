library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mul_fast is
    port (
        a      : in  std_logic_vector(15 downto 0);
        b      : in  std_logic_vector(15 downto 0);
        result : out std_logic_vector(31 downto 0)
    );
end entity mul_fast;

architecture rtl of mul_fast is
    subtype word_t is unsigned(31 downto 0);
    type word_array_t is array (natural range <>) of word_t;

    signal stage0 : word_array_t(0 to 15);
    signal stage1 : word_array_t(0 to 10);
    signal stage2 : word_array_t(0 to 7);
    signal stage3 : word_array_t(0 to 5);
    signal stage4 : word_array_t(0 to 3);
    signal stage5 : word_array_t(0 to 2);
    signal stage6 : word_array_t(0 to 1);

    function csa_carry(x, y, z : word_t) return word_t is
    begin
        return shift_left((x and y) or (x and z) or (y and z), 1);
    end function csa_carry;
begin
    -- Generate the sixteen shifted partial products.
    partial_products : for i in 0 to 15 generate
        stage0(i) <= shift_left(resize(unsigned(a), 32), i)
                     when b(i) = '1' else (others => '0');
    end generate partial_products;

    -- Each compressor replaces three operands with sum and carry operands.
    -- Reduction: 16 -> 11.
    reduce_stage1 : for i in 0 to 4 generate
        stage1(2*i) <= stage0(3*i) xor
                       stage0(3*i + 1) xor
                       stage0(3*i + 2);
        stage1(2*i + 1) <= csa_carry(
            stage0(3*i), stage0(3*i + 1), stage0(3*i + 2)
        );
    end generate reduce_stage1;
    stage1(10) <= stage0(15);

    -- Reduction: 11 -> 8.
    reduce_stage2 : for i in 0 to 2 generate
        stage2(2*i) <= stage1(3*i) xor
                       stage1(3*i + 1) xor
                       stage1(3*i + 2);
        stage2(2*i + 1) <= csa_carry(
            stage1(3*i), stage1(3*i + 1), stage1(3*i + 2)
        );
    end generate reduce_stage2;
    stage2(6) <= stage1(9);
    stage2(7) <= stage1(10);

    -- Reduction: 8 -> 6.
    reduce_stage3 : for i in 0 to 1 generate
        stage3(2*i) <= stage2(3*i) xor
                       stage2(3*i + 1) xor
                       stage2(3*i + 2);
        stage3(2*i + 1) <= csa_carry(
            stage2(3*i), stage2(3*i + 1), stage2(3*i + 2)
        );
    end generate reduce_stage3;
    stage3(4) <= stage2(6);
    stage3(5) <= stage2(7);

    -- Reduction: 6 -> 4.
    reduce_stage4 : for i in 0 to 1 generate
        stage4(2*i) <= stage3(3*i) xor
                       stage3(3*i + 1) xor
                       stage3(3*i + 2);
        stage4(2*i + 1) <= csa_carry(
            stage3(3*i), stage3(3*i + 1), stage3(3*i + 2)
        );
    end generate reduce_stage4;

    -- Reduction: 4 -> 3.
    stage5(0) <= stage4(0) xor stage4(1) xor stage4(2);
    stage5(1) <= csa_carry(stage4(0), stage4(1), stage4(2));
    stage5(2) <= stage4(3);

    -- Reduction: 3 -> 2.
    stage6(0) <= stage5(0) xor stage5(1) xor stage5(2);
    stage6(1) <= csa_carry(stage5(0), stage5(1), stage5(2));

    -- Only the final addition propagates carries across the word.
    result <= std_logic_vector(stage6(0) + stage6(1));
end architecture rtl;
