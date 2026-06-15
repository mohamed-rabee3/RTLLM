library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- 4-bit comparator using subtractive combinational logic
-- The comparison is performed by computing A - B with a carry/borrow chain.
-- The outputs are mutually exclusive: exactly one of A_greater, A_equal, A_less is high at any time.

entity comparator_4bit is
    Port (
        A         : in  STD_LOGIC_VECTOR (3 downto 0);  -- First 4-bit operand
        B         : in  STD_LOGIC_VECTOR (3 downto 0);  -- Second 4-bit operand
        A_greater : out STD_LOGIC;                      -- High when A > B
        A_equal   : out STD_LOGIC;                      -- High when A = B
        A_less    : out STD_LOGIC                       -- High when A < B
    );
end comparator_4bit;

architecture rtl of comparator_4bit is
    -- Internal signals for bitwise subtraction (A - B) using A + (not B) + 1
    signal B_inv : STD_LOGIC_VECTOR (3 downto 0);   -- Inverted B bits
    signal sum   : STD_LOGIC_VECTOR (3 downto 0);   -- Result of subtraction
    signal c     : STD_LOGIC_VECTOR (4 downto 0);   -- Carry chain, c(0) = '1' (the +1)
    signal zero  : STD_LOGIC;                       -- High when sum == "0000"
begin

    -- Generate the subtractor bit by bit using a ripple-carry adder structure
    c(0) <= '1';   -- Add 1 for two's complement subtraction (A - B = A + (~B) + 1)

    gen_full_adders: for i in 0 to 3 generate
        B_inv(i) <= not B(i);
        sum(i)   <= A(i) xor B_inv(i) xor c(i);
        c(i+1)   <= (A(i) and B_inv(i)) or (c(i) and (A(i) xor B_inv(i)));
    end generate;

    -- Detect zero result (A == B)
    zero <= '1' when sum = "0000" else '0';

    -- Determine comparison outputs based on carry (borrow) and zero
    -- If the final carry out is '0', a borrow occurred → A < B.
    -- If the carry is '1' and the result is non-zero → A > B.
    -- If the result is zero (no borrow, carry = 1) → A = B.
    A_greater <= c(4) and (not zero);
    A_equal   <= zero;
    A_less    <= not c(4);

end rtl;