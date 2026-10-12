-- Contador de medio segundo: saca un pulso (tick) cada CLKS_PER_TICK ciclos.
-- Con el reloj de 50 MHz, 25 millones de ciclos = 0.5 s.
-- En simulacion se le pone un numero chico para no esperar una eternidad.
-- clr lo regresa a 0 para que cada punto/raya dure completo.
library ieee;
use ieee.std_logic_1164.all;

entity half_sec_counter is
    generic (
        CLKS_PER_TICK : positive := 25_000_000
    );
    port (
        clk     : in  std_logic;
        reset_n : in  std_logic;
        clr     : in  std_logic;
        tick    : out std_logic
    );
end entity half_sec_counter;

architecture rtl of half_sec_counter is
    signal count : natural range 0 to CLKS_PER_TICK - 1;
begin
    process (clk, reset_n)
    begin
        if reset_n = '0' then
            count <= 0;
            tick  <= '0';
        elsif rising_edge(clk) then
            tick <= '0';
            if clr = '1' then
                count <= 0;
            elsif count = CLKS_PER_TICK - 1 then
                count <= 0;
                tick  <= '1';
            else
                count <= count + 1;
            end if;
        end if;
    end process;
end architecture rtl;
