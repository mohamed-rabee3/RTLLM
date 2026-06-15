library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity fixed_point_subtractor is
    generic (
        Q : integer;  -- Number of fractional bits
        N : integer   -- Total number of bits (integer + fractional)
    );
    port (
        a : in  std_logic_vector(N-1 downto 0);
        b : in  std_logic_vector(N-1 downto 0);
        c : out std_logic_vector(N-1 downto 0)
    );
end entity fixed_point_subtractor;

architecture behavioral of fixed_point_subtractor is
    -- Internal register to hold the subtraction result
    signal res : std_logic_vector(N-1 downto 0);
begin
    -- Perform fixed-point subtraction using two's complement arithmetic.
    -- This automatically handles same-sign and different-sign cases,
    -- and zero is represented with MSB = '0'.
    res <= std_logic_vector(signed(a) - signed(b));
    
    -- Drive the output
    c <= res;
end architecture behavioral;