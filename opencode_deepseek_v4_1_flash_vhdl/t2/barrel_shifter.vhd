library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity mux2X1 is
    port (
        a   : in  std_logic;
        b   : in  std_logic;
        sel : in  std_logic;
        y   : out std_logic
    );
end entity mux2X1;

architecture Behavioral of mux2X1 is
begin
    y <= a when sel = '0' else b;
end architecture Behavioral;

entity barrel_shifter is
    port (
        \in\  : in  std_logic_vector(7 downto 0);
        ctrl  : in  std_logic_vector(2 downto 0);
        \out\ : out std_logic_vector(7 downto 0)
    );
end entity barrel_shifter;

architecture Structural of barrel_shifter is
    signal s0 : std_logic_vector(7 downto 0);
    signal s4 : std_logic_vector(7 downto 0);
    signal s2 : std_logic_vector(7 downto 0);
    signal s1 : std_logic_vector(7 downto 0);
begin
    s0 <= \in\;

    -- Stage 1: rotate left by 4 if ctrl(2) = '1'
    gen4: for i in 0 to 7 generate
        u4: entity work.mux2X1
            port map (
                a   => s0(i),
                b   => s0((i + 4) mod 8),
                sel => ctrl(2),
                y   => s4(i)
            );
    end generate gen4;

    -- Stage 2: rotate left by 2 if ctrl(1) = '1'
    gen2: for i in 0 to 7 generate
        u2: entity work.mux2X1
            port map (
                a   => s4(i),
                b   => s4((i + 6) mod 8),
                sel => ctrl(1),
                y   => s2(i)
            );
    end generate gen2;

    -- Stage 3: rotate left by 1 if ctrl(0) = '1'
    gen1: for i in 0 to 7 generate
        u1: entity work.mux2X1
            port map (
                a   => s2(i),
                b   => s2((i + 7) mod 8),
                sel => ctrl(0),
                y   => s1(i)
            );
    end generate gen1;

    \out\ <= s1;

end architecture Structural;
