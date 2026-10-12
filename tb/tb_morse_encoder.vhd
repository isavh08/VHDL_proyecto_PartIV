-- Testbench de todo el circuito.
-- Para no simular 25 millones de ciclos, aqui el "medio segundo" son 10 ciclos.
-- Pasa por todas las letras A..H: pica KEY1, mide cuanto dura prendido cada
-- pulso de LEDR0 para saber si fue punto o raya, y compara con lo esperado.
-- Al final prueba que KEY0 resetee a media letra.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_morse_encoder is
end entity tb_morse_encoder;

architecture sim of tb_morse_encoder is
    constant CLK_PERIOD : time     := 20 ns;  -- 50 MHz
    constant TICK       : positive := 10;     -- ciclos por "medio segundo"
    constant T_UNIT     : time     := TICK * CLK_PERIOD;
    -- margen por los ciclos extra de LOAD, DECIDE y NEXT
    constant T_TOL      : time     := 3 * CLK_PERIOD;

    signal CLOCK_50 : std_logic := '0';
    signal SW       : std_logic_vector(2 downto 0) := "000";
    signal KEY      : std_logic_vector(1 downto 0) := "11";
    signal LEDR     : std_logic_vector(0 downto 0);
    signal LEDG     : std_logic_vector(3 downto 0);

    signal sim_done : boolean := false;

    type morse_table_t is array (0 to 7) of string(1 to 4);
    -- lo que deberia salir para cada letra (con espacios al final)
    constant EXPECTED : morse_table_t := (
        ".-  ",   -- A
        "-...",   -- B
        "-.-.",   -- C
        "-.. ",   -- D
        ".   ",   -- E
        "..-.",   -- F
        "--. ",   -- G
        "...."    -- H
    );
    constant LETTERS : string(1 to 8) := "ABCDEFGH";
    constant S_IDLE  : std_logic_vector(3 downto 0) := "0000";
begin
    dut : entity work.morse_encoder
        generic map (
            CLKS_PER_TICK => TICK
        )
        port map (
            CLOCK_50 => CLOCK_50,
            SW       => SW,
            KEY      => KEY,
            LEDR     => LEDR,
            LEDG     => LEDG
        );

    CLOCK_50 <= not CLOCK_50 after CLK_PERIOD / 2 when not sim_done;

    stimulus : process
        variable errors   : natural := 0;
        variable received : string(1 to 4);
        variable n        : natural;
        variable t_on     : time;
        variable t_off    : time;
        variable width    : time;

        -- picado cortito para regresar antes de que se prenda el LED
        -- (entre el sincronizador, LOAD y DECIDE son como 4 ciclos)
        procedure press_key1 is
        begin
            wait until falling_edge(CLOCK_50);
            KEY(1) <= '0';
            wait for 2 * CLK_PERIOD;
            KEY(1) <= '1';
        end procedure;
    begin
        -- reset al inicio
        KEY(0) <= '0';
        wait for 5 * CLK_PERIOD;
        KEY(0) <= '1';
        wait for 5 * CLK_PERIOD;

        for i in 0 to 7 loop
            SW <= std_logic_vector(to_unsigned(i, 3));
            wait for 2 * CLK_PERIOD;
            press_key1;

            received := "    ";
            n        := 0;
            t_off    := now;

            -- lee simbolos hasta que la FSM regrese a IDLE
            loop
                wait until LEDR(0) = '1' or LEDG = S_IDLE;
                exit when LEDR(0) /= '1';

                -- la pausa de antes (en el primer simbolo no hay)
                if n > 0 then
                    width := now - t_off;
                    if width < T_UNIT or width > T_UNIT + T_TOL then
                        report LETTERS(i + 1) & ": separacion incorrecta de " &
                               time'image(width) severity error;
                        errors := errors + 1;
                    end if;
                end if;

                t_on := now;
                wait until LEDR(0) = '0';
                t_off := now;
                width := t_off - t_on;
                n     := n + 1;

                if width >= T_UNIT and width <= T_UNIT + T_TOL then
                    received(n) := '.';
                elsif width >= 3 * T_UNIT and width <= 3 * T_UNIT + T_TOL then
                    received(n) := '-';
                else
                    received(n) := '?';
                    report LETTERS(i + 1) & ": pulso de ancho invalido " &
                           time'image(width) severity error;
                    errors := errors + 1;
                end if;
                exit when n = 4;
            end loop;

            if LEDG /= S_IDLE then
                wait until LEDG = S_IDLE;
            end if;

            if received = EXPECTED(i) then
                report "OK: letra " & LETTERS(i + 1) & " -> " & received severity note;
            else
                report "FALLO: letra " & LETTERS(i + 1) & " esperado '" & EXPECTED(i) &
                       "' recibido '" & received & "'" severity error;
                errors := errors + 1;
            end if;

            wait for 5 * CLK_PERIOD;
        end loop;

        -- picar KEY0 mientras se esta mandando la B
        SW <= "001";
        press_key1;
        wait until LEDR(0) = '1';
        wait for T_UNIT / 2;
        KEY(0) <= '0';
        wait for 1 ns;
        if LEDR(0) = '0' and LEDG = S_IDLE then
            report "OK: KEY0 reinicia asincronamente (LEDR0 apagado, FSM en IDLE)" severity note;
        else
            report "FALLO: KEY0 no reinicio el circuito" severity error;
            errors := errors + 1;
        end if;
        wait for 5 * CLK_PERIOD;
        KEY(0) <= '1';

        -- despues del reset no debe arrancar sola
        wait for 5 * T_UNIT;
        if LEDR(0) = '0' and LEDG = S_IDLE then
            report "OK: permanece en IDLE tras el reset" severity note;
        else
            report "FALLO: la FSM salio de IDLE sin KEY1" severity error;
            errors := errors + 1;
        end if;

        if errors = 0 then
            report "==== tb_morse_encoder: TODAS LAS PRUEBAS PASARON ====" severity note;
        else
            report "==== tb_morse_encoder: " & integer'image(errors) & " FALLOS ====" severity error;
        end if;
        sim_done <= true;
        wait;
    end process;
end architecture sim;
