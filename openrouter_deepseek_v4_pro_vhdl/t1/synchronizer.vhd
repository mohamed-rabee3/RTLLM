library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;  -- only used for completeness, not strictly required

entity synchronizer is
    port (
        clk_a   : in  std_logic;                      -- Clock A
        clk_b   : in  std_logic;                      -- Clock B
        arstn   : in  std_logic;                      -- Active-low reset for clock A domain
        brstn   : in  std_logic;                      -- Active-low reset for clock B domain
        data_in : in  std_logic_vector(3 downto 0);   -- Input data (4 bits)
        data_en : in  std_logic;                      -- Input enable signal
        dataout : out std_logic_vector(3 downto 0)    -- Output data (4 bits)
    );
end entity synchronizer;

architecture rtl of synchronizer is

    -- Registers in clock A domain
    signal data_reg   : std_logic_vector(3 downto 0);
    signal en_data_reg: std_logic;

    -- Synchronization registers in clock B domain
    signal en_clap_one : std_logic;
    signal en_clap_two : std_logic;

begin

    ----------------------------------------------------------------------------
    -- DATA_REG and ENABLE_REG in clock domain A (clk_a)
    ----------------------------------------------------------------------------
    -- data_reg stores data_in when data_en is active.
    -- Both registers have asynchronous active-low reset (arstn).
    process(clk_a, arstn)
    begin
        if arstn = '0' then
            data_reg    <= (others => '0');
            en_data_reg <= '0';
        elsif rising_edge(clk_a) then
            data_reg    <= data_in;      -- capture data_in directly
            en_data_reg <= data_en;      -- capture the enable signal
        end if;
    end process;

    ----------------------------------------------------------------------------
    -- Two-stage synchronizer for the enable signal in clock domain B (clk_b)
    ----------------------------------------------------------------------------
    process(clk_b, brstn)
    begin
        if brstn = '0' then
            en_clap_one <= '0';
            en_clap_two <= '0';
        elsif rising_edge(clk_b) then
            en_clap_one <= en_data_reg;   -- first flip-flop (samples from clk_a domain)
            en_clap_two <= en_clap_one;   -- second flip-flop (delayed by one clk_b cycle)
        end if;
    end process;

    ----------------------------------------------------------------------------
    -- Output data register in clock domain B (clk_b)
    -- Loads data_reg when the twice-synchronized enable (en_clap_two) is active.
    ----------------------------------------------------------------------------
    process(clk_b, brstn)
    begin
        if brstn = '0' then
            dataout <= (others => '0');
        elsif rising_edge(clk_b) then
            if en_clap_two = '1' then
                dataout <= data_reg;   -- safe to sample because data_reg is stable
            else
                dataout <= dataout;    -- retain previous value
            end if;
        end if;
    end process;

end architecture rtl;