-- Contador de cuantos simbolos faltan.
-- Se carga con el largo de la letra y baja uno cada vez que pasamos
-- al siguiente simbolo. last = 1 cuando ya vamos en el ultimo.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity morse_len_counter is
    port (
        clk     : in  std_logic;
        reset_n : in  std_logic;
        load    : in  std_logic;
        enable  : in  std_logic;
        data    : in  std_logic_vector(2 downto 0);
        last    : out std_logic
    );
end entity morse_len_counter;

architecture rtl of morse_len_counter is
    signal count : unsigned(2 downto 0);
begin
    process (clk, reset_n)
    begin
        if reset_n = '0' then
            count <= (others => '0');
        elsif rising_edge(clk) then
            if load = '1' then
                count <= unsigned(data);
            elsif enable = '1' and count /= 0 then
                count <= count - 1;
            end if;
        end if;
    end process;

    last <= '1' when count <= 1 else '0';
end architecture rtl;
