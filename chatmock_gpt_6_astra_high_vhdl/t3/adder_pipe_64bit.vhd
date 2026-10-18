library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity adder_pipe_64bit is
    port (
        clk    : in  std_logic;
        rst_n  : in  std_logic;
        i_en   : in  std_logic;
        adda   : in  std_logic_vector(63 downto 0);
        addb   : in  std_logic_vector(63 downto 0);
        result : out std_logic_vector(64 downto 0);
        o_en   : out std_logic
    );
end entity adder_pipe_64bit;

architecture rtl of adder_pipe_64bit is
    -- Four pipeline stages, each computing a 16-bit portion.
    signal a_s1, b_s1 : unsigned(47 downto 0);
    signal a_s2, b_s2 : unsigned(31 downto 0);
    signal a_s3, b_s3 : unsigned(15 downto 0);

    signal sum_s1 : unsigned(15 downto 0);
    signal sum_s2 : unsigned(31 downto 0);
    signal sum_s3 : unsigned(47 downto 0);

    signal carry_s1, carry_s2, carry_s3 : std_logic;
    signal en_s1, en_s2, en_s3          : std_logic;

    -- Explicit ripple-carry addition for each pipeline stage.
    function add16 (
        a   : unsigned(15 downto 0);
        b   : unsigned(15 downto 0);
        cin : std_logic
    ) return unsigned is
        variable s : unsigned(16 downto 0);
        variable c : std_logic;
    begin
        c := cin;
        for i in 0 to 15 loop
            s(i) := a(i) xor b(i) xor c;
            c := (a(i) and b(i)) or
                 (a(i) and c) or
                 (b(i) and c);
        end loop;
        s(16) := c;
        return s;
    end function;
begin
    process (clk, rst_n)
        variable t1, t2, t3, t4 : unsigned(16 downto 0);
    begin
        if rst_n = '0' then
            a_s1 <= (others => '0');
            b_s1 <= (others => '0');
            a_s2 <= (others => '0');
            b_s2 <= (others => '0');
            a_s3 <= (others => '0');
            b_s3 <= (others => '0');

            sum_s1 <= (others => '0');
            sum_s2 <= (others => '0');
            sum_s3 <= (others => '0');

            carry_s1 <= '0';
            carry_s2 <= '0';
            carry_s3 <= '0';

            en_s1 <= '0';
            en_s2 <= '0';
            en_s3 <= '0';
            o_en  <= '0';

            result <= (others => '0');
        elsif rising_edge(clk) then
            -- Stage 1: bits 15:0.
            t1 := add16(unsigned(adda(15 downto 0)),
                        unsigned(addb(15 downto 0)), '0');
            sum_s1   <= t1(15 downto 0);
            carry_s1 <= t1(16);
            a_s1     <= unsigned(adda(63 downto 16));
            b_s1     <= unsigned(addb(63 downto 16));
            en_s1    <= i_en;

            -- Stage 2: bits 31:16.
            t2 := add16(a_s1(15 downto 0),
                        b_s1(15 downto 0), carry_s1);
            sum_s2   <= t2(15 downto 0) & sum_s1;
            carry_s2 <= t2(16);
            a_s2     <= a_s1(47 downto 16);
            b_s2     <= b_s1(47 downto 16);
            en_s2    <= en_s1;

            -- Stage 3: bits 47:32.
            t3 := add16(a_s2(15 downto 0),
                        b_s2(15 downto 0), carry_s2);
            sum_s3   <= t3(15 downto 0) & sum_s2;
            carry_s3 <= t3(16);
            a_s3     <= a_s2(31 downto 16);
            b_s3     <= b_s2(31 downto 16);
            en_s3    <= en_s2;

            -- Stage 4: bits 63:48 and the final carry.
            t4 := add16(a_s3, b_s3, carry_s3);
            result <= std_logic_vector(t4 & sum_s3);
            o_en   <= en_s3;
        end if;
    end process;
end architecture rtl;
