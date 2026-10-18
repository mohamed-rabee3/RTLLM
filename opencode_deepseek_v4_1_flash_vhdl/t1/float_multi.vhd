library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity float_multi is
    Port (
        clk : in STD_LOGIC;
        rst : in STD_LOGIC;
        a : in STD_LOGIC_VECTOR (31 downto 0);
        b : in STD_LOGIC_VECTOR (31 downto 0);
        z : out STD_LOGIC_VECTOR (31 downto 0)
    );
end float_multi;

architecture Behavioral of float_multi is
    signal counter : unsigned(2 downto 0);
    signal a_mantissa : unsigned(23 downto 0);
    signal b_mantissa : unsigned(23 downto 0);
    signal z_mantissa : unsigned(23 downto 0);
    signal a_exponent : unsigned(9 downto 0);
    signal b_exponent : unsigned(9 downto 0);
    signal z_exponent : unsigned(9 downto 0);
    signal a_sign : std_logic;
    signal b_sign : std_logic;
    signal z_sign : std_logic;
    signal product : unsigned(49 downto 0);
    signal guard_bit : std_logic;
    signal round_bit : std_logic;
    signal sticky : std_logic;
begin
    process(clk)
        variable sa, sb : std_logic;
        variable ea, eb : integer range 0 to 255;
        variable fa, fb : unsigned(22 downto 0);
        variable ma, mb : unsigned(23 downto 0);
        variable exa, exb, e : integer range -400 to 400;
        variable prod_v : unsigned(49 downto 0);
        variable h : integer range 0 to 49;
        variable shift : integer range -50 to 50;
        variable M_floor, M_v, F_floor, F_v : unsigned(24 downto 0);
        variable E_tmp : integer range -1000 to 1000;
        variable q : integer range -500 to 500;
        variable shift_sub : integer range 0 to 500;
        variable g, sticky_v : std_logic;
        variable res : unsigned(31 downto 0);
    begin
        if rising_edge(clk) then
            if rst = '1' then
                z <= (others => '0');
                counter <= (others => '0');
                a_mantissa <= (others => '0');
                b_mantissa <= (others => '0');
                z_mantissa <= (others => '0');
                a_exponent <= (others => '0');
                b_exponent <= (others => '0');
                z_exponent <= (others => '0');
                a_sign <= '0';
                b_sign <= '0';
                z_sign <= '0';
                product <= (others => '0');
                guard_bit <= '0';
                round_bit <= '0';
                sticky <= '0';
            else
                counter <= counter + 1;
                
                sa := a(31);
                ea := to_integer(unsigned(a(30 downto 23)));
                fa := unsigned(a(22 downto 0));
                sb := b(31);
                eb := to_integer(unsigned(b(30 downto 23)));
                fb := unsigned(b(22 downto 0));
                
                a_sign <= sa;
                b_sign <= sb;
                a_exponent <= to_unsigned(ea, 10);
                b_exponent <= to_unsigned(eb, 10);
                
                -- Special cases handling
                if ((ea = 255 and fa /= 0) or (eb = 255 and fb /= 0)) then
                    res := to_unsigned(16#7FC00000#, 32); -- Quiet NaN
                elsif ((ea = 255 and fa = 0) and (eb = 0 and fb = 0)) or
                      ((eb = 255 and fb = 0) and (ea = 0 and fa = 0)) then
                    res := to_unsigned(16#7FC00000#, 32); -- Inf * 0 = NaN
                elsif (ea = 255 and fa = 0) or (eb = 255 and fb = 0) then
                    res(31) := sa xor sb;
                    res(30 downto 23) := (others => '1');
                    res(22 downto 0) := (others => '0');
                elsif (ea = 0 and fa = 0) or (eb = 0 and fb = 0) then
                    res(31) := sa xor sb;
                    res(30 downto 23) := (others => '0');
                    res(22 downto 0) := (others => '0');
                else
                    -- Finite non-zero multiplication
                    if ea = 0 then
                        ma := '0' & fa;
                        exa := -149;
                    else
                        ma := '1' & fa;
                        exa := ea - 150;
                    end if;
                    if eb = 0 then
                        mb := '0' & fb;
                        exb := -149;
                    else
                        mb := '1' & fb;
                        exb := eb - 150;
                    end if;
                    
                    a_mantissa <= ma;
                    b_mantissa <= mb;
                    
                    prod_v := resize(ma * mb, 50);
                    product <= prod_v;
                    e := exa + exb;
                    
                    -- Find most significant bit index
                    h := 0;
                    for i in 49 downto 0 loop
                        if prod_v(i) = '1' then
                            h := i;
                            exit;
                        end if;
                    end loop;
                    
                    E_tmp := e + h + 127;
                    
                    if E_tmp > 0 then
                        -- Normal result
                        if E_tmp >= 255 then
                            res(31) := sa xor sb;
                            res(30 downto 23) := (others => '1');
                            res(22 downto 0) := (others => '0');
                        else
                            shift := h - 23;
                            if shift > 0 then
                                M_floor := resize(shift_right(prod_v, shift), 25);
                                g := prod_v(shift - 1);
                                sticky_v := '0';
                                for i in 0 to 49 loop
                                    if i < shift - 1 then
                                        sticky_v := sticky_v or prod_v(i);
                                    end if;
                                end loop;
                                if g = '1' and (sticky_v = '1' or M_floor(0) = '1') then
                                    M_v := M_floor + 1;
                                else
                                    M_v := M_floor;
                                end if;
                            else
                                M_v := resize(shift_left(prod_v, -shift), 25);
                            end if;
                            
                            if M_v(24) = '1' then
                                M_v := shift_right(M_v, 1);
                                E_tmp := E_tmp + 1;
                            end if;
                            
                            if E_tmp >= 255 then
                                res(31) := sa xor sb;
                                res(30 downto 23) := (others => '1');
                                res(22 downto 0) := (others => '0');
                            else
                                res(31) := sa xor sb;
                                res(30 downto 23) := to_unsigned(E_tmp, 8);
                                res(22 downto 0) := M_v(22 downto 0);
                            end if;
                        end if;
                    else
                        -- Subnormal or zero result
                        q := e + 149;
                        if q >= 0 then
                            F_v := resize(shift_left(prod_v, q), 25);
                        else
                            shift_sub := -q;
                            if shift_sub > 0 then
                                F_floor := (others => '0');
                                if shift_sub <= 49 then
                                    F_floor := resize(shift_right(prod_v, shift_sub), 25);
                                end if;
                                g := '0';
                                if shift_sub - 1 <= 49 then
                                    g := prod_v(shift_sub - 1);
                                end if;
                                sticky_v := '0';
                                for i in 0 to 49 loop
                                    if i < shift_sub - 1 then
                                        sticky_v := sticky_v or prod_v(i);
                                    end if;
                                end loop;
                                if g = '1' and (sticky_v = '1' or F_floor(0) = '1') then
                                    F_v := resize(F_floor + 1, 25);
                                else
                                    F_v := resize(F_floor, 25);
                                end if;
                            else
                                F_v := resize(prod_v, 25);
                            end if;
                        end if;
                        
                        if F_v >= to_unsigned(2**23, 25) then
                            res(31) := sa xor sb;
                            res(30 downto 23) := "00000001";
                            res(22 downto 0) := (others => '0');
                        else
                            res(31) := sa xor sb;
                            res(30 downto 23) := (others => '0');
                            res(22 downto 0) := F_v(22 downto 0);
                        end if;
                    end if;
                end if;
                
                z <= std_logic_vector(res);
                
                z_sign <= res(31);
                z_exponent <= to_unsigned(to_integer(unsigned(res(30 downto 23))), 10);
                z_mantissa <= unsigned(res(22 downto 0)) & '0';
            end if;
        end if;
    end process;
end Behavioral;
