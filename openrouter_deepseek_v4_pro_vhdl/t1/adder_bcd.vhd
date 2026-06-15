library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity adder_bcd is
    port (
        A   : in  std_logic_vector(3 downto 0);  -- First BCD input (0-9)
        B   : in  std_logic_vector(3 downto 0);  -- Second BCD input (0-9)
        Cin : in  std_logic;                     -- Carry-in input
        Sum : out std_logic_vector(3 downto 0);  -- BCD sum output (0-9)
        Cout: out std_logic                      -- Carry-out output
    );
end entity adder_bcd;

architecture rtl of adder_bcd is
    signal temp      : unsigned(4 downto 0);
    signal corrected : unsigned(4 downto 0);
begin
    -- 1) Binary addition of A, B, and Cin (extended to 5 bits)
    temp <= resize(unsigned(A), 5) + 
            resize(unsigned(B), 5) + 
            ('0' & Cin);

    -- 2) BCD correction: add 6 if result > 9
    corrected <= temp + to_unsigned(6, 5) when (temp > 9) else temp;

    -- 3) Drive outputs from the corrected 5-bit sum
    Sum  <= std_logic_vector(corrected(3 downto 0));
    Cout <= corrected(4);

end architecture rtl;