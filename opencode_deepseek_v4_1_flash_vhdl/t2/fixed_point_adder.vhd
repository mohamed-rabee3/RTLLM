library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity fixed_point_adder is
    generic (
        Q : integer := 8;
        N : integer := 16
    );
    port (
        a : in  std_logic_vector(N-1 downto 0);
        b : in  std_logic_vector(N-1 downto 0);
        c : out std_logic_vector(N-1 downto 0)
    );
end fixed_point_adder;

architecture Behavioral of fixed_point_adder is
    signal res : std_logic_vector(N-1 downto 0);
begin
    process(a, b)
        variable a_mag : unsigned(N-2 downto 0);
        variable b_mag : unsigned(N-2 downto 0);
        variable sum_ext : unsigned(N-1 downto 0);
        variable diff : unsigned(N-2 downto 0);
        variable sum_mag : unsigned(N-2 downto 0);
        variable sign : std_logic;
    begin
        a_mag := unsigned(a(N-2 downto 0));
        b_mag := unsigned(b(N-2 downto 0));
        
        if a(N-1) = b(N-1) then
            -- Same sign: add magnitudes
            sum_ext := ('0' & a_mag) + ('0' & b_mag);
            if sum_ext(N-1) = '1' then
                -- Overflow: saturate to maximum magnitude
                sum_mag := (others => '1');
            else
                sum_mag := sum_ext(N-2 downto 0);
            end if;
            sign := a(N-1);
        else
            -- Different signs: subtract smaller magnitude from larger
            if a_mag >= b_mag then
                diff := a_mag - b_mag;
                sign := a(N-1);
            else
                diff := b_mag - a_mag;
                sign := b(N-1);
            end if;
            if diff = 0 then
                sign := '0';
            end if;
            sum_mag := diff;
        end if;
        
        res <= sign & std_logic_vector(sum_mag);
    end process;
    
    c <= res;
end Behavioral;
