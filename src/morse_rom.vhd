-- Tabla con el morse de cada letra (A..H segun SW2..0)
-- code: 1 = raya, 0 = punto. Se manda primero el bit 3
-- len: cuantos simbolos tiene la letra (los bits que sobran van en 0)
library ieee;
use ieee.std_logic_1164.all;

entity morse_rom is
    port (
        letter : in  std_logic_vector(2 downto 0);
        code   : out std_logic_vector(3 downto 0);
        len    : out std_logic_vector(2 downto 0)
    );
end entity morse_rom;

architecture rtl of morse_rom is
begin
    process (letter)
    begin
        case letter is
            when "000"  => code <= "0100"; len <= "010";  -- A  .-
            when "001"  => code <= "1000"; len <= "100";  -- B  -...
            when "010"  => code <= "1010"; len <= "100";  -- C  -.-.
            when "011"  => code <= "1000"; len <= "011";  -- D  -..
            when "100"  => code <= "0000"; len <= "001";  -- E  .
            when "101"  => code <= "0010"; len <= "100";  -- F  ..-.
            when "110"  => code <= "1100"; len <= "011";  -- G  --.
            when others => code <= "0000"; len <= "100";  -- H  ....
        end case;
    end process;
end architecture rtl;
