library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity verified_fir_interpolator is
    port(clk       : in  std_logic;
         rst       : in  std_logic;
         valid_in  : in  std_logic;
         data_in   : in  std_logic_vector(15 downto 0);
         valid_out : out std_logic;
         data_out  : out std_logic_vector(15 downto 0));
end verified_fir_interpolator;
architecture rtl of verified_fir_interpolator is
    constant L : integer := 8;
    signal prev, cur : signed(15 downto 0) := (others => '0');
    signal k         : integer range 0 to 8 := 0;
    signal busy, first : std_logic := '0';
begin
    process(clk)
        variable diff : signed(31 downto 0);
    begin
        if rising_edge(clk) then
            if rst = '1' then
                valid_out <= '0';
                first     <= '1';
                busy      <= '0';
                k         <= 0;
                prev      <= (others => '0');
                cur       <= (others => '0');
                data_out  <= (others => '0');
            else
                valid_out <= '0';
                if valid_in = '1' then
                    if first = '1' then
                        data_out  <= data_in;
                        valid_out <= '1';
                        prev      <= signed(data_in);
                        first     <= '0';
                    else
                        cur  <= signed(data_in);
                        busy <= '1';
                        k    <= 1;
                    end if;
                elsif busy = '1' then
                    diff := (cur - prev) * to_signed(k, 16);
                    data_out  <= std_logic_vector(resize(prev, 16) + resize(diff / L, 16));
                    valid_out <= '1';
                    if k = L then
                        busy <= '0';
                        prev <= cur;
                    else
                        k <= k + 1;
                    end if;
                end if;
            end if;
        end if;
    end process;
end rtl;
