library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity LIFObuffer is
    Port (
        dataIn : in  STD_LOGIC_VECTOR (3 downto 0);
        RW     : in  STD_LOGIC;
        EN     : in  STD_LOGIC;
        Rst    : in  STD_LOGIC;
        Clk    : in  STD_LOGIC;
        EMPTY  : out STD_LOGIC;
        FULL   : out STD_LOGIC;
        dataOut: out STD_LOGIC_VECTOR (3 downto 0)
    );
end LIFObuffer;

architecture RTL of LIFObuffer is
    type stack_array is array (0 to 3) of STD_LOGIC_VECTOR(3 downto 0);
    signal stack_mem : stack_array;
    signal SP : integer range 0 to 4;
    signal dataOut_reg : STD_LOGIC_VECTOR(3 downto 0);
begin

    process(Clk)
    begin
        if rising_edge(Clk) then
            if Rst = '1' then
                SP <= 4;
                for i in 0 to 3 loop
                    stack_mem(i) <= (others => '0');
                end loop;
                dataOut_reg <= (others => '0');
            elsif EN = '1' then
                if RW = '0' then  -- write/push
                    if SP /= 0 then
                        stack_mem(SP - 1) <= dataIn;
                        SP <= SP - 1;
                    end if;
                else              -- read/pop
                    if SP /= 4 then
                        dataOut_reg <= stack_mem(SP);
                        stack_mem(SP) <= (others => '0');
                        SP <= SP + 1;
                    end if;
                end if;
            end if;
        end if;
    end process;

    dataOut <= dataOut_reg;
    EMPTY <= '1' when SP = 4 else '0';
    FULL <= '1' when SP = 0 else '0';

end RTL;
