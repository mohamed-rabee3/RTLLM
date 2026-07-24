library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity verified_alu_32bit_unsigned is
    port(clk          : in  std_logic;
         rst          : in  std_logic;
         valid_in     : in  std_logic;
         a            : in  std_logic_vector(31 downto 0);
         b            : in  std_logic_vector(31 downto 0);
         op           : in  std_logic_vector(1 downto 0);
         result       : out std_logic_vector(63 downto 0);
         result_valid : out std_logic);
end verified_alu_32bit_unsigned;
architecture rtl of verified_alu_32bit_unsigned is
    signal rv : std_logic := '0';
begin
    result_valid <= rv;
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                result <= (others => '0');
                rv     <= '0';
            elsif valid_in = '1' and rv = '0' then
                -- accept one operation, pulse result_valid for a single cycle
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
                rv <= '1';
            else
                rv <= '0';
            end if;
        end if;
    end process;
end rtl;
