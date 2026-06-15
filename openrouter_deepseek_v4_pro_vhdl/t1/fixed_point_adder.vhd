library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity fixed_point_adder is
    generic (
        Q : natural;  -- number of fractional bits (precision)
        N : positive  -- total number of bits (including integer and fractional parts, N >= 2)
    );
    port (
        a : in  std_logic_vector(N-1 downto 0);
        b : in  std_logic_vector(N-1 downto 0);
        c : out std_logic_vector(N-1 downto 0)
    );
end fixed_point_adder;

architecture behave of fixed_point_adder is
    -- internal register as required by specification (used combinatorially here)
    signal res : std_logic_vector(N-1 downto 0);
    constant MAG_WIDTH : natural := N-1;  -- number of magnitude bits
begin
    process(a, b)
        variable sign_a, sign_b   : std_logic;
        variable mag_a, mag_b     : unsigned(MAG_WIDTH-1 downto 0);
        variable sum_mag          : unsigned(MAG_WIDTH downto 0);   -- extra bit for carry
        variable diff_mag         : unsigned(MAG_WIDTH-1 downto 0);
        variable sign_res         : std_logic;
        variable mag_res          : unsigned(MAG_WIDTH-1 downto 0);
    begin
        if N < 2 then
            -- degenerate case: no magnitude bits, output zero
            res <= (others => '0');
        else
            -- extract sign and magnitude
            sign_a := a(N-1);
            mag_a  := unsigned(a(MAG_WIDTH-1 downto 0));
            sign_b := b(N-1);
            mag_b  := unsigned(b(MAG_WIDTH-1 downto 0));

            if sign_a = sign_b then
                -- both operands have the same sign: add absolute values
                sum_mag := ('0' & mag_a) + ('0' & mag_b);
                if sum_mag(MAG_WIDTH) = '1' then  -- overflow detected
                    mag_res := (others => '1');    -- saturate to maximum magnitude
                else
                    mag_res := sum_mag(MAG_WIDTH-1 downto 0);
                end if;
                sign_res := sign_a;
            else
                -- different signs: subtract smaller magnitude from larger one
                if mag_a > mag_b then
                    diff_mag := mag_a - mag_b;
                    mag_res  := diff_mag;
                    sign_res := sign_a;           -- result takes sign of the larger operand (a)
                elsif mag_b > mag_a then
                    diff_mag := mag_b - mag_a;
                    mag_res  := diff_mag;
                    sign_res := sign_b;           -- result takes sign of the larger operand (b)
                else
                    mag_res  := (others => '0');  -- zero magnitude
                    sign_res := '0';              -- zero is treated as positive
                end if;
            end if;

            res <= sign_res & std_logic_vector(mag_res);
        end if;
    end process;

    c <= res;
end behave;