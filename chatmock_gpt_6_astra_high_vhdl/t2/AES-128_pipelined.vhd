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
    type pipeline_t is array (0 to 10) of block_t;

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

    signal state_pipe : pipeline_t;
    signal key_pipe   : pipeline_t;

    function substitute_byte(b : byte_t) return byte_t is
    begin
        return SBOX(to_integer(unsigned(b)));
    end function;

    function xtime(b : byte_t) return byte_t is
        variable result : byte_t;
    begin
        result := b(6 downto 0) & '0';
        if b(7) = '1' then
            result := result xor x"1B";
        end if;
        return result;
    end function;

    function sub_bytes_shift_rows(s : block_t) return block_t is
        variable result    : block_t;
        variable src_index : integer range 0 to 15;
        variable dst_index : integer range 0 to 15;
    begin
        -- AES byte order: byte 0 is bits 127:120.
        -- State byte (row, column) has index 4*column + row.
        for column in 0 to 3 loop
            for row in 0 to 3 loop
                dst_index := 4 * column + row;
                src_index := 4 * ((column + row) mod 4) + row;
                result(127 - 8 * dst_index downto 120 - 8 * dst_index) :=
                    substitute_byte(
                        s(127 - 8 * src_index downto 120 - 8 * src_index)
                    );
            end loop;
        end loop;
        return result;
    end function;

    function mix_columns(s : block_t) return block_t is
        variable result : block_t;
        variable a0     : byte_t;
        variable a1     : byte_t;
        variable a2     : byte_t;
        variable a3     : byte_t;
        variable total  : byte_t;
    begin
        for column in 0 to 3 loop
            a0 := s(127 - 32 * column downto 120 - 32 * column);
            a1 := s(119 - 32 * column downto 112 - 32 * column);
            a2 := s(111 - 32 * column downto 104 - 32 * column);
            a3 := s(103 - 32 * column downto  96 - 32 * column);

            total := a0 xor a1 xor a2 xor a3;

            result(127 - 32 * column downto 120 - 32 * column) :=
                a0 xor total xor xtime(a0 xor a1);
            result(119 - 32 * column downto 112 - 32 * column) :=
                a1 xor total xor xtime(a1 xor a2);
            result(111 - 32 * column downto 104 - 32 * column) :=
                a2 xor total xor xtime(a2 xor a3);
            result(103 - 32 * column downto 96 - 32 * column) :=
                a3 xor total xor xtime(a3 xor a0);
        end loop;
        return result;
    end function;

    function next_round_key(
        current_key : block_t;
        round_number : positive
    ) return block_t is
        variable w0       : word_t;
        variable w1       : word_t;
        variable w2       : word_t;
        variable w3       : word_t;
        variable temp     : word_t;
        variable rcon     : byte_t;
    begin
        rcon := x"01";
        for i in 1 to round_number - 1 loop
            rcon := xtime(rcon);
        end loop;

        -- SubWord(RotWord(last word)) XOR Rcon.
        temp(31 downto 24) :=
            substitute_byte(current_key(23 downto 16)) xor rcon;
        temp(23 downto 16) :=
            substitute_byte(current_key(15 downto 8));
        temp(15 downto 8) :=
            substitute_byte(current_key(7 downto 0));
        temp(7 downto 0) :=
            substitute_byte(current_key(31 downto 24));

        w0 := current_key(127 downto 96) xor temp;
        w1 := current_key(95 downto 64) xor w0;
        w2 := current_key(63 downto 32) xor w1;
        w3 := current_key(31 downto 0) xor w2;

        return w0 & w1 & w2 & w3;
    end function;

begin
    Cypher_text <= state_pipe(10);

    -- Eleven registered stages: initial AddRoundKey and ten AES rounds.
    -- EN is a global clock enable; deasserting it freezes the pipeline.
    -- A block accepted at one enabled edge reaches the output ten
    -- subsequent enabled edges later. Keys may change for every block.
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
                    round_key :=
                        next_round_key(key_pipe(round_number - 1),
                                       round_number);

                    round_state :=
                        sub_bytes_shift_rows(state_pipe(round_number - 1));

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
