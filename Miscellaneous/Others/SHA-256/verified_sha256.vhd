library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sha256_core is
    port(clk          : in  std_logic;
         reset_n      : in  std_logic;
         init         : in  std_logic;
         next_i       : in  std_logic;   -- 'next' is a VHDL keyword
         mode         : in  std_logic;   -- SHA-256 only
         block_i      : in  std_logic_vector(511 downto 0); -- 'block' is a keyword
         ready        : out std_logic;
         digest       : out std_logic_vector(255 downto 0);
         digest_valid : out std_logic);
end sha256_core;

architecture rtl of sha256_core is
    type u32_arr is array(natural range <>) of unsigned(31 downto 0);
    constant IV : u32_arr(0 to 7) := (x"6a09e667", x"bb67ae85", x"3c6ef372", x"a54ff53a", x"510e527f", x"9b05688c", x"1f83d9ab", x"5be0cd19");
    constant KC : u32_arr(0 to 63) := (
        x"428a2f98",
        x"71374491",
        x"b5c0fbcf",
        x"e9b5dba5",
        x"3956c25b",
        x"59f111f1",
        x"923f82a4",
        x"ab1c5ed5",
        x"d807aa98",
        x"12835b01",
        x"243185be",
        x"550c7dc3",
        x"72be5d74",
        x"80deb1fe",
        x"9bdc06a7",
        x"c19bf174",
        x"e49b69c1",
        x"efbe4786",
        x"0fc19dc6",
        x"240ca1cc",
        x"2de92c6f",
        x"4a7484aa",
        x"5cb0a9dc",
        x"76f988da",
        x"983e5152",
        x"a831c66d",
        x"b00327c8",
        x"bf597fc7",
        x"c6e00bf3",
        x"d5a79147",
        x"06ca6351",
        x"14292967",
        x"27b70a85",
        x"2e1b2138",
        x"4d2c6dfc",
        x"53380d13",
        x"650a7354",
        x"766a0abb",
        x"81c2c92e",
        x"92722c85",
        x"a2bfe8a1",
        x"a81a664b",
        x"c24b8b70",
        x"c76c51a3",
        x"d192e819",
        x"d6990624",
        x"f40e3585",
        x"106aa070",
        x"19a4c116",
        x"1e376c08",
        x"2748774c",
        x"34b0bcb5",
        x"391c0cb3",
        x"4ed8aa4a",
        x"5b9cca4f",
        x"682e6ff3",
        x"748f82ee",
        x"78a5636f",
        x"84c87814",
        x"8cc70208",
        x"90befffa",
        x"a4506ceb",
        x"bef9a3f7",
        x"c67178f2");

    function rotr(x : unsigned(31 downto 0); n : integer) return unsigned is
    begin return rotate_right(x, n); end function;
    function bsig0(x : unsigned(31 downto 0)) return unsigned is
    begin return rotr(x,2) xor rotr(x,13) xor rotr(x,22); end function;
    function bsig1(x : unsigned(31 downto 0)) return unsigned is
    begin return rotr(x,6) xor rotr(x,11) xor rotr(x,25); end function;
    function ssig0(x : unsigned(31 downto 0)) return unsigned is
    begin return rotr(x,7) xor rotr(x,18) xor shift_right(x,3); end function;
    function ssig1(x : unsigned(31 downto 0)) return unsigned is
    begin return rotr(x,17) xor rotr(x,19) xor shift_right(x,10); end function;
    function ch(x,y,z : unsigned(31 downto 0)) return unsigned is
    begin return (x and y) xor ((not x) and z); end function;
    function maj(x,y,z : unsigned(31 downto 0)) return unsigned is
    begin return (x and y) xor (x and z) xor (y and z); end function;

    signal state : integer range 0 to 2 := 0;
    signal hs    : u32_arr(0 to 7);                       -- hash state H0..H7
    signal a,b,c,d,e,f,g,hh : unsigned(31 downto 0);      -- working vars (hh avoids H/h clash)
    signal w     : u32_arr(0 to 15);
    signal t     : integer range 0 to 127 := 0;
begin
    digest <= std_logic_vector(hs(0)) & std_logic_vector(hs(1)) & std_logic_vector(hs(2)) &
              std_logic_vector(hs(3)) & std_logic_vector(hs(4)) & std_logic_vector(hs(5)) &
              std_logic_vector(hs(6)) & std_logic_vector(hs(7));

    process(clk, reset_n)
        variable t1v, t2v, nw : unsigned(31 downto 0);
    begin
        if reset_n = '0' then
            state <= 0; ready <= '1'; digest_valid <= '0'; t <= 0;
            hs <= (others => (others => '0'));
        elsif rising_edge(clk) then
            case state is
                when 0 =>                                  -- IDLE
                    ready <= '1';
                    if init = '1' or next_i = '1' then
                        for idx in 0 to 15 loop
                            w(idx) <= unsigned(block_i(511 - idx*32 downto 480 - idx*32));
                        end loop;
                        if init = '1' then
                            hs <= IV;
                            a<=IV(0); b<=IV(1); c<=IV(2); d<=IV(3);
                            e<=IV(4); f<=IV(5); g<=IV(6); hh<=IV(7);
                        else
                            a<=hs(0); b<=hs(1); c<=hs(2); d<=hs(3);
                            e<=hs(4); f<=hs(5); g<=hs(6); hh<=hs(7);
                        end if;
                        t <= 0; ready <= '0'; digest_valid <= '0'; state <= 1;
                    end if;
                when 1 =>                                  -- WORK
                    t1v := hh + bsig1(e) + ch(e,f,g) + KC(t) + w(0);
                    t2v := bsig0(a) + maj(a,b,c);
                    hh <= g; g <= f; f <= e; e <= d + t1v;
                    d <= c; c <= b; b <= a; a <= t1v + t2v;
                    nw := ssig1(w(14)) + w(9) + ssig0(w(1)) + w(0);
                    for idx in 0 to 14 loop w(idx) <= w(idx+1); end loop;
                    w(15) <= nw;
                    t <= t + 1;
                    if t = 63 then state <= 2; end if;
                when others =>                             -- FIN
                    hs(0)<=hs(0)+a; hs(1)<=hs(1)+b; hs(2)<=hs(2)+c; hs(3)<=hs(3)+d;
                    hs(4)<=hs(4)+e; hs(5)<=hs(5)+f; hs(6)<=hs(6)+g; hs(7)<=hs(7)+hh;
                    ready <= '1'; digest_valid <= '1'; state <= 0;
            end case;
        end if;
    end process;
end rtl;


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity verified_sha256 is
    port(clk        : in  std_logic;
         reset_n    : in  std_logic;
         cs         : in  std_logic;
         we         : in  std_logic;
         address    : in  std_logic_vector(7 downto 0);
         write_data : in  std_logic_vector(31 downto 0);
         read_data  : out std_logic_vector(31 downto 0);
         error      : out std_logic);
end verified_sha256;

architecture rtl of verified_sha256 is
    type blk_arr is array(0 to 15) of std_logic_vector(31 downto 0);
    signal block_reg : blk_arr;
    signal init_reg, next_reg, mode_reg : std_logic := '0';
    signal core_ready, core_valid : std_logic;
    signal core_digest : std_logic_vector(255 downto 0);
    signal core_block  : std_logic_vector(511 downto 0);
    constant Z30 : std_logic_vector(29 downto 0) := (others => '0');
begin
    core_block <= block_reg(0) & block_reg(1) & block_reg(2)  & block_reg(3) &
                  block_reg(4) & block_reg(5) & block_reg(6)  & block_reg(7) &
                  block_reg(8) & block_reg(9) & block_reg(10) & block_reg(11) &
                  block_reg(12)& block_reg(13)& block_reg(14) & block_reg(15);

    core : entity work.sha256_core
        port map(clk => clk, reset_n => reset_n,
                 init => init_reg, next_i => next_reg, mode => mode_reg,
                 block_i => core_block,
                 ready => core_ready, digest => core_digest, digest_valid => core_valid);

    -- write / control
    process(clk, reset_n)
        variable ai : integer;
    begin
        if reset_n = '0' then
            init_reg <= '0'; next_reg <= '0'; mode_reg <= '0';
            block_reg <= (others => (others => '0'));
        elsif rising_edge(clk) then
            init_reg <= '0';
            next_reg <= '0';
            if cs = '1' and we = '1' then
                ai := to_integer(unsigned(address));
                if ai >= 16 and ai <= 31 then
                    block_reg(ai - 16) <= write_data;
                elsif ai = 8 then
                    init_reg <= write_data(0);
                    next_reg <= write_data(1);
                    mode_reg <= write_data(2);
                end if;
            end if;
        end if;
    end process;

    -- read
    process(cs, we, address, core_digest, core_valid, core_ready)
        variable ai : integer;
    begin
        read_data <= (others => '0');
        error     <= '0';
        if cs = '1' and we = '0' then
            ai := to_integer(unsigned(address));
            if ai >= 32 and ai <= 39 then
                read_data <= core_digest(255 - (ai-32)*32 downto 224 - (ai-32)*32);
            else
                case ai is
                    when 0 => read_data <= x"73686132";
                    when 1 => read_data <= x"35362020";
                    when 2 => read_data <= x"302e3830";
                    when 9 => read_data <= Z30 & core_valid & core_ready;
                    when others => error <= '1';
                end case;
            end if;
        end if;
    end process;
end rtl;
