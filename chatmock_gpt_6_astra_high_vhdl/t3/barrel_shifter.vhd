library ieee;
use ieee.std_logic_1164.all;

entity mux2X1 is
    port (
        a   : in  std_logic;
        b   : in  std_logic;
        sel : in  std_logic;
        y   : out std_logic
    );
end entity mux2X1;

architecture rtl of mux2X1 is
begin
    y <= a when sel = '0' else b;
end architecture rtl;

library ieee;
use ieee.std_logic_1164.all;

entity barrel_shifter is
    port (
        \in\  : in  std_logic_vector(7 downto 0);
        ctrl  : in  std_logic_vector(2 downto 0);
        \out\ : out std_logic_vector(7 downto 0)
    );
end entity barrel_shifter;

architecture rtl of barrel_shifter is
    signal stage4 : std_logic_vector(7 downto 0);
    signal stage2 : std_logic_vector(7 downto 0);
begin
    -- Cascaded circular right rotations by 4, 2, and 1 positions.
    gen_bits : for i in 0 to 7 generate
        mux_stage4 : entity work.mux2X1(rtl)
            port map (
                a   => \in\(i),
                b   => \in\((i + 4) mod 8),
                sel => ctrl(2),
                y   => stage4(i)
            );

        mux_stage2 : entity work.mux2X1(rtl)
            port map (
                a   => stage4(i),
                b   => stage4((i + 2) mod 8),
                sel => ctrl(1),
                y   => stage2(i)
            );

        mux_stage1 : entity work.mux2X1(rtl)
            port map (
                a   => stage2(i),
                b   => stage2((i + 1) mod 8),
                sel => ctrl(0),
                y   => \out\(i)
            );
    end generate gen_bits;
end architecture rtl;
