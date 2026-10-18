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
    type word_array_t is array (0 to 15) of word_t;
    type tree_array_t is array (0 to 6) of word_array_t;
    type count_array_t is array (0 to 6) of natural;

    constant COUNTS : count_array_t := (16, 11, 8, 6, 4, 3, 2);

    signal tree : tree_array_t;
begin
    -- Generate the sixteen aligned partial products.
    gen_partial_products : for i in 0 to 15 generate
        tree(0)(i) <= shift_left(resize(unsigned(a), 32), i)
                      when b(i) = '1' else (others => '0');
    end generate gen_partial_products;

    -- Reduce each group of three operands to two without propagating
    -- carries across bit positions.
    gen_levels : for level in 0 to 5 generate
        constant GROUPS    : natural := COUNTS(level) / 3;
        constant REMAINDER : natural := COUNTS(level) mod 3;
    begin
        gen_compressors : for g in 0 to GROUPS - 1 generate
            tree(level + 1)(2 * g) <=
                tree(level)(3 * g) xor
                tree(level)(3 * g + 1) xor
                tree(level)(3 * g + 2);

            tree(level + 1)(2 * g + 1) <= shift_left(
                (tree(level)(3 * g) and tree(level)(3 * g + 1)) or
                (tree(level)(3 * g) and tree(level)(3 * g + 2)) or
                (tree(level)(3 * g + 1) and tree(level)(3 * g + 2)),
                1
            );
        end generate gen_compressors;

        -- Forward any operands not included in a group of three.
        gen_remainder : for r in 0 to REMAINDER - 1 generate
            tree(level + 1)(2 * GROUPS + r) <=
                tree(level)(3 * GROUPS + r);
        end generate gen_remainder;

        -- Unused entries do not participate in the reduction.
        gen_unused : for u in COUNTS(level + 1) to 15 generate
            tree(level + 1)(u) <= (others => '0');
        end generate gen_unused;
    end generate gen_levels;

    -- Only the final addition requires carry propagation.
    result <= std_logic_vector(tree(6)(0) + tree(6)(1));
end architecture rtl;
