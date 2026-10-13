# Implementación y prueba

## 1. Simulación (ModelSim-Altera 13.1)

Desde la carpeta `sim/`:

```
vsim -do run_tb_fsm.do       # testbench de la FSM (con formas de onda)
vsim -do run_tb_encoder.do   # testbench del sistema completo
```

Para correrlos sin interfaz gráfica añadir `-c`. Cada testbench imprime
`OK:` por cada verificación y al final `TODAS LAS PRUEBAS PASARON`.

### `tb_morse_fsm` – FSM aislada

Maneja directamente `start`, `tick`, `code_bit` y `last` y comprueba, ciclo a
ciclo, el estado y las cinco salidas (`load`, `timer_clr`, `shift_en`,
`len_dec`, `led`) contra la tabla de `fsm_diagrama.md`:

1. Reset asíncrono → `IDLE`.
2. Sin `start` permanece en `IDLE` (aunque llegue `tick`).
3. Letra A (`.-`): recorre `LOAD → DECIDE → DOT → GAP → NEXT → DECIDE →
   DASH1 → DASH2 → DASH3 → GAP → IDLE`; en cada estado de duración se
   comprueba que se mantiene mientras `tick = 0`.
4. Letra E (`.`): un solo símbolo, de `GAP` vuelve directo a `IDLE`.
5. `start` durante la transmisión no la reinicia.
6. Reset asíncrono en medio de `DASH2`: pasa a `IDLE` sin esperar flanco.

### `tb_morse_encoder` – sistema completo

Usa `CLKS_PER_TICK = 10` para que medio segundo dure 10 ciclos. Para cada
letra A..H presiona `KEY1`, mide el ancho de cada pulso de `LEDR0`, lo
clasifica como punto (1 tick) o raya (3 ticks), verifica la separación de
1 tick entre símbolos y compara el resultado con el código esperado. Al
final prueba el reset asíncrono con `KEY0` a mitad de la letra B.

Resultado obtenido:

```
OK: letra A -> .-
OK: letra B -> -...
OK: letra C -> -.-.
OK: letra D -> -..
OK: letra E -> .
OK: letra F -> ..-.
OK: letra G -> --.
OK: letra H -> ....
OK: KEY0 reinicia asincronamente (LEDR0 apagado, FSM en IDLE)
OK: permanece en IDLE tras el reset
==== tb_morse_encoder: TODAS LAS PRUEBAS PASARON ====
```

## 2. Síntesis (Quartus II 13.1 Web Edition)

Abrir `quartus/morse_encoder.qpf` y ejecutar *Processing → Start Compilation*,
o desde consola en `quartus/`:

```
quartus_sh --flow compile morse_encoder
```

Resumen del ajuste en EP4CE115F29C7:

| Recurso               | Uso                 |
|-----------------------|---------------------|
| Elementos lógicos     | 66 / 114 480 (<1 %) |
| Registros             | 44                  |
| Pines                 | 11 / 529            |
| Restricción de reloj  | 50 MHz (cumplida)   |

## 3. Programación de la DE2-115

1. Conectar la tarjeta por el puerto USB-Blaster y encenderla
   (interruptor `SW19` de RUN/PROG en **RUN**).
2. *Tools → Programmer*, *Hardware Setup* → **USB-Blaster**, modo **JTAG**.
3. Agregar `quartus/output_files/morse_encoder.sof` y presionar **Start**.

## 4. Asignación de pines

| Señal      | Pin   | Elemento de la tarjeta     |
|------------|-------|----------------------------|
| `CLOCK_50` | Y2    | Oscilador 50 MHz           |
| `SW[0]`    | AB28  | SW0                        |
| `SW[1]`    | AC28  | SW1                        |
| `SW[2]`    | AC27  | SW2                        |
| `KEY[0]`   | M23   | KEY0 – reset asíncrono     |
| `KEY[1]`   | M21   | KEY1 – iniciar transmisión |
| `LEDR[0]`  | G19   | LEDR0 – salida Morse       |
| `LEDG[3:0]`| E24, E25, E22, E21 | LEDG3..0 – estado de la FSM |

## 5. Protocolo de prueba en la tarjeta

1. Presionar `KEY0`: `LEDR0` y `LEDG3..0` deben quedar apagados (`IDLE`).
2. Para cada letra, colocar `SW2..0` y presionar `KEY1`. Observar `LEDR0`
   (punto ≈ 0.5 s, raya ≈ 1.5 s, pausa ≈ 0.5 s):

   | SW2..0 | Letra | Se debe observar en LEDR0           | Resultado |
   |--------|-------|-------------------------------------|-----------|
   | 000    | A     | corto, largo                        | ☐         |
   | 001    | B     | largo, corto, corto, corto          | ☐         |
   | 010    | C     | largo, corto, largo, corto          | ☐         |
   | 011    | D     | largo, corto, corto                 | ☐         |
   | 100    | E     | corto                               | ☐         |
   | 101    | F     | corto, corto, largo, corto          | ☐         |
   | 110    | G     | largo, largo, corto                 | ☐         |
   | 111    | H     | corto, corto, corto, corto          | ☐         |

3. Durante una transmisión, cambiar `SW2..0`: la letra en curso no debe
   cambiar (el código se cargó en el registro al presionar `KEY1`).
4. Durante una transmisión, presionar `KEY1` otra vez: debe ignorarse.
5. Durante una raya, presionar `KEY0`: `LEDR0` se apaga inmediatamente.
6. En `LEDG3..0` se ve el código binario del estado (ver tabla de estados en
   `fsm_diagrama.md`): `0011` punto, `0100/0101/0110` raya, `0111` pausa.
