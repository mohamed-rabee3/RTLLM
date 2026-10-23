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

    function carry3(x, y, z : word_t) return word_t is
    begin
        return shift_left((x and y) or (x and z) or (y and z), 1);
    end function carry3;
begin
    -- Generate sixteen shifted partial products.
    gen_pp : for i in 0 to 15 generate
        signal masked_a : unsigned(15 downto 0);
    begin
        gen_bits : for j in 0 to 15 generate
            masked_a(j) <= a(j) and b(i);
        end generate gen_bits;

        pp(i) <= shift_left(resize(masked_a, 32), i);
    end generate gen_pp;

    -- Carry-save reduction: 16 operands to 11 operands.
    gen_s1 : for i in 0 to 4 generate
        s1(2*i)   <= pp(3*i) xor pp(3*i+1) xor pp(3*i+2);
        s1(2*i+1) <= carry3(pp(3*i), pp(3*i+1), pp(3*i+2));
    end generate gen_s1;
    s1(10) <= pp(15);

    -- 11 operands to 8 operands.
    gen_s2 : for i in 0 to 2 generate
        s2(2*i)   <= s1(3*i) xor s1(3*i+1) xor s1(3*i+2);
        s2(2*i+1) <= carry3(s1(3*i), s1(3*i+1), s1(3*i+2));
    end generate gen_s2;
    s2(6) <= s1(9);
    s2(7) <= s1(10);

    -- 8 operands to 6 operands.
    gen_s3 : for i in 0 to 1 generate
        s3(2*i)   <= s2(3*i) xor s2(3*i+1) xor s2(3*i+2);
        s3(2*i+1) <= carry3(s2(3*i), s2(3*i+1), s2(3*i+2));
    end generate gen_s3;
    s3(4) <= s2(6);
    s3(5) <= s2(7);

    -- 6 operands to 4 operands.
    gen_s4 : for i in 0 to 1 generate
        s4(2*i)   <= s3(3*i) xor s3(3*i+1) xor s3(3*i+2);
        s4(2*i+1) <= carry3(s3(3*i), s3(3*i+1), s3(3*i+2));
    end generate gen_s4;

    -- 4 operands to 3 operands.
    s5(0) <= s4(0) xor s4(1) xor s4(2);
    s5(1) <= carry3(s4(0), s4(1), s4(2));
    s5(2) <= s4(3);

    -- 3 operands to 2 operands.
    s6(0) <= s5(0) xor s5(1) xor s5(2);
    s6(1) <= carry3(s5(0), s5(1), s5(2));

    -- Single final carry-propagating addition.
    result <= std_logic_vector(s6(0) + s6(1));
end architecture rtl;
