library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity fixed_point_subtractor is
    generic (
        Q : integer := 8;
        N : integer := 16
    );
    port (
        a : in std_logic_vector(N-1 downto 0);
        b : in std_logic_vector(N-1 downto 0);
        c : out std_logic_vector(N-1 downto 0)
    );
end fixed_point_subtractor;

architecture Behavioral of fixed_point_subtractor is
    signal res : std_logic_vector(N-1 downto 0);
begin
    process(a, b)
        variable a_val, b_val : signed(N-1 downto 0);
        variable diff : signed(N downto 0);
        variable abs_diff : unsigned(N downto 0);
        variable c_sign : std_logic;
        variable c_mag : unsigned(N-2 downto 0);
    begin
        -- Convert a from sign-magnitude to signed
        if a(N-1) = '1' then
            a_val := -signed(resize(unsigned(a(N-2 downto 0)), N));
        else
            a_val := signed(resize(unsigned(a(N-2 downto 0)), N));
        end if;

        -- Convert b from sign-magnitude to signed
        if b(N-1) = '1' then
            b_val := -signed(resize(unsigned(b(N-2 downto 0)), N));
        else
            b_val := signed(resize(unsigned(b(N-2 downto 0)), N));
        end if;

        -- Perform subtraction
        diff := resize(a_val, N+1) - resize(b_val, N+1);

        -- Convert result back to sign-magnitude
        if diff = 0 then
            c_sign := '0';
            c_mag := (others => '0');
        elsif diff < 0 then
            c_sign := '1';
            abs_diff := unsigned(std_logic_vector(-diff));
            c_mag := abs_diff(N-2 downto 0);
        else
            c_sign := '0';
            abs_diff := unsigned(std_logic_vector(diff));
            c_mag := abs_diff(N-2 downto 0);
        end if;

        -- Handle zero: ensure sign bit is 0 when magnitude is zero
        if c_mag = 0 then
            c_sign := '0';
        end if;

        -- Assign to internal register res
        res(N-1) <= c_sign;
        res(N-2 downto 0) <= std_logic_vector(c_mag);
    end process;

    c <= res;

end Behavioral;
