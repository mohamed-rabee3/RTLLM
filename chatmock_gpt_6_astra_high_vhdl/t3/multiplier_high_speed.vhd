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

    signal pp : word_array_t(0 to 15);
    signal s1 : word_array_t(0 to 10);
    signal s2 : word_array_t(0 to 7);
    signal s3 : word_array_t(0 to 5);
    signal s4 : word_array_t(0 to 3);
    signal s5 : word_array_t(0 to 2);
    signal s6 : word_array_t(0 to 1);

    function csa_sum(x, y, z : word_t) return word_t is
    begin
        return x xor y xor z;
    end function;

    function csa_carry(x, y, z : word_t) return word_t is
    begin
        return shift_left((x and y) or (x and z) or (y and z), 1);
    end function;

begin
    -- Generate sixteen aligned partial products.
    gen_partial_products : for i in 0 to 15 generate
        pp(i) <= shift_left(resize(unsigned(a), 32), i)
                 when b(i) = '1' else (others => '0');
    end generate;

    -- Carry-save reduction: 16 operands to 11.
    gen_stage1 : for i in 0 to 4 generate
        s1(2*i)   <= csa_sum(pp(3*i), pp(3*i+1), pp(3*i+2));
        s1(2*i+1) <= csa_carry(pp(3*i), pp(3*i+1), pp(3*i+2));
    end generate;
    s1(10) <= pp(15);

    -- Carry-save reduction: 11 operands to 8.
    gen_stage2 : for i in 0 to 2 generate
        s2(2*i)   <= csa_sum(s1(3*i), s1(3*i+1), s1(3*i+2));
        s2(2*i+1) <= csa_carry(s1(3*i), s1(3*i+1), s1(3*i+2));
    end generate;
    s2(6) <= s1(9);
    s2(7) <= s1(10);

    -- Carry-save reduction: 8 operands to 6.
    gen_stage3 : for i in 0 to 1 generate
        s3(2*i)   <= csa_sum(s2(3*i), s2(3*i+1), s2(3*i+2));
        s3(2*i+1) <= csa_carry(s2(3*i), s2(3*i+1), s2(3*i+2));
    end generate;
    s3(4) <= s2(6);
    s3(5) <= s2(7);

    -- Carry-save reduction: 6 operands to 4.
    gen_stage4 : for i in 0 to 1 generate
        s4(2*i)   <= csa_sum(s3(3*i), s3(3*i+1), s3(3*i+2));
        s4(2*i+1) <= csa_carry(s3(3*i), s3(3*i+1), s3(3*i+2));
    end generate;

    -- Carry-save reduction: 4 operands to 3.
    s5(0) <= csa_sum(s4(0), s4(1), s4(2));
    s5(1) <= csa_carry(s4(0), s4(1), s4(2));
    s5(2) <= s4(3);

    -- Carry-save reduction: 3 operands to 2.
    s6(0) <= csa_sum(s5(0), s5(1), s5(2));
    s6(1) <= csa_carry(s5(0), s5(1), s5(2));

    -- Single final carry-propagating addition.
    result <= std_logic_vector(s6(0) + s6(1));
end architecture rtl;
