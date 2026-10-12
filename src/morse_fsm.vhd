-- FSM del codificador morse (tipo Moore). El diagrama esta en docs/fsm_diagrama.md
--
-- IDLE    -> esperando a que piquen KEY1
-- LOAD    -> carga la letra en el registro y el contador
-- DECIDE  -> reinicia el timer y ve si toca punto o raya
-- DOT     -> LED prendido medio segundo
-- DASH1-3 -> LED prendido 3 medios segundos (1.5 s)
-- GAP     -> LED apagado medio segundo entre simbolos
-- NEXT    -> recorre al siguiente simbolo
library ieee;
use ieee.std_logic_1164.all;

entity morse_fsm is
    port (
        clk       : in  std_logic;
        reset_n   : in  std_logic;  -- reset asincrono, activo en 0
        start     : in  std_logic;
        tick      : in  std_logic;
        code_bit  : in  std_logic;  -- 1 = raya, 0 = punto
        last      : in  std_logic;  -- 1 si ya es el ultimo simbolo
        load      : out std_logic;
        timer_clr : out std_logic;
        shift_en  : out std_logic;
        len_dec   : out std_logic;
        led       : out std_logic;
        state_dbg : out std_logic_vector(3 downto 0)
    );
end entity morse_fsm;

architecture rtl of morse_fsm is
    type state_t is (IDLE, LOAD_ST, DECIDE, DOT, DASH1, DASH2, DASH3, GAP, NEXT_ST);
    signal state, next_state : state_t;
begin
    state_reg : process (clk, reset_n)
    begin
        if reset_n = '0' then
            state <= IDLE;
        elsif rising_edge(clk) then
            state <= next_state;
        end if;
    end process;

    next_state_logic : process (state, start, tick, code_bit, last)
    begin
        next_state <= state;
        case state is
            when IDLE =>
                if start = '1' then
                    next_state <= LOAD_ST;
                end if;
            when LOAD_ST =>
                next_state <= DECIDE;
            when DECIDE =>
                if code_bit = '1' then
                    next_state <= DASH1;
                else
                    next_state <= DOT;
                end if;
            when DOT =>
                if tick = '1' then
                    next_state <= GAP;
                end if;
            when DASH1 =>
                if tick = '1' then
                    next_state <= DASH2;
                end if;
            when DASH2 =>
                if tick = '1' then
                    next_state <= DASH3;
                end if;
            when DASH3 =>
                if tick = '1' then
                    next_state <= GAP;
                end if;
            when GAP =>
                if tick = '1' then
                    if last = '1' then
                        next_state <= IDLE;
                    else
                        next_state <= NEXT_ST;
                    end if;
                end if;
            when NEXT_ST =>
                next_state <= DECIDE;
        end case;
    end process;

    -- salidas, solo dependen del estado
    load     <= '1' when state = LOAD_ST else '0';
    timer_clr <= '1' when state = DECIDE  else '0';
    shift_en  <= '1' when state = NEXT_ST else '0';
    len_dec   <= '1' when state = NEXT_ST else '0';
    led       <= '1' when state = DOT or state = DASH1 or
                          state = DASH2 or state = DASH3 else '0';

    -- numero de estado para verlo en los LEDG
    with state select state_dbg <=
        "0000" when IDLE,
        "0001" when LOAD_ST,
        "0010" when DECIDE,
        "0011" when DOT,
        "0100" when DASH1,
        "0101" when DASH2,
        "0110" when DASH3,
        "0111" when GAP,
        "1000" when NEXT_ST;
end architecture rtl;
