library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity adder_pipe_64bit is
    Port (
        clk    : in  std_logic;
        rst_n  : in  std_logic;
        i_en   : in  std_logic;
        adda   : in  std_logic_vector(63 downto 0);
        addb   : in  std_logic_vector(63 downto 0);
        result : out std_logic_vector(64 downto 0);
        o_en   : out std_logic
    );
end adder_pipe_64bit;

architecture rtl of adder_pipe_64bit is
    signal pipe0, pipe1, pipe2, pipe3 : unsigned(63 downto 0);
    signal carry0, carry1, carry2, carry3 : std_logic;
    signal a1, b1 : unsigned(47 downto 0);
    signal a2, b2 : unsigned(31 downto 0);
    signal a3, b3 : unsigned(15 downto 0);
    signal e0, e1, e2 : std_logic;
    signal o_en_int : std_logic;
begin
    process(clk, rst_n)
        variable sum0_v : unsigned(16 downto 0);
        variable sum1_v : unsigned(16 downto 0);
        variable sum2_v : unsigned(16 downto 0);
        variable sum3_v : unsigned(16 downto 0);
    begin
        if rst_n = '0' then
            pipe0 <= (others => '0');
            pipe1 <= (others => '0');
            pipe2 <= (others => '0');
            pipe3 <= (others => '0');
            carry0 <= '0';
            carry1 <= '0';
            carry2 <= '0';
            carry3 <= '0';
            a1 <= (others => '0');
            b1 <= (others => '0');
            a2 <= (others => '0');
            b2 <= (others => '0');
            a3 <= (others => '0');
            b3 <= (others => '0');
            e0 <= '0';
            e1 <= '0';
            e2 <= '0';
            o_en_int <= '0';
        elsif rising_edge(clk) then
            -- Stage 0
            sum0_v := ('0' & unsigned(adda(15 downto 0))) + ('0' & unsigned(addb(15 downto 0)));
            pipe0 <= resize(sum0_v(15 downto 0), 64);
            carry0 <= sum0_v(16);
            a1 <= unsigned(adda(63 downto 16));
            b1 <= unsigned(addb(63 downto 16));
            e0 <= i_en;

            -- Stage 1
            sum1_v := ('0' & a1(15 downto 0)) + ('0' & b1(15 downto 0));
            if carry0 = '1' then
                sum1_v := sum1_v + 1;
            end if;
            pipe1 <= pipe0(63 downto 32) & sum1_v(15 downto 0) & pipe0(15 downto 0);
            carry1 <= sum1_v(16);
            a2 <= a1(47 downto 16);
            b2 <= b1(47 downto 16);
            e1 <= e0;

            -- Stage 2
            sum2_v := ('0' & a2(15 downto 0)) + ('0' & b2(15 downto 0));
            if carry1 = '1' then
                sum2_v := sum2_v + 1;
            end if;
            pipe2 <= pipe1(63 downto 48) & sum2_v(15 downto 0) & pipe1(31 downto 0);
            carry2 <= sum2_v(16);
            a3 <= a2(31 downto 16);
            b3 <= b2(31 downto 16);
            e2 <= e1;

            -- Stage 3
            sum3_v := ('0' & a3) + ('0' & b3);
            if carry2 = '1' then
                sum3_v := sum3_v + 1;
            end if;
            pipe3 <= sum3_v(15 downto 0) & pipe2(47 downto 0);
            carry3 <= sum3_v(16);
            o_en_int <= e2;
        end if;
    end process;

    o_en <= o_en_int;
    result <= carry3 & std_logic_vector(pipe3);
end rtl;
