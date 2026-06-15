library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity LIFObuffer is
    Port (
        dataIn  : in  STD_LOGIC_VECTOR (3 downto 0);
        RW      : in  STD_LOGIC;
        EN      : in  STD_LOGIC;
        Rst     : in  STD_LOGIC;
        Clk     : in  STD_LOGIC;
        EMPTY   : out STD_LOGIC;
        FULL    : out STD_LOGIC;
        dataOut : out STD_LOGIC_VECTOR (3 downto 0)
    );
end LIFObuffer;

architecture Behavioral of LIFObuffer is

    -- Stack memory: 4 locations of 4-bit each
    type mem_type is array (0 to 3) of STD_LOGIC_VECTOR(3 downto 0);
    signal stack_mem : mem_type := (others => (others => '0'));

    -- Stack pointer: 0 means full, 4 means empty
    signal SP : integer range 0 to 4 := 4;

    -- Internal register for dataOut
    signal dataOut_reg : STD_LOGIC_VECTOR(3 downto 0) := (others => '0');

begin

    -- Output flags derived from SP (combinational)
    EMPTY <= '1' when SP = 4 else '0';
    FULL  <= '1' when SP = 0 else '0';
    dataOut <= dataOut_reg;

    -- Synchronous process with enable
    process(Clk)
    begin
        if rising_edge(Clk) then
            if EN = '1' then
                if Rst = '1' then
                    -- Reset: clear stack, pointer to 4 (empty), zero dataOut
                    SP <= 4;
                    for i in 0 to 3 loop
                        stack_mem(i) <= (others => '0');
                    end loop;
                    dataOut_reg <= (others => '0');
                else
                    if RW = '0' then
                        -- Write (push) operation
                        if SP /= 0 then   -- not full
                            stack_mem(SP-1) <= dataIn;
                            SP <= SP - 1;
                        end if;
                    else
                        -- Read (pop) operation
                        if SP /= 4 then   -- not empty
                            dataOut_reg <= stack_mem(SP);
                            stack_mem(SP) <= (others => '0');  -- clear popped location
                            SP <= SP + 1;
                        end if;
                    end if;
                end if;
            end if;
        end if;
    end process;

end Behavioral;