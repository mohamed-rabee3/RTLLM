library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity mul_booth is
    Port (
        a : in STD_LOGIC_VECTOR (15 downto 0);
        b : in STD_LOGIC_VECTOR (15 downto 0);
        result : out STD_LOGIC_VECTOR (31 downto 0)
    );
end mul_booth;

architecture Behavioral of mul_booth is
    constant ACC_W : integer := 40;
begin
    process(a, b)
        variable b_ext : std_logic_vector(17 downto 0);
        variable a_sig : signed(ACC_W-1 downto 0);
        variable acc : signed(ACC_W-1 downto 0);
        variable pp : signed(ACC_W-1 downto 0);
        variable code : std_logic_vector(2 downto 0);
    begin
        b_ext := (others => '0');
        b_ext(15 downto 0) := b;

        a_sig := resize(signed('0' & a), ACC_W);
        acc := (others => '0');

        for i in 0 to 8 loop
            if i = 0 then
                code(0) := '0';
            else
                code(0) := b_ext(2*i - 1);
            end if;
            code(1) := b_ext(2*i);
            code(2) := b_ext(2*i + 1);

            case code is
                when "001" | "010" =>
                    pp := a_sig;
                when "011" =>
                    pp := shift_left(a_sig, 1);
                when "100" =>
                    pp := -shift_left(a_sig, 1);
                when "101" | "110" =>
                    pp := -a_sig;
                when others =>
                    pp := (others => '0');
            end case;

            acc := acc + shift_left(pp, 2*i);
        end loop;

        result <= std_logic_vector(acc(31 downto 0));
    end process;
end Behavioral;
