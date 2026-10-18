library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity mul_fast is
    Port (
        a : in STD_LOGIC_VECTOR (15 downto 0);
        b : in STD_LOGIC_VECTOR (15 downto 0);
        result : out STD_LOGIC_VECTOR (31 downto 0)
    );
end mul_fast;

architecture rtl of mul_fast is
    type pp_array_t is array (0 to 15) of unsigned(31 downto 0);
    type s8_array_t is array (0 to 7) of unsigned(31 downto 0);
    type s4_array_t is array (0 to 3) of unsigned(31 downto 0);
    type s2_array_t is array (0 to 1) of unsigned(31 downto 0);
begin
    process(a, b)
        variable pp : pp_array_t;
        variable s1 : s8_array_t;
        variable s2 : s4_array_t;
        variable s3 : s2_array_t;
        variable s4 : unsigned(31 downto 0);
        variable a_u : unsigned(15 downto 0);
    begin
        a_u := unsigned(a);

        -- Generate 16 partial products
        for i in 0 to 15 loop
            pp(i) := (others => '0');
            if b(i) = '1' then
                for j in 0 to 15 loop
                    pp(i)(j + i) := a_u(j);
                end loop;
            end if;
        end loop;

        -- Balanced adder tree: stage 1 (16 -> 8)
        for i in 0 to 7 loop
            s1(i) := pp(2*i) + pp(2*i+1);
        end loop;

        -- Stage 2 (8 -> 4)
        for i in 0 to 3 loop
            s2(i) := s1(2*i) + s1(2*i+1);
        end loop;

        -- Stage 3 (4 -> 2)
        for i in 0 to 1 loop
            s3(i) := s2(2*i) + s2(2*i+1);
        end loop;

        -- Stage 4 (2 -> 1)
        s4 := s3(0) + s3(1);

        result <= std_logic_vector(s4);
    end process;
end rtl;
