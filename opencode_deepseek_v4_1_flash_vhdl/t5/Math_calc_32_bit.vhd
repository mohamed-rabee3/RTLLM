library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity alu_32bit_unsigned is
    Port (
        clk          : in  std_logic;
        rst          : in  std_logic;
        valid_in     : in  std_logic;
        a            : in  std_logic_vector(31 downto 0);
        b            : in  std_logic_vector(31 downto 0);
        op           : in  std_logic_vector(1 downto 0);
        result       : out std_logic_vector(63 downto 0);
        result_valid : out std_logic
    );
end alu_32bit_unsigned;

architecture rtl of alu_32bit_unsigned is
    signal result_reg : std_logic_vector(63 downto 0) := (others => '0');
    signal valid_reg  : std_logic := '0';
begin

    process(clk)
        variable sum33   : unsigned(32 downto 0);
        variable prod64  : unsigned(63 downto 0);
        variable min_val : unsigned(31 downto 0);
    begin
        if rising_edge(clk) then
            if rst = '1' then
                result_reg <= (others => '0');
                valid_reg  <= '0';
            else
                valid_reg <= '0';

                if valid_in = '1' then
                    case op is
                        when "00" =>
                            sum33 := resize(unsigned(a), 33) + resize(unsigned(b), 33);
                            result_reg <= std_logic_vector(resize(sum33, 64));

                        when "01" =>
                            prod64 := unsigned(a) * unsigned(b);
                            result_reg <= std_logic_vector(prod64);

                        when "10" =>
                            if unsigned(a) < unsigned(b) then
                                min_val := unsigned(a);
                            else
                                min_val := unsigned(b);
                            end if;
                            result_reg <= std_logic_vector(resize(min_val, 64));

                        when others =>
                            result_reg <= (others => '1');
                    end case;

                    valid_reg <= '1';
                end if;
            end if;
        end if;
    end process;

    result       <= result_reg;
    result_valid <= valid_reg;

end rtl;
