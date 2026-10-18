library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity mux2X1 is
    port (
        a   : in  std_logic;
        b   : in  std_logic;
        sel : in  std_logic;
        y   : out std_logic
    );
end mux2X1;

architecture behavioral of mux2X1 is
begin
    y <= a when sel = '0' else b;
end behavioral;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity barrel_shifter is
    port (
        \in\  : in  std_logic_vector(7 downto 0);
        ctrl  : in  std_logic_vector(2 downto 0);
        \out\ : out std_logic_vector(7 downto 0)
    );
end barrel_shifter;

architecture rtl of barrel_shifter is
    signal stage1 : std_logic_vector(7 downto 0);
    signal stage2 : std_logic_vector(7 downto 0);
    signal stage3 : std_logic_vector(7 downto 0);

    component mux2X1
        port (
            a   : in  std_logic;
            b   : in  std_logic;
            sel : in  std_logic;
            y   : out std_logic
        );
    end component;
begin

    -- Stage 1: rotate left by 4 if ctrl(2) = '1'
    gen_stage1 : for i in 0 to 7 generate
        mux_stage1 : mux2X1 port map (
            a   => \in\(i),
            b   => \in\((i + 4) mod 8),
            sel => ctrl(2),
            y   => stage1(i)
        );
    end generate;

    -- Stage 2: rotate left by 2 if ctrl(1) = '1'
    gen_stage2 : for i in 0 to 7 generate
        mux_stage2 : mux2X1 port map (
            a   => stage1(i),
            b   => stage1((i + 6) mod 8),
            sel => ctrl(1),
            y   => stage2(i)
        );
    end generate;

    -- Stage 3: rotate left by 1 if ctrl(0) = '1'
    gen_stage3 : for i in 0 to 7 generate
        mux_stage3 : mux2X1 port map (
            a   => stage2(i),
            b   => stage2((i + 7) mod 8),
            sel => ctrl(0),
            y   => stage3(i)
        );
    end generate;

    \out\ <= stage3;

end rtl;
