library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity LIFObuffer is
    Port (
        dataIn : in STD_LOGIC_VECTOR(3 downto 0);
        RW     : in STD_LOGIC;
        EN     : in STD_LOGIC;
        Rst    : in STD_LOGIC;
        Clk    : in STD_LOGIC;
        EMPTY  : out STD_LOGIC;
        FULL   : out STD_LOGIC;
        dataOut: out STD_LOGIC_VECTOR(3 downto 0)
    );
end LIFObuffer;

architecture RTL of LIFObuffer is
    constant WIDTH : integer := 4;
    constant DEPTH : integer := 4;

    type stack_mem_type is array (0 to DEPTH-1) of STD_LOGIC_VECTOR(WIDTH-1 downto 0);
    signal stack_mem : stack_mem_type;
    signal SP        : integer range 0 to DEPTH;
    signal dataOut_reg : STD_LOGIC_VECTOR(WIDTH-1 downto 0);
begin
    EMPTY <= '1' when SP = DEPTH else '0';
    FULL  <= '1' when SP = 0 else '0';

    dataOut <= dataOut_reg;

    process(Clk)
    begin
        if rising_edge(Clk) then
            if EN = '1' then
                if Rst = '1' then
                    SP <= DEPTH;
                    dataOut_reg <= (others => '0');
                    for i in 0 to DEPTH-1 loop
                        stack_mem(i) <= (others => '0');
                    end loop;
                else
                    if RW = '0' then
                        if SP /= 0 then
                            stack_mem(SP-1) <= dataIn;
                            SP <= SP - 1;
                        end if;
                    else
                        if SP /= DEPTH then
                            dataOut_reg <= stack_mem(SP);
                            stack_mem(SP) <= (others => '0');
                            SP <= SP + 1;
                        end if;
                    end if;
                end if;
            end if;
        end if;
    end process;
end RTL;
