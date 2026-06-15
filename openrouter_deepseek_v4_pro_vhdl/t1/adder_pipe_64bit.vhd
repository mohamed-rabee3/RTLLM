library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity adder_pipe_64bit is
    port (
        clk    : in  std_logic;
        rst_n  : in  std_logic;
        i_en   : in  std_logic;
        adda   : in  std_logic_vector(63 downto 0);
        addb   : in  std_logic_vector(63 downto 0);
        result : out std_logic_vector(64 downto 0);
        o_en   : out std_logic
    );
end entity adder_pipe_64bit;

architecture rtl of adder_pipe_64bit is

    -- Pipeline stage registers for operands
    signal adda_stage1 : std_logic_vector(63 downto 0);
    signal addb_stage1 : std_logic_vector(63 downto 0);
    signal adda_stage2 : std_logic_vector(63 downto 0);
    signal addb_stage2 : std_logic_vector(63 downto 0);
    signal adda_stage3 : std_logic_vector(63 downto 0);
    signal addb_stage3 : std_logic_vector(63 downto 0);

    -- Pipeline stage registers for enable signals
    signal en_stage1   : std_logic;
    signal en_stage2   : std_logic;
    signal en_stage3   : std_logic;

    -- Carry signals for each 16-bit segment
    signal carry_in    : std_logic;
    signal carry_stage1 : std_logic;
    signal carry_stage2 : std_logic;
    signal carry_stage3 : std_logic;

    -- Partial sum results
    signal sum_stage1  : std_logic_vector(15 downto 0);
    signal sum_stage2  : std_logic_vector(15 downto 0);
    signal sum_stage3  : std_logic_vector(15 downto 0);
    signal sum_stage4  : std_logic_vector(15 downto 0);

    -- Registered partial sums
    signal sum_reg1    : std_logic_vector(15 downto 0);
    signal sum_reg2    : std_logic_vector(15 downto 0);
    signal sum_reg3    : std_logic_vector(15 downto 0);
    signal sum_reg4    : std_logic_vector(15 downto 0);

    -- Final result assembly
    signal result_int  : std_logic_vector(64 downto 0);

begin

    -- Initial carry-in is '0'
    carry_in <= '0';

    -- Stage 1: Add lower 16 bits [15:0]
    process(clk, rst_n)
        variable temp_sum : unsigned(16 downto 0);
    begin
        if rst_n = '0' then
            adda_stage1 <= (others => '0');
            addb_stage1 <= (others => '0');
            en_stage1   <= '0';
            carry_stage1 <= '0';
            sum_reg1    <= (others => '0');
        elsif rising_edge(clk) then
            en_stage1   <= i_en;
            adda_stage1 <= adda;
            addb_stage1 <= addb;
            
            if i_en = '1' then
                temp_sum := unsigned('0' & adda(15 downto 0)) + unsigned('0' & addb(15 downto 0)) + unsigned'('0' & carry_in);
                sum_reg1    <= std_logic_vector(temp_sum(15 downto 0));
                carry_stage1 <= temp_sum(16);
            else
                sum_reg1    <= (others => '0');
                carry_stage1 <= '0';
            end if;
        end if;
    end process;

    -- Stage 2: Add bits [31:16]
    process(clk, rst_n)
        variable temp_sum : unsigned(16 downto 0);
    begin
        if rst_n = '0' then
            adda_stage2 <= (others => '0');
            addb_stage2 <= (others => '0');
            en_stage2   <= '0';
            carry_stage2 <= '0';
            sum_reg2    <= (others => '0');
        elsif rising_edge(clk) then
            en_stage2   <= en_stage1;
            adda_stage2 <= adda_stage1;
            addb_stage2 <= addb_stage1;
            
            if en_stage1 = '1' then
                temp_sum := unsigned('0' & adda_stage1(31 downto 16)) + unsigned('0' & addb_stage1(31 downto 16)) + unsigned'('0' & carry_stage1);
                sum_reg2    <= std_logic_vector(temp_sum(15 downto 0));
                carry_stage2 <= temp_sum(16);
            else
                sum_reg2    <= (others => '0');
                carry_stage2 <= '0';
            end if;
        end if;
    end process;

    -- Stage 3: Add bits [47:32]
    process(clk, rst_n)
        variable temp_sum : unsigned(16 downto 0);
    begin
        if rst_n = '0' then
            adda_stage3 <= (others => '0');
            addb_stage3 <= (others => '0');
            en_stage3   <= '0';
            carry_stage3 <= '0';
            sum_reg3    <= (others => '0');
        elsif rising_edge(clk) then
            en_stage3   <= en_stage2;
            adda_stage3 <= adda_stage2;
            addb_stage3 <= addb_stage2;
            
            if en_stage2 = '1' then
                temp_sum := unsigned('0' & adda_stage2(47 downto 32)) + unsigned('0' & addb_stage2(47 downto 32)) + unsigned'('0' & carry_stage2);
                sum_reg3    <= std_logic_vector(temp_sum(15 downto 0));
                carry_stage3 <= temp_sum(16);
            else
                sum_reg3    <= (others => '0');
                carry_stage3 <= '0';
            end if;
        end if;
    end process;

    -- Stage 4: Add bits [63:48] and produce final result
    process(clk, rst_n)
        variable temp_sum : unsigned(16 downto 0);
    begin
        if rst_n = '0' then
            sum_reg4 <= (others => '0');
            result_int <= (others => '0');
            o_en <= '0';
        elsif rising_edge(clk) then
            o_en <= en_stage3;
            
            if en_stage3 = '1' then
                temp_sum := unsigned('0' & adda_stage3(63 downto 48)) + unsigned('0' & addb_stage3(63 downto 48)) + unsigned'('0' & carry_stage3);
                sum_reg4 <= std_logic_vector(temp_sum(15 downto 0));
                result_int <= std_logic_vector(temp_sum(16)) & sum_reg4 & sum_reg3 & sum_reg2 & sum_reg1;
            else
                sum_reg4 <= (others => '0');
                result_int <= (others => '0');
            end if;
        end if;
    end process;

    -- Drive output
    result <= result_int;

end architecture rtl;