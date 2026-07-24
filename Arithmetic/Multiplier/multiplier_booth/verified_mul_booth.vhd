library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity verified_mul_booth is
    port(a, b : in std_logic_vector(15 downto 0);
         result : out std_logic_vector(31 downto 0));
end verified_mul_booth;
architecture rtl of verified_mul_booth is
begin
    process(a, b)
        variable mc   : signed(39 downto 0);
        variable acc  : signed(39 downto 0);
        variable pp   : signed(39 downto 0);
        variable mb   : std_logic_vector(18 downto 0);
        variable code : std_logic_vector(2 downto 0);
    begin
        mc  := signed(resize(unsigned(a), 40));      -- zero-extended positive multiplicand
        mb  := "00" & b & "0";                       -- mb(0)=0, mb(j+1)=b(j)
        acc := (others => '0');
        for i in 0 to 8 loop
            code := mb(2*i+2 downto 2*i);
            case code is
                when "001" | "010" => pp := mc;
                when "011"         => pp := shift_left(mc, 1);
                when "100"         => pp := -shift_left(mc, 1);
                when "101" | "110" => pp := -mc;
                when others        => pp := (others => '0');
            end case;
            acc := acc + shift_left(pp, 2*i);
        end loop;
        result <= std_logic_vector(acc(31 downto 0));
    end process;
end rtl;
