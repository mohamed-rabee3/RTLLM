library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity sorting_3_numbers is
    Port (
        a1  : in  STD_LOGIC_VECTOR(9 downto 0);
        a2  : in  STD_LOGIC_VECTOR(9 downto 0);
        a3  : in  STD_LOGIC_VECTOR(9 downto 0);
        max : out STD_LOGIC_VECTOR(9 downto 0);
        med : out STD_LOGIC_VECTOR(9 downto 0);
        min : out STD_LOGIC_VECTOR(9 downto 0)
    );
end sorting_3_numbers;

architecture rtl of sorting_3_numbers is
    signal s1  : unsigned(9 downto 0);
    signal s2  : unsigned(9 downto 0);
    signal s3  : unsigned(9 downto 0);

    signal t1  : unsigned(9 downto 0);
    signal t2  : unsigned(9 downto 0);
    signal t3  : unsigned(9 downto 0);
begin
    -- Stage 1: compare and swap a1 and a2
    process(a1, a2)
    begin
        if unsigned(a1) > unsigned(a2) then
            s1 <= unsigned(a1);
            s2 <= unsigned(a2);
        else
            s1 <= unsigned(a2);
            s2 <= unsigned(a1);
        end if;
    end process;

    s3 <= unsigned(a3);

    -- Stage 2: compare the larger side (s1) with s3
    process(s1, s2, s3)
    begin
        if s1 > s3 then
            t1 <= s1;
            t2 <= s3;
        else
            t1 <= s3;
            t2 <= s1;
        end if;
        t3 <= s2;
    end process;

    -- Stage 3: re-order the remaining pair (t2, t3)
    process(t1, t2, t3)
    begin
        if t2 > t3 then
            max <= std_logic_vector(t1);
            med <= std_logic_vector(t2);
            min <= std_logic_vector(t3);
        else
            max <= std_logic_vector(t1);
            med <= std_logic_vector(t3);
            min <= std_logic_vector(t2);
        end if;
    end process;
end rtl;
