library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity fixed_point_subtractor is
    generic (
        Q : integer := 8;
        N : integer := 16
    );
    port (
        a : in  std_logic_vector(N-1 downto 0);
        b : in  std_logic_vector(N-1 downto 0);
        c : out std_logic_vector(N-1 downto 0)
    );
end fixed_point_subtractor;

architecture Behavioral of fixed_point_subtractor is
    signal res : std_logic_vector(N-1 downto 0);
begin

    process(a, b)
        variable a_s   : signed(N-1 downto 0);
        variable b_s   : signed(N-1 downto 0);
        variable diff  : signed(N downto 0);
    begin
        a_s  := signed(a);
        b_s  := signed(b);
        diff := resize(a_s, N+1) - resize(b_s, N+1);

        if diff(N) /= diff(N-1) then
            -- Overflow: saturate
            if diff(N) = '0' then
                -- Positive overflow, saturate to max positive
                res <= std_logic_vector(to_signed(2**(N-1) - 1, N));
            else
                -- Negative overflow, saturate to min negative
                res <= std_logic_vector(to_signed(-(2**(N-1)), N));
            end if;
        else
            res <= std_logic_vector(diff(N-1 downto 0));
        end if;
    end process;

    c <= res;

end Behavioral;
