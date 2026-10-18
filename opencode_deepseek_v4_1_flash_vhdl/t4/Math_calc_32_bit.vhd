library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity alu_32bit_unsigned is
    port (
        clk          : in  std_logic;
        rst          : in  std_logic;
        valid_in     : in  std_logic;
        a            : in  std_logic_vector(31 downto 0);
        b            : in  std_logic_vector(31 downto 0);
        op           : in  std_logic_vector(1 downto 0);
        result       : out std_logic_vector(63 downto 0);
        result_valid : out std_logic
    );
end entity alu_32bit_unsigned;

architecture rtl of alu_32bit_unsigned is
    signal a_u        : unsigned(31 downto 0);
    signal b_u        : unsigned(31 downto 0);
    signal result_reg : unsigned(63 downto 0);
    signal valid_reg  : std_logic;
begin
    a_u <= unsigned(a);
    b_u <= unsigned(b);

    process(clk)
        variable res_v : unsigned(63 downto 0);
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
                            res_v := resize(a_u, 64) + resize(b_u, 64);

                        when "01" =>
                            res_v := a_u * b_u;

                        when "10" =>
                            if a_u < b_u then
                                res_v := resize(a_u, 64);
                            else
                                res_v := resize(b_u, 64);
                            end if;

                        when others =>
                            res_v := (others => '1');
                    end case;

                    result_reg <= res_v;
                    valid_reg  <= '1';
                end if;
            end if;
        end if;
    end process;

    result       <= std_logic_vector(result_reg);
    result_valid <= valid_reg;
end architecture rtl;
