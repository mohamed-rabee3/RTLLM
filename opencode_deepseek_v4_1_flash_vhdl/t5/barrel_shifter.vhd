library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity mux2X1 is
    Port (
        a   : in  STD_LOGIC;
        b   : in  STD_LOGIC;
        sel : in  STD_LOGIC;
        y   : out STD_LOGIC
    );
end mux2X1;

architecture rtl of mux2X1 is
begin
    y <= b when sel = '1' else a;
end rtl;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity barrel_shifter is
    Port (
        \in\ : in  STD_LOGIC_VECTOR(7 downto 0);
        ctrl : in  STD_LOGIC_VECTOR(2 downto 0);
        \out\ : out STD_LOGIC_VECTOR(7 downto 0)
    );
end barrel_shifter;

architecture rtl of barrel_shifter is
    signal stage4 : STD_LOGIC_VECTOR(7 downto 0);
    signal stage2 : STD_LOGIC_VECTOR(7 downto 0);
    signal stage1 : STD_LOGIC_VECTOR(7 downto 0);

    component mux2X1 is
        Port (
            a   : in  STD_LOGIC;
            b   : in  STD_LOGIC;
            sel : in  STD_LOGIC;
            y   : out STD_LOGIC
        );
    end component;

begin
    -- Stage 1: shift by 4 if ctrl(2) = '1'
    mux4_0: mux2X1 port map (a => \in\(0), b => '0', sel => ctrl(2), y => stage4(0));
    mux4_1: mux2X1 port map (a => \in\(1), b => '0', sel => ctrl(2), y => stage4(1));
    mux4_2: mux2X1 port map (a => \in\(2), b => '0', sel => ctrl(2), y => stage4(2));
    mux4_3: mux2X1 port map (a => \in\(3), b => '0', sel => ctrl(2), y => stage4(3));
    mux4_4: mux2X1 port map (a => \in\(4), b => \in\(0), sel => ctrl(2), y => stage4(4));
    mux4_5: mux2X1 port map (a => \in\(5), b => \in\(1), sel => ctrl(2), y => stage4(5));
    mux4_6: mux2X1 port map (a => \in\(6), b => \in\(2), sel => ctrl(2), y => stage4(6));
    mux4_7: mux2X1 port map (a => \in\(7), b => \in\(3), sel => ctrl(2), y => stage4(7));

    -- Stage 2: shift by 2 if ctrl(1) = '1'
    mux2_0: mux2X1 port map (a => stage4(0), b => '0', sel => ctrl(1), y => stage2(0));
    mux2_1: mux2X1 port map (a => stage4(1), b => '0', sel => ctrl(1), y => stage2(1));
    mux2_2: mux2X1 port map (a => stage4(2), b => stage4(0), sel => ctrl(1), y => stage2(2));
    mux2_3: mux2X1 port map (a => stage4(3), b => stage4(1), sel => ctrl(1), y => stage2(3));
    mux2_4: mux2X1 port map (a => stage4(4), b => stage4(2), sel => ctrl(1), y => stage2(4));
    mux2_5: mux2X1 port map (a => stage4(5), b => stage4(3), sel => ctrl(1), y => stage2(5));
    mux2_6: mux2X1 port map (a => stage4(6), b => stage4(4), sel => ctrl(1), y => stage2(6));
    mux2_7: mux2X1 port map (a => stage4(7), b => stage4(5), sel => ctrl(1), y => stage2(7));

    -- Stage 3: shift by 1 if ctrl(0) = '1'
    mux1_0: mux2X1 port map (a => stage2(0), b => '0', sel => ctrl(0), y => stage1(0));
    mux1_1: mux2X1 port map (a => stage2(1), b => stage2(0), sel => ctrl(0), y => stage1(1));
    mux1_2: mux2X1 port map (a => stage2(2), b => stage2(1), sel => ctrl(0), y => stage1(2));
    mux1_3: mux2X1 port map (a => stage2(3), b => stage2(2), sel => ctrl(0), y => stage1(3));
    mux1_4: mux2X1 port map (a => stage2(4), b => stage2(3), sel => ctrl(0), y => stage1(4));
    mux1_5: mux2X1 port map (a => stage2(5), b => stage2(4), sel => ctrl(0), y => stage1(5));
    mux1_6: mux2X1 port map (a => stage2(6), b => stage2(5), sel => ctrl(0), y => stage1(6));
    mux1_7: mux2X1 port map (a => stage2(7), b => stage2(6), sel => ctrl(0), y => stage1(7));

    \out\ <= stage1;
end rtl;
