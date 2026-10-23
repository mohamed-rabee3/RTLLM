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
    -- Rotate right by four positions when ctrl(2) is asserted.
    gen_stage4 : for i in 0 to 7 generate
        mux4 : entity work.mux2X1(rtl)
            port map (
                a   => \in\(i),
                b   => \in\((i + 4) mod 8),
                sel => ctrl(2),
                y   => stage4(i)
            );
    end generate gen_stage4;

    -- Rotate right by two additional positions when ctrl(1) is asserted.
    gen_stage2 : for i in 0 to 7 generate
        mux2 : entity work.mux2X1(rtl)
            port map (
                a   => stage4(i),
                b   => stage4((i + 2) mod 8),
                sel => ctrl(1),
                y   => stage2(i)
            );
    end generate gen_stage2;

    -- Rotate right by one additional position when ctrl(0) is asserted.
    gen_stage1 : for i in 0 to 7 generate
        mux1 : entity work.mux2X1(rtl)
            port map (
                a   => stage2(i),
                b   => stage2((i + 1) mod 8),
                sel => ctrl(0),
                y   => \out\(i)
            );
    end generate gen_stage1;
end architecture rtl;
