-- Top del lab 7 parte IV para la DE2-115.
-- Aqui se juntan todos los bloques de la figura 5.
--
-- SW2..0   -> letra (000 = A ... 111 = H)
-- KEY1     -> manda la letra
-- KEY0     -> reset
-- LEDR0    -> aqui sale el morse
-- LEDG3..0 -> estado de la FSM, para depurar
library ieee;
use ieee.std_logic_1164.all;

entity morse_encoder is
    generic (
        CLKS_PER_TICK : positive := 25_000_000  -- medio segundo con 50 MHz
    );
    port (
        CLOCK_50 : in  std_logic;
        SW       : in  std_logic_vector(2 downto 0);
        KEY      : in  std_logic_vector(1 downto 0);
        LEDR     : out std_logic_vector(0 downto 0);
        LEDG     : out std_logic_vector(3 downto 0)
    );
end entity morse_encoder;

architecture structural of morse_encoder is
    signal reset_n   : std_logic;
    signal key1_sync : std_logic_vector(2 downto 0);
    signal start     : std_logic;

    signal rom_code  : std_logic_vector(3 downto 0);
    signal rom_len   : std_logic_vector(2 downto 0);

    signal load      : std_logic;
    signal timer_clr : std_logic;
    signal shift_en  : std_logic;
    signal len_dec   : std_logic;
    signal tick      : std_logic;
    signal code_bit  : std_logic;
    signal last      : std_logic;
begin
    reset_n <= KEY(0);

    -- KEY1 pasa por dos flip-flops para sincronizarlo y luego se detecta
    -- el flanco de bajada (los botones de la DE2 dan 0 al presionarlos),
    -- asi start dura un solo ciclo aunque dejes el boton apretado
    key_sync : process (CLOCK_50, reset_n)
    begin
        if reset_n = '0' then
            key1_sync <= (others => '1');
        elsif rising_edge(CLOCK_50) then
            key1_sync <= key1_sync(1 downto 0) & KEY(1);
        end if;
    end process;

    start <= key1_sync(2) and not key1_sync(1);

    letter_sel : entity work.morse_rom
        port map (
            letter => SW,
            code   => rom_code,
            len    => rom_len
        );

    len_counter : entity work.morse_len_counter
        port map (
            clk     => CLOCK_50,
            reset_n => reset_n,
            load    => load,
            enable  => len_dec,
            data    => rom_len,
            last    => last
        );

    shift_reg : entity work.morse_shift_reg
        port map (
            clk      => CLOCK_50,
            reset_n  => reset_n,
            load     => load,
            enable   => shift_en,
            data     => rom_code,
            code_bit => code_bit
        );

    half_sec : entity work.half_sec_counter
        generic map (
            CLKS_PER_TICK => CLKS_PER_TICK
        )
        port map (
            clk     => CLOCK_50,
            reset_n => reset_n,
            clr     => timer_clr,
            tick    => tick
        );

    fsm : entity work.morse_fsm
        port map (
            clk       => CLOCK_50,
            reset_n   => reset_n,
            start     => start,
            tick      => tick,
            code_bit  => code_bit,
            last      => last,
            load      => load,
            timer_clr => timer_clr,
            shift_en  => shift_en,
            len_dec   => len_dec,
            led       => LEDR(0),
            state_dbg => LEDG
        );
end architecture structural;
