library ieee;
use ieee.std_logic_1164.all;

entity LIFObuffer is
    port (
        dataIn  : in  std_logic_vector(3 downto 0);
        RW      : in  std_logic;
        EN      : in  std_logic;
        Rst     : in  std_logic;
        Clk     : in  std_logic;
        EMPTY   : out std_logic;
        FULL    : out std_logic;
        dataOut : out std_logic_vector(3 downto 0)
    );
end entity LIFObuffer;

architecture rtl of LIFObuffer is
    type stack_mem_type is array (0 to 3) of std_logic_vector(3 downto 0);
    signal stack_mem : stack_mem_type := (others => (others => '0'));
    signal SP       : integer range 0 to 4 := 4;
    signal out_reg  : std_logic_vector(3 downto 0) := (others => '0');
begin
    EMPTY   <= '1' when SP = 4 else '0';
    FULL    <= '1' when SP = 0 else '0';
    dataOut <= out_reg;

    process (Clk)
    begin
        if rising_edge(Clk) then
            if EN = '1' then
                if Rst = '1' then
                    stack_mem <= (others => (others => '0'));
                    SP        <= 4;
                    out_reg   <= (others => '0');
                else
                    if RW = '0' then
                        if SP > 0 then
                            stack_mem(SP - 1) <= dataIn;
                            SP                <= SP - 1;
                        end if;
                    elsif RW = '1' then
                        if SP < 4 then
                            out_reg       <= stack_mem(SP);
                            stack_mem(SP) <= (others => '0');
                            SP            <= SP + 1;
                        end if;
                    end if;
                end if;
            end if;
        end if;
    end process;
end architecture rtl;
