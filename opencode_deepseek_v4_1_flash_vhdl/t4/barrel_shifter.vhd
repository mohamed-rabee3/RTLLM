library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity mux2X1 is
    Port ( a   : in  STD_LOGIC;
           b   : in  STD_LOGIC;
           sel : in  STD_LOGIC;
           y   : out STD_LOGIC);
end mux2X1;

architecture Behavioral of mux2X1 is
begin
    y <= a when sel = '0' else b;
end Behavioral;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity barrel_shifter is
    Port ( \in\  : in  STD_LOGIC_VECTOR (7 downto 0);
           ctrl  : in  STD_LOGIC_VECTOR (2 downto 0);
           \out\ : out STD_LOGIC_VECTOR (7 downto 0));
end barrel_shifter;

architecture Structural of barrel_shifter is
    component mux2X1
        Port ( a   : in  STD_LOGIC;
               b   : in  STD_LOGIC;
               sel : in  STD_LOGIC;
               y   : out STD_LOGIC);
    end component;

    signal s1, s2 : STD_LOGIC_VECTOR(7 downto 0);
begin
    -- Stage 1: shift by 4 when ctrl(2) = '1'
    mux4_0: mux2X1 port map (a => \in\(0), b => \in\(4), sel => ctrl(2), y => s1(0));
    mux4_1: mux2X1 port map (a => \in\(1), b => \in\(5), sel => ctrl(2), y => s1(1));
    mux4_2: mux2X1 port map (a => \in\(2), b => \in\(6), sel => ctrl(2), y => s1(2));
    mux4_3: mux2X1 port map (a => \in\(3), b => \in\(7), sel => ctrl(2), y => s1(3));
    mux4_4: mux2X1 port map (a => \in\(4), b => \in\(0), sel => ctrl(2), y => s1(4));
    mux4_5: mux2X1 port map (a => \in\(5), b => \in\(1), sel => ctrl(2), y => s1(5));
    mux4_6: mux2X1 port map (a => \in\(6), b => \in\(2), sel => ctrl(2), y => s1(6));
    mux4_7: mux2X1 port map (a => \in\(7), b => \in\(3), sel => ctrl(2), y => s1(7));

    -- Stage 2: shift by 2 when ctrl(1) = '1'
    mux2_0: mux2X1 port map (a => s1(0), b => s1(2), sel => ctrl(1), y => s2(0));
    mux2_1: mux2X1 port map (a => s1(1), b => s1(3), sel => ctrl(1), y => s2(1));
    mux2_2: mux2X1 port map (a => s1(2), b => s1(4), sel => ctrl(1), y => s2(2));
    mux2_3: mux2X1 port map (a => s1(3), b => s1(5), sel => ctrl(1), y => s2(3));
    mux2_4: mux2X1 port map (a => s1(4), b => s1(6), sel => ctrl(1), y => s2(4));
    mux2_5: mux2X1 port map (a => s1(5), b => s1(7), sel => ctrl(1), y => s2(5));
    mux2_6: mux2X1 port map (a => s1(6), b => s1(0), sel => ctrl(1), y => s2(6));
    mux2_7: mux2X1 port map (a => s1(7), b => s1(1), sel => ctrl(1), y => s2(7));

    -- Stage 3: shift by 1 when ctrl(0) = '1'
    mux1_0: mux2X1 port map (a => s2(0), b => s2(1), sel => ctrl(0), y => \out\(0));
    mux1_1: mux2X1 port map (a => s2(1), b => s2(2), sel => ctrl(0), y => \out\(1));
    mux1_2: mux2X1 port map (a => s2(2), b => s2(3), sel => ctrl(0), y => \out\(2));
    mux1_3: mux2X1 port map (a => s2(3), b => s2(4), sel => ctrl(0), y => \out\(3));
    mux1_4: mux2X1 port map (a => s2(4), b => s2(5), sel => ctrl(0), y => \out\(4));
    mux1_5: mux2X1 port map (a => s2(5), b => s2(6), sel => ctrl(0), y => \out\(5));
    mux1_6: mux2X1 port map (a => s2(6), b => s2(7), sel => ctrl(0), y => \out\(6));
    mux1_7: mux2X1 port map (a => s2(7), b => s2(0), sel => ctrl(0), y => \out\(7));

end Structural;
