library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity fixed_point_adder is
    generic (
        Q : integer := 8;
        N : integer := 16
    );
    port (
        a : in STD_LOGIC_VECTOR(N-1 downto 0);
        b : in STD_LOGIC_VECTOR(N-1 downto 0);
        c : out STD_LOGIC_VECTOR(N-1 downto 0)
    );
end fixed_point_adder;

architecture Behavioral of fixed_point_adder is
    signal res : STD_LOGIC_VECTOR(N-1 downto 0);
begin
    process(a, b)
        variable sign_a, sign_b, sign_res : STD_LOGIC;
        variable mag_a, mag_b : unsigned(N-2 downto 0);
        variable sum_mag : unsigned(N-1 downto 0);
        variable diff_mag : unsigned(N-2 downto 0);
        variable res_var : STD_LOGIC_VECTOR(N-1 downto 0);
    begin
        sign_a := a(N-1);
        sign_b := b(N-1);
        mag_a := unsigned(a(N-2 downto 0));
        mag_b := unsigned(b(N-2 downto 0));

        if sign_a = sign_b then
            sum_mag := resize(mag_a, N) + resize(mag_b, N);
            if sum_mag(N-1) = '1' then
                res_var(N-1) := sign_a;
                res_var(N-2 downto 0) := (others => '1');
            else
                res_var(N-1) := sign_a;
                res_var(N-2 downto 0) := std_logic_vector(sum_mag(N-2 downto 0));
            end if;
        else
            if mag_a > mag_b then
                diff_mag := mag_a - mag_b;
                sign_res := sign_a;
            elsif mag_b > mag_a then
                diff_mag := mag_b - mag_a;
                sign_res := sign_b;
            else
                diff_mag := (others => '0');
                sign_res := '0';
            end if;
            res_var(N-1) := sign_res;
            res_var(N-2 downto 0) := std_logic_vector(diff_mag);
        end if;

        res <= res_var;
    end process;

    c <= res;
end Behavioral;
