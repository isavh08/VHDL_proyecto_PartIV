-- Testbench de la FSM sola.
-- Le muevo a mano start, tick, code_bit y last, y en cada paso reviso que
-- el estado y las salidas sean los de la tabla de docs/fsm_diagrama.md.
-- Si algo no cuadra sale "FALLO" en la consola.
library ieee;
use ieee.std_logic_1164.all;

entity tb_morse_fsm is
end entity tb_morse_fsm;

architecture sim of tb_morse_fsm is
    constant CLK_PERIOD : time := 20 ns;

    -- mismos codigos que saca state_dbg
    constant S_IDLE   : std_logic_vector(3 downto 0) := "0000";
    constant S_LOAD   : std_logic_vector(3 downto 0) := "0001";
    constant S_DECIDE : std_logic_vector(3 downto 0) := "0010";
    constant S_DOT    : std_logic_vector(3 downto 0) := "0011";
    constant S_DASH1  : std_logic_vector(3 downto 0) := "0100";
    constant S_DASH2  : std_logic_vector(3 downto 0) := "0101";
    constant S_DASH3  : std_logic_vector(3 downto 0) := "0110";
    constant S_GAP    : std_logic_vector(3 downto 0) := "0111";
    constant S_NEXT   : std_logic_vector(3 downto 0) := "1000";

    signal clk       : std_logic := '0';
    signal reset_n   : std_logic := '0';
    signal start     : std_logic := '0';
    signal tick      : std_logic := '0';
    signal code_bit  : std_logic := '0';
    signal last      : std_logic := '0';
    signal load      : std_logic;
    signal timer_clr : std_logic;
    signal shift_en  : std_logic;
    signal len_dec   : std_logic;
    signal led       : std_logic;
    signal state_dbg : std_logic_vector(3 downto 0);

    signal sim_done  : boolean := false;
    signal errors    : natural := 0;
begin
    dut : entity work.morse_fsm
        port map (
            clk       => clk,
            reset_n   => reset_n,
            start     => start,
            tick      => tick,
            code_bit  => code_bit,
            last      => last,
            load      => load,
            timer_clr => timer_clr,
            shift_en  => shift_en,
            len_dec   => len_dec,
            led       => led,
            state_dbg => state_dbg
        );

    clk <= not clk after CLK_PERIOD / 2 when not sim_done;

    stimulus : process

        -- espera un flanco y un ns para que se acomoden las salidas
        procedure step is
        begin
            wait until rising_edge(clk);
            wait for 1 ns;
        end procedure;

        -- revisa el estado y las salidas en orden: load, timer_clr, shift_en, len_dec, led
        procedure check (
            constant exp_state : in std_logic_vector(3 downto 0);
            constant exp_out   : in std_logic_vector(4 downto 0);
            constant msg       : in string
        ) is
            variable outs : std_logic_vector(4 downto 0);
        begin
            outs := load & timer_clr & shift_en & len_dec & led;
            if state_dbg /= exp_state or outs /= exp_out then
                report "FALLO: " & msg severity error;
                errors <= errors + 1;
            else
                report "OK: " & msg severity note;
            end if;
        end procedure;

        -- deja pasar n ciclos sin tick y checa que no se mueva del estado
        procedure hold (
            constant n         : in natural;
            constant exp_state : in std_logic_vector(3 downto 0);
            constant exp_out   : in std_logic_vector(4 downto 0);
            constant msg       : in string
        ) is
        begin
            tick <= '0';
            for i in 1 to n loop
                step;
                check(exp_state, exp_out, msg);
            end loop;
        end procedure;

        -- tick de un ciclo, como el que da el contador de medio segundo
        procedure pulse_tick is
        begin
            tick <= '1';
            step;
            tick <= '0';
        end procedure;

        --                                       load clr shf dec led
        constant O_NONE  : std_logic_vector(4 downto 0) := "00000";
        constant O_LOAD  : std_logic_vector(4 downto 0) := "10000";
        constant O_CLR   : std_logic_vector(4 downto 0) := "01000";
        constant O_NEXT  : std_logic_vector(4 downto 0) := "00110";
        constant O_LED   : std_logic_vector(4 downto 0) := "00001";
    begin
        -- 1) reset
        reset_n <= '0';
        wait for 3 * CLK_PERIOD;
        check(S_IDLE, O_NONE, "reset -> IDLE");
        reset_n <= '1';

        -- 2) si nadie pica KEY1 se queda en IDLE, aunque llegue un tick
        hold(5, S_IDLE, O_NONE, "IDLE sin start");
        pulse_tick;
        check(S_IDLE, O_NONE, "IDLE ignora tick");

        -- 3) letra A (.-): punto, pausa, raya, pausa y regresa a IDLE
        start <= '1';
        step;
        start <= '0';
        check(S_LOAD, O_LOAD, "A: start -> LOAD (load=1)");

        code_bit <= '0';                       -- primero va un punto
        last     <= '0';
        step;
        check(S_DECIDE, O_CLR, "A: LOAD -> DECIDE (timer_clr=1)");
        step;
        check(S_DOT, O_LED, "A: DECIDE -> DOT con code_bit=0");
        hold(4, S_DOT, O_LED, "A: DOT se mantiene sin tick");
        pulse_tick;
        check(S_GAP, O_NONE, "A: DOT -> GAP con tick");
        hold(3, S_GAP, O_NONE, "A: GAP se mantiene sin tick");
        pulse_tick;
        check(S_NEXT, O_NEXT, "A: GAP -> NEXT (last=0, shift_en/len_dec)");

        code_bit <= '1';                       -- y luego la raya
        last     <= '1';
        step;
        check(S_DECIDE, O_CLR, "A: NEXT -> DECIDE");
        step;
        check(S_DASH1, O_LED, "A: DECIDE -> DASH1 con code_bit=1");
        hold(2, S_DASH1, O_LED, "A: DASH1 se mantiene");
        pulse_tick;
        check(S_DASH2, O_LED, "A: DASH1 -> DASH2");
        hold(2, S_DASH2, O_LED, "A: DASH2 se mantiene");
        pulse_tick;
        check(S_DASH3, O_LED, "A: DASH2 -> DASH3");
        hold(2, S_DASH3, O_LED, "A: DASH3 se mantiene");
        pulse_tick;
        check(S_GAP, O_NONE, "A: DASH3 -> GAP");
        pulse_tick;
        check(S_IDLE, O_NONE, "A: GAP -> IDLE (last=1)");
        hold(3, S_IDLE, O_NONE, "A: permanece en IDLE al terminar");

        -- 4) letra E (.): nomas un simbolo, de GAP se va directo a IDLE
        code_bit <= '0';
        last     <= '1';
        start    <= '1';
        step;
        start <= '0';
        check(S_LOAD, O_LOAD, "E: start -> LOAD");
        step;
        check(S_DECIDE, O_CLR, "E: LOAD -> DECIDE");
        step;
        check(S_DOT, O_LED, "E: DECIDE -> DOT");
        pulse_tick;
        check(S_GAP, O_NONE, "E: DOT -> GAP");
        pulse_tick;
        check(S_IDLE, O_NONE, "E: GAP -> IDLE");

        -- 5) si se pica KEY1 a medio envio no debe reiniciar nada
        code_bit <= '1';
        last     <= '1';
        start    <= '1';
        step;
        check(S_LOAD, O_LOAD, "start -> LOAD");
        step;
        step;
        check(S_DASH1, O_LED, "-> DASH1 con start aun activo");
        hold(3, S_DASH1, O_LED, "DASH1 ignora start");
        start <= '0';

        -- 6) reset a media raya, tiene que irse a IDLE sin esperar el reloj
        pulse_tick;
        check(S_DASH2, O_LED, "DASH1 -> DASH2");
        wait for CLK_PERIOD / 4;               -- a la mitad entre flancos
        reset_n <= '0';
        wait for 1 ns;
        check(S_IDLE, O_NONE, "reset asincrono en DASH2 -> IDLE inmediato");
        wait for 2 * CLK_PERIOD;
        reset_n <= '1';
        hold(2, S_IDLE, O_NONE, "IDLE despues del reset");

        wait for CLK_PERIOD;
        if errors = 0 then
            report "==== tb_morse_fsm: TODAS LAS PRUEBAS PASARON ====" severity note;
        else
            report "==== tb_morse_fsm: " & integer'image(errors) & " FALLOS ====" severity error;
        end if;
        sim_done <= true;
        wait;
    end process;
end architecture sim;
