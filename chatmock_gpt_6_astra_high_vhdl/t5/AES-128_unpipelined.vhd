library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

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

architecture RTL of AES_Encrypt is

    subtype byte_t is std_logic_vector(7 downto 0);
    type state_t is array (0 to 15) of byte_t;
    type word_t is array (0 to 3) of byte_t;
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

    function sub_byte(b : byte_t) return byte_t is
    begin
        return SBOX(to_integer(unsigned(b)));
    end function;

    function xtime(b : byte_t) return byte_t is
        variable result_b : byte_t;
    begin
        result_b := b(6 downto 0) & '0';
        if b(7) = '1' then
            result_b := result_b xor x"1B";
        end if;
        return result_b;
    end function;

    function encrypt_block(
        plaintext : std_logic_vector(127 downto 0);
        cipherkey : std_logic_vector(127 downto 0)
    ) return std_logic_vector is
        variable state       : state_t;
        variable shifted     : state_t;
        variable round_key   : state_t;
        variable key_temp    : word_t;
        variable rcon        : byte_t;
        variable a0, a1      : byte_t;
        variable a2, a3      : byte_t;
        variable column_xor  : byte_t;
        variable result_vec : std_logic_vector(127 downto 0);
    begin
        -- Bytes are serialized in FIPS-197 column-major order.
        for i in 0 to 15 loop
            round_key(i) := cipherkey(127 - 8*i downto 120 - 8*i);
            state(i) := plaintext(127 - 8*i downto 120 - 8*i)
                        xor round_key(i);
        end loop;

        rcon := x"01";

        for round_number in 1 to 10 loop
            -- Expand the previous round key into the next round key.
            key_temp(0) := sub_byte(round_key(13)) xor rcon;
            key_temp(1) := sub_byte(round_key(14));
            key_temp(2) := sub_byte(round_key(15));
            key_temp(3) := sub_byte(round_key(12));

            for i in 0 to 3 loop
                round_key(i) := round_key(i) xor key_temp(i);
            end loop;

            for i in 4 to 15 loop
                round_key(i) := round_key(i) xor round_key(i - 4);
            end loop;

            rcon := xtime(rcon);

            -- SubBytes.
            for i in 0 to 15 loop
                state(i) := sub_byte(state(i));
            end loop;

            -- ShiftRows.
            for col in 0 to 3 loop
                for row in 0 to 3 loop
                    shifted(4*col + row) :=
                        state(4*((col + row) mod 4) + row);
                end loop;
            end loop;

            -- MixColumns is omitted in round 10.
            if round_number < 10 then
                for col in 0 to 3 loop
                    a0 := shifted(4*col);
                    a1 := shifted(4*col + 1);
                    a2 := shifted(4*col + 2);
                    a3 := shifted(4*col + 3);

                    column_xor := a0 xor a1 xor a2 xor a3;

                    state(4*col) :=
                        a0 xor column_xor xor xtime(a0 xor a1);
                    state(4*col + 1) :=
                        a1 xor column_xor xor xtime(a1 xor a2);
                    state(4*col + 2) :=
                        a2 xor column_xor xor xtime(a2 xor a3);
                    state(4*col + 3) :=
                        a3 xor column_xor xor xtime(a3 xor a0);
                end loop;
            else
                state := shifted;
            end if;

            -- AddRoundKey.
            for i in 0 to 15 loop
                state(i) := state(i) xor round_key(i);
            end loop;
        end loop;

        for i in 0 to 15 loop
            result_vec(127 - 8*i downto 120 - 8*i) := state(i);
        end loop;

        return result_vec;
    end function;

begin

    -- Single-shot combinational encryption with a registered output.
    -- Active-high asynchronous reset; EN low holds the previous result.
    process(clk, rst)
    begin
        if rst = '1' then
            Cypher_text <= (others => '0');
        elsif rising_edge(clk) then
            if EN = '1' then
                Cypher_text <= encrypt_block(Plain_text, Key_in);
            end if;
        end if;
    end process;

end architecture RTL;
