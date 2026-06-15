library ieee;
use ieee.std_logic_1164.all;

-- Full adder component used as a bit-level adder
entity full_adder is
    port (
        a    : in  std_logic;
        b    : in  std_logic;
        cin  : in  std_logic;
        sum  : out std_logic;
        cout : out std_logic
    );
end entity full_adder;

architecture dataflow of full_adder is
begin
    sum  <= a xor b xor cin;
    cout <= (a and b) or (cin and (a xor b));
end architecture dataflow;

-- 8-bit adder that chains eight bit-level full adders
entity adder_8bit is
    port (
        a    : in  std_logic_vector(7 downto 0);
        b    : in  std_logic_vector(7 downto 0);
        cin  : in  std_logic;
        sum  : out std_logic_vector(7 downto 0);
        cout : out std_logic
    );
end entity adder_8bit;

architecture structural of adder_8bit is
    signal carry : std_logic_vector(8 downto 0);  -- internal carry chain
begin
    -- Connect carry-in and carry-out to the internal chain
    carry(0) <= cin;
    cout     <= carry(8);

    -- Generate 8 full adder instances, one per bit position
    gen_full_adders: for i in 0 to 7 generate
        fa: entity work.full_adder(dataflow)
            port map (
                a    => a(i),
                b    => b(i),
                cin  => carry(i),
                sum  => sum(i),
                cout => carry(i+1)
            );
    end generate gen_full_adders;

end architecture structural;