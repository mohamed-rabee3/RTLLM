library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pe is
    port (
        clk : in  std_logic;
        rst : in  std_logic;
        a   : in  std_logic_vector(31 downto 0);
        b   : in  std_logic_vector(31 downto 0);
        c   : out std_logic_vector(31 downto 0)
    );
end entity pe;

architecture rtl of pe is
    -- Internal accumulator register
    signal acc      : signed(31 downto 0);
    -- Type‑converted inputs
    signal a_signed : signed(31 downto 0);
    signal b_signed : signed(31 downto 0);
    -- Full 64‑bit product
    signal product  : signed(63 downto 0);
begin
    -- Continuous assignments
    a_signed <= signed(a);
    b_signed <= signed(b);
    product  <= a_signed * b_signed;

    -- Process for accumulation with asynchronous reset
    process(clk, rst)
    begin
        if rst = '1' then
            acc <= (others => '0');
        elsif rising_edge(clk) then
            -- Accumulate the low 32 bits of the product (modulo‑2^32 wrap‑around)
            acc <= acc + signed(product(31 downto 0));
        end if;
    end process;

    -- Drive output
    c <= std_logic_vector(acc);
end architecture rtl;