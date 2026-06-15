library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- 2-to-1 multiplexer used as a building block
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
    Port ( \in\  : in  STD_LOGIC_VECTOR(7 downto 0);   -- extended identifier for reserved word "in"
           ctrl  : in  STD_LOGIC_VECTOR(2 downto 0);
           \out\ : out STD_LOGIC_VECTOR(7 downto 0)    -- extended identifier for reserved word "out"
         );
end barrel_shifter;

architecture structural of barrel_shifter is
    -- Intermediate signals between stages
    signal stage2_in, stage2_out : STD_LOGIC_VECTOR(7 downto 0);
    signal stage1_in, stage1_out : STD_LOGIC_VECTOR(7 downto 0);
    signal stage0_in, stage0_out : STD_LOGIC_VECTOR(7 downto 0);

    -- Shifted vectors for each stage (left rotate)
    signal shift4 : STD_LOGIC_VECTOR(7 downto 0);   -- rotate left by 4
    signal shift2 : STD_LOGIC_VECTOR(7 downto 0);   -- rotate left by 2
    signal shift1 : STD_LOGIC_VECTOR(7 downto 0);   -- rotate left by 1
begin
    -- Connect stages: input -> stage2 -> stage1 -> stage0 -> output
    stage2_in <= \in\;
    stage1_in <= stage2_out;
    stage0_in <= stage1_out;
    \out\     <= stage0_out;

    -- Define rotated versions for each stage
    shift4 <= stage2_in(3 downto 0) & stage2_in(7 downto 4);   -- left rotate by 4
    shift2 <= stage1_in(5 downto 0) & stage1_in(7 downto 6);   -- left rotate by 2
    shift1 <= stage0_in(6 downto 0) & stage0_in(7);            -- left rotate by 1

    -- Stage 2: Controlled by ctrl(2) -- shift by 4 if '1'
    gen_stage2: for i in 0 to 7 generate
        mux_stage2: entity work.mux2X1
            port map (
                a   => stage2_in(i),
                b   => shift4(i),
                sel => ctrl(2),
                y   => stage2_out(i)
            );
    end generate;

    -- Stage 1: Controlled by ctrl(1) -- shift by 2 if '1'
    gen_stage1: for i in 0 to 7 generate
        mux_stage1: entity work.mux2X1
            port map (
                a   => stage1_in(i),
                b   => shift2(i),
                sel => ctrl(1),
                y   => stage1_out(i)
            );
    end generate;

    -- Stage 0: Controlled by ctrl(0) -- shift by 1 if '1'
    gen_stage0: for i in 0 to 7 generate
        mux_stage0: entity work.mux2X1
            port map (
                a   => stage0_in(i),
                b   => shift1(i),
                sel => ctrl(0),
                y   => stage0_out(i)
            );
    end generate;

end structural;