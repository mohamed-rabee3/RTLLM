library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity AES_Encrypt is
    port (
        clk         : in  std_logic;
        rst         : in  std_logic;
        Plain_text  : in  std_logic_vector(127 downto 0);
        EN          : in  std_logic;
        Key_in      : in  std_logic_vector(127 downto 0);
        Cypher_text : out std_logic_vector(127 downto 0)
    );
end entity AES_Encrypt;

architecture rtl of AES_Encrypt is

    subtype byte_t  is std_logic_vector(7 downto 0);
    subtype word_t  is std_logic_vector(31 downto 0);
    subtype block_t is std_logic_vector(127 downto 0);

    type sbox_t is array (0 to 255) of byte_t;
    constant SBOX : sbox_t := (
        x"63", x"7C", x"77", x"7B", x"F2", x"6B", x"6F", x"C5",
        x"30", x"01", x"67", x"2B", x"FE", x"D7", x"AB", x"76",
        x"CA", x"82", x"C9", x"7D", x"FA", x"59", x"47", x"F0",
        x"AD", x"D4", x"A2", x"AF", x"9C", x"A4", x"72", x"C0",
        x"B7", x"FD", x"93", x"26", x"36", x"3F", x"F7", x"CC",
        x"34", x"A5", x"E5", x"F1", x"71", x"D8", x"31", x"15",
        x"04", x"C7", x"23", x"C3", x"18", x"96", x"05", x"9A",
        x"07", x"12", x"80", x"E2", x"EB", x"27", x"B2", x"75",
        x"09", x"83", x"2C", x"1A", x"1B", x"6E", x"5A", x"A0",
        x"52", x"3B", x"D6", x"B3", x"29", x"E3", x"2F", x"84",
        x"53", x"D1", x"00", x"ED", x"20", x"FC", x"B1", x"5B",
        x"6A", x"CB", x"BE", x"39", x"4A", x"4C", x"58", x"CF",
        x"D0", x"EF", x"AA", x"FB", x"43", x"4D", x"33", x"85",
        x"45", x"F9", x"02", x"7F", x"50", x"3C", x"9F", x"A8",
        x"51", x"A3", x"40", x"8F", x"92", x"9D", x"38", x"F5",
        x"BC", x"B6", x"DA", x"21", x"10", x"FF", x"F3", x"D2",
        x"CD", x"0C", x"13", x"EC", x"5F", x"97", x"44", x"17",
        x"C4", x"A7", x"7E", x"3D", x"64", x"5D", x"19", x"73",
        x"60", x"81", x"4F", x"DC", x"22", x"2A", x"90", x"88",
        x"46", x"EE", x"B8", x"14", x"DE", x"5E", x"0B", x"DB",
        x"E0", x"32", x"3A", x"0A", x"49", x"06", x"24", x"5C",
        x"C2", x"D3", x"AC", x"62", x"91", x"95", x"E4", x"79",
        x"E7", x"C8", x"37", x"6D", x"8D", x"D5", x"4E", x"A9",
        x"6C", x"56", x"F4", x"EA", x"65", x"7A", x"AE", x"08",
        x"BA", x"78", x"25", x"2E", x"1C", x"A6", x"B4", x"C6",
        x"E8", x"DD", x"74", x"1F", x"4B", x"BD", x"8B", x"8A",
        x"70", x"3E", x"B5", x"66", x"48", x"03", x"F6", x"0E",
        x"61", x"35", x"57", x"B9", x"86", x"C1", x"1D", x"9E",
        x"E1", x"F8", x"98", x"11", x"69", x"D9", x"8E", x"94",
        x"9B", x"1E", x"87", x"E9", x"CE", x"55", x"28", x"DF",
        x"8C", x"A1", x"89", x"0D", x"BF", x"E6", x"42", x"68",
        x"41", x"99", x"2D", x"0F", x"B0", x"54", x"BB", x"16"
    );

    type rcon_t is array (1 to 10) of byte_t;
    constant RCON : rcon_t := (
        x"01", x"02", x"04", x"08", x"10",
        x"20", x"40", x"80", x"1B", x"36"
    );

    type pipeline_t is array (0 to 10) of block_t;
    signal state_pipe : pipeline_t;
    signal key_pipe   : pipeline_t;

    function substitute_byte(a : byte_t) return byte_t is
    begin
        return SBOX(to_integer(unsigned(a)));
    end function;

    function xtime(a : byte_t) return byte_t is
        variable result : byte_t;
    begin
        result := a(6 downto 0) & '0';
        if a(7) = '1' then
            result := result xor x"1B";
        end if;
        return result;
    end function;

    function sub_bytes(a : block_t) return block_t is
        variable result : block_t;
    begin
        for i in 0 to 15 loop
            result(127 - 8*i downto 120 - 8*i) :=
                substitute_byte(a(127 - 8*i downto 120 - 8*i));
        end loop;
        return result;
    end function;

    -- Byte 0 is bits 127:120. AES states are serialized column first.
    function shift_rows(a : block_t) return block_t is
        variable result : block_t;
        variable src    : integer range 0 to 15;
        variable dst    : integer range 0 to 15;
    begin
        for column_index in 0 to 3 loop
            for row_index in 0 to 3 loop
                dst := 4*column_index + row_index;
                src := 4*((column_index + row_index) mod 4) + row_index;
                result(127 - 8*dst downto 120 - 8*dst) :=
                    a(127 - 8*src downto 120 - 8*src);
            end loop;
        end loop;
        return result;
    end function;

    function mix_columns(a : block_t) return block_t is
        variable result         : block_t;
        variable a0, a1, a2, a3 : byte_t;
        variable t              : byte_t;
    begin
        for c in 0 to 3 loop
            a0 := a(127 - 32*c downto 120 - 32*c);
            a1 := a(119 - 32*c downto 112 - 32*c);
            a2 := a(111 - 32*c downto 104 - 32*c);
            a3 := a(103 - 32*c downto  96 - 32*c);

            t := a0 xor a1 xor a2 xor a3;

            result(127 - 32*c downto 120 - 32*c) :=
                a0 xor t xor xtime(a0 xor a1);
            result(119 - 32*c downto 112 - 32*c) :=
                a1 xor t xor xtime(a1 xor a2);
            result(111 - 32*c downto 104 - 32*c) :=
                a2 xor t xor xtime(a2 xor a3);
            result(103 - 32*c downto 96 - 32*c) :=
                a3 xor t xor xtime(a3 xor a0);
        end loop;
        return result;
    end function;

    function expand_round_key(
        previous_key : block_t;
        round_number : integer
    ) return block_t is
        variable temp           : word_t;
        variable w0, w1, w2, w3 : word_t;
    begin
        -- SubWord(RotWord(previous_key's final word)).
        temp := substitute_byte(previous_key(23 downto 16)) &
                substitute_byte(previous_key(15 downto 8))  &
                substitute_byte(previous_key(7 downto 0))   &
                substitute_byte(previous_key(31 downto 24));

        temp(31 downto 24) := temp(31 downto 24) xor RCON(round_number);

        w0 := previous_key(127 downto 96) xor temp;
        w1 := previous_key(95 downto 64)  xor w0;
        w2 := previous_key(63 downto 32)  xor w1;
        w3 := previous_key(31 downto 0)   xor w2;

        return w0 & w1 & w2 & w3;
    end function;

begin

    Cypher_text <= state_pipe(10);

    -- Eleven register stages: initial AddRoundKey, then ten AES rounds.
    -- EN is a global clock enable: low pauses all blocks in flight.
    -- A block accepted at an enabled edge reaches the output after ten
    -- additional enabled edges. Each enabled edge can accept a new key/block.
    process (clk, rst)
        variable round_key   : block_t;
        variable round_state : block_t;
    begin
        if rst = '1' then
            state_pipe <= (others => (others => '0'));
            key_pipe   <= (others => (others => '0'));
        elsif rising_edge(clk) then
            if EN = '1' then
                state_pipe(0) <= Plain_text xor Key_in;
                key_pipe(0)   <= Key_in;

                for round_number in 1 to 10 loop
                    round_key := expand_round_key(
                        key_pipe(round_number - 1), round_number
                    );

                    round_state := shift_rows(
                        sub_bytes(state_pipe(round_number - 1))
                    );

                    if round_number < 10 then
                        round_state := mix_columns(round_state);
                    end if;

                    state_pipe(round_number) <= round_state xor round_key;
                    key_pipe(round_number)   <= round_key;
                end loop;
            end if;
        end if;
    end process;

end architecture rtl;
