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
    signal a_reg          : unsigned(31 downto 0) := (others => '0');
    signal b_reg          : unsigned(31 downto 0) := (others => '0');
    signal op_reg         : std_logic_vector(1 downto 0) := (others => '0');
    signal result_valid_r : std_logic := '0';
    signal result_comb    : std_logic_vector(63 downto 0);
begin

    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                a_reg          <= (others => '0');
                b_reg          <= (others => '0');
                op_reg         <= (others => '0');
                result_valid_r <= '0';
            else
                if valid_in = '1' then
                    a_reg  <= unsigned(a);
                    b_reg  <= unsigned(b);
                    op_reg <= op;
                end if;
                result_valid_r <= valid_in;
            end if;
        end if;
    end process;

    process(a_reg, b_reg, op_reg)
        variable sum : unsigned(32 downto 0);
    begin
        case op_reg is
            when "00" =>
                sum := ('0' & a_reg) + ('0' & b_reg);
                result_comb <= std_logic_vector(resize(sum, 64));
            when "01" =>
                result_comb <= std_logic_vector(resize(a_reg * b_reg, 64));
            when "10" =>
                if a_reg < b_reg then
                    result_comb <= std_logic_vector(resize(a_reg, 64));
                else
                    result_comb <= std_logic_vector(resize(b_reg, 64));
                end if;
            when others =>
                result_comb <= (others => '1');
        end case;
    end process;

    result       <= result_comb;
    result_valid <= result_valid_r;

end rtl;
