library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity alu_32bit_unsigned is
    Port (
        clk          : in  STD_LOGIC;
        rst          : in  STD_LOGIC;
        valid_in     : in  STD_LOGIC;
        a            : in  STD_LOGIC_VECTOR (31 downto 0);
        b            : in  STD_LOGIC_VECTOR (31 downto 0);
        op           : in  STD_LOGIC_VECTOR (1 downto 0);
        result       : out STD_LOGIC_VECTOR (63 downto 0);
        result_valid : out STD_LOGIC
    );
end alu_32bit_unsigned;

architecture rtl of alu_32bit_unsigned is
begin

    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                result       <= (others => '0');
                result_valid <= '0';
            else
                result_valid <= '0';

                if valid_in = '1' then
                    case op is
                        when "00" =>
                            result <= std_logic_vector(resize(unsigned(a), 64) + resize(unsigned(b), 64));

                        when "01" =>
                            result <= std_logic_vector(unsigned(a) * unsigned(b));

                        when "10" =>
                            if unsigned(a) < unsigned(b) then
                                result <= std_logic_vector(resize(unsigned(a), 64));
                            else
                                result <= std_logic_vector(resize(unsigned(b), 64));
                            end if;

                        when others =>
                            result <= (others => '1');
                    end case;

                    result_valid <= '1';
                end if;
            end if;
        end if;
    end process;

end rtl;
